import 'dart:convert';
import 'dart:io';

import 'package:ag_flow_cli/src/io/file_op.dart';
import 'package:path/path.dart' as p;

/// The name every client config registers the AG server under.
const mcpServerName = 'ag';

/// How a client launches `ag mcp`: through the project's own
/// `ag_flow_cli` dev_dependency, so the server always matches the version
/// the project pins. `dart run` walks up from its working directory to the
/// nearest `pubspec.yaml`, so any folder inside the project works, and it
/// prints nothing on stdout before the server starts — stdout is the MCP
/// channel.
const Map<String, Object> _launch = {
  'command': 'dart',
  'args': ['run', 'ag_flow_cli:ag', 'mcp'],
};

/// One coding agent's project-level MCP config file.
class McpClientConfig {
  const McpClientConfig(this.relativePath, this.serversKey, this.entry);

  /// Where the client reads its project config, relative to the root.
  final String relativePath;

  /// The top-level key the client lists its servers under.
  final String serversKey;

  /// The `ag` server entry in this client's format.
  final Map<String, Object> entry;
}

/// Claude Code (`.mcp.json`), Cursor (`.cursor/mcp.json`) and VS Code
/// (`.vscode/mcp.json`), each in the format its own docs define.
final mcpClientConfigs = [
  const McpClientConfig('.mcp.json', 'mcpServers', _launch),
  McpClientConfig(p.join('.cursor', 'mcp.json'), 'mcpServers', _launch),
  McpClientConfig(p.join('.vscode', 'mcp.json'), 'servers', {
    'type': 'stdio',
    ..._launch,
    'cwd': r'${workspaceFolder}',
  }),
];

/// Plans the `ag` entry in one client's config under [root].
///
/// A missing file is created. An existing one only ever gains the `ag`
/// entry — every other server and key is kept — and is skipped when it
/// already has one, or when it is not plain JSON (VS Code allows
/// comments, which re-encoding would drop).
FileOp planMcpConfig(Directory root, McpClientConfig config) {
  final path = p.join(root.path, config.relativePath);
  final file = File(path);
  if (!file.existsSync()) {
    return FileOp.create(
      path: path,
      content: _encode({
        config.serversKey: {mcpServerName: config.entry},
      }),
    );
  }

  final Object? decoded;
  try {
    decoded = jsonDecode(file.readAsStringSync());
  } on FormatException {
    return FileOp.skipExisting(path: path);
  }
  if (decoded is! Map<String, Object?>) return FileOp.skipExisting(path: path);

  final servers = decoded[config.serversKey] ?? <String, Object?>{};
  if (servers is! Map<String, Object?> || servers.containsKey(mcpServerName)) {
    return FileOp.skipExisting(path: path);
  }
  return FileOp.update(
    path: path,
    content: _encode({
      ...decoded,
      config.serversKey: {...servers, mcpServerName: config.entry},
    }),
  );
}

String _encode(Object json) => '${const JsonEncoder.withIndent('  ').convert(json)}\n';
