import 'dart:async';
import 'dart:io';

import 'package:ag_flow_cli/src/mcp/ag_mcp_server.dart';
import 'package:dart_mcp/client.dart';
import 'package:dart_mcp/stdio.dart';
import 'package:path/path.dart' as p;
import 'package:stream_channel/stream_channel.dart';
import 'package:test/test.dart';

base class _TestClient extends MCPClient {
  _TestClient() : super(Implementation(name: 'test client', version: '0.1.0'));
}

base class _RootsClient extends MCPClient with RootsSupport {
  _RootsClient() : super(Implementation(name: 'roots client', version: '0.1.0'));
}

/// Initializes [connection] the way every MCP client does before its first call.
Future<void> _handshake(ServerConnection connection, MCPClient client) async {
  await connection.initialize(
    InitializeRequest(
      protocolVersion: ProtocolVersion.latestSupported,
      capabilities: client.capabilities,
      clientInfo: client.implementation,
    ),
  );
  connection.notifyInitialized();
}

/// Drives [AgMcpServer] through a real [MCPClient] over an in-memory channel,
/// so every call goes through the same JSON-RPC encoding a real agent's does.
void main() {
  late Directory appDir;
  late ServerConnection connection;

  /// Connects [client] to a fresh server started in [workingDirectory].
  Future<ServerConnection> connect(MCPClient client, Directory workingDirectory) async {
    final toServer = StreamController<String>();
    final toClient = StreamController<String>();
    final server = AgMcpServer(
      StreamChannel<String>.withCloseGuarantee(toServer.stream, toClient.sink),
      workingDirectory: workingDirectory,
    );
    final connection = client.connectServer(
      StreamChannel<String>.withCloseGuarantee(toClient.stream, toServer.sink),
    );
    await _handshake(connection, client);
    addTearDown(() async {
      await client.shutdown();
      await server.shutdown();
    });
    return connection;
  }

  setUp(() async {
    appDir = Directory.systemTemp.createTempSync('ag_mcp_test_');
    addTearDown(() => appDir.deleteSync(recursive: true));
    File(p.join(appDir.path, 'pubspec.yaml')).writeAsStringSync('name: sample_app\n');
    connection = await connect(_TestClient(), appDir);
  });

  /// Calls [tool] and checks its structured result against the tool's own
  /// `outputSchema`, as the MCP spec requires of every structured result.
  Future<CallToolResult> call(String tool, [Map<String, Object?> args = const {}]) async {
    final result = await connection.callTool(CallToolRequest(name: tool, arguments: args));
    final schema = (await connection.listTools()).tools
        .singleWhere((t) => t.name == tool)
        .outputSchema;
    if (result.structuredContent case final data?) {
      expect(schema, isNotNull, reason: '$tool returns structured content');
      expect(schema!.validate(data), isEmpty, reason: '$tool output matches its outputSchema');
    }
    return result;
  }

  List<Map<String, Object?>> files(CallToolResult result) =>
      (result.structuredContent!['files']! as List).cast<Map<String, Object?>>();

  test('lists the five tools', () async {
    final tools = await connection.listTools();
    expect(
      tools.tools.map((t) => t.name),
      unorderedEquals([
        'ag_rules',
        'ag_init',
        'ag_generate_module',
        'ag_analyze',
        'ag_list_modules',
      ]),
    );
  });

  test('ag_rules returns the architecture standard', () async {
    final result = await call('ag_rules');
    expect(
      (result.content.single as TextContent).text,
      contains('AG Flow — architecture standard'),
    );
  });

  test('ag_init writes the skeleton once, then skips every file', () async {
    final first = await call('ag_init');
    expect(first.isError, isNot(true));
    expect(files(first).map((f) => f['action']), everyElement('create'));
    expect(
      File(p.join(appDir.path, 'lib', 'core', 'routes', 'app_routes.dart')).existsSync(),
      isTrue,
    );

    final second = await call('ag_init');
    expect(files(second).map((f) => f['action']), everyElement('skip'));
  });

  test('ag_generate_module before ag_init is a tool error, not a crash', () async {
    final result = await call('ag_generate_module', {'module_path': 'product'});
    expect(result.isError, isTrue);
    expect((result.content.single as TextContent).text, contains('ag_init'));
  });

  test('ag_generate_module dry_run writes nothing', () async {
    await call('ag_init');
    final result = await call('ag_generate_module', {'module_path': 'product', 'dry_run': true});
    expect(result.structuredContent!['dry_run'], isTrue);
    expect(files(result), isNotEmpty);
    expect(Directory(p.join(appDir.path, 'lib', 'modules')).existsSync(), isFalse);
  });

  test('generates a typed module from a JSON sample, then lists and analyzes it', () async {
    await call('ag_init');
    final generated = await call('ag_generate_module', {
      'module_path': 'product',
      'json_sample': '[{"id": 1, "title": "Pen"}]',
      'methods': 'none',
    });
    expect(generated.isError, isNot(true));
    final paths = files(generated).map((f) => f['path']);
    expect(paths, contains('lib/modules/product/models/product.dart'));

    await call('ag_generate_module', {'module_path': 'product/details'});

    final listed = await call('ag_list_modules');
    final modules = (listed.structuredContent!['modules']! as List).cast<Map<String, Object?>>();
    expect(modules.map((m) => m['module_path']), ['product', 'product/details']);
    expect(modules.map((m) => m['kind']), ['collection', 'detail']);
    expect(modules.map((m) => m['model']), everyElement('Product'));

    final analyzed = await call('ag_analyze');
    expect(analyzed.structuredContent!['issues'], isEmpty);
  });

  test('ag_analyze reports a violation with its category and file', () async {
    await call('ag_init');
    await call('ag_generate_module', {'module_path': 'product'});
    File(p.join(appDir.path, 'lib', 'modules', 'product', 'repos', 'products_repo.dart'))
        .deleteSync();

    final result = await call('ag_analyze');
    final issues = (result.structuredContent!['issues']! as List).cast<Map<String, Object?>>();
    expect(issues.map((i) => i['category']), contains('missingLayerFile'));
  });

  test('bad arguments come back as tool errors', () async {
    await call('ag_init');
    final badMethods = await call('ag_generate_module', {
      'module_path': 'product',
      'methods': 'list',
    });
    expect(badMethods.isError, isTrue);
    final badJson = await call('ag_generate_module', {
      'module_path': 'product',
      'json_sample': '{',
    });
    expect(badJson.isError, isTrue);
    final noProject = await call('ag_analyze', {'project_root': p.join(appDir.path, 'missing')});
    expect(noProject.isError, isTrue);
  });

  test("without project_root, uses the client's single workspace root", () async {
    final elsewhere = Directory.systemTemp.createTempSync('ag_mcp_cwd_');
    addTearDown(() => elsewhere.deleteSync(recursive: true));
    final client = _RootsClient()..addRoot(Root(uri: appDir.uri.toString()));
    final rooted = await connect(client, elsewhere);

    final result = await rooted.callTool(CallToolRequest(name: 'ag_init'));
    expect(result.isError, isNot(true));
    expect(File(p.join(appDir.path, 'AGENTS.md')).existsSync(), isTrue);
    expect(elsewhere.listSync(), isEmpty);
  });

  test('ag mcp serves the tools over stdio', () async {
    final process = await Process.start(
      Platform.resolvedExecutable,
      ['run', p.join(Directory.current.path, 'bin', 'ag.dart'), 'mcp'],
      workingDirectory: appDir.path,
    );
    final client = _TestClient();
    final stdio = client.connectServer(stdioChannel(input: process.stdout, output: process.stdin));
    addTearDown(() async {
      await client.shutdown();
      process.kill();
    });
    await _handshake(stdio, client);

    final result = await stdio.callTool(CallToolRequest(name: 'ag_init'));
    expect(result.isError, isNot(true));
    expect(File(p.join(appDir.path, 'AGENTS.md')).existsSync(), isTrue);
  }, timeout: const Timeout(Duration(minutes: 2)));
}
