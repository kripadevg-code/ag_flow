import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:ag_flow_cli/src/analyze/analyze_issue.dart';
import 'package:ag_flow_cli/src/analyze/project_analyzer.dart';
import 'package:ag_flow_cli/src/analyze/route_table.dart';
import 'package:ag_flow_cli/src/generators/aggregator_updater.dart';
import 'package:ag_flow_cli/src/generators/app_routes_updater.dart';
import 'package:ag_flow_cli/src/generators/init_generator.dart';
import 'package:ag_flow_cli/src/generators/module_generator.dart';
import 'package:ag_flow_cli/src/generators/module_options.dart';
import 'package:ag_flow_cli/src/io/executor.dart';
import 'package:ag_flow_cli/src/io/file_op.dart';
import 'package:ag_flow_cli/src/io/project.dart';
import 'package:ag_flow_cli/src/naming/case_convert.dart';
import 'package:ag_flow_cli/src/naming/module_path.dart';
import 'package:ag_flow_cli/src/naming/pluralizer.dart';
import 'package:ag_flow_cli/src/version.dart';
import 'package:dart_mcp/server.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:path/path.dart' as p;

/// The `ag mcp` server: AG's generator and analyzer as MCP tools, so a
/// coding agent builds modules through the same code path as `ag g m`
/// instead of hand-writing layer files.
///
/// Local stdio only — it reads and writes the project on this machine and
/// makes no network calls. Every tool takes an optional `project_root`,
/// defaulting to the client's workspace root (MCP roots) and then to the
/// directory the server was started in.
base class AgMcpServer extends MCPServer with LoggingSupport, RootsTrackingSupport, ToolsSupport {
  AgMcpServer(super.channel, {Directory? workingDirectory})
    : _workingDirectory = workingDirectory ?? Directory.current,
      super.fromStreamChannel(
        implementation: Implementation(name: 'ag', version: agCliVersion),
        instructions:
            'AG Flow architecture tools. Call ag_rules before changing a '
            'project. Create modules with ag_generate_module, never by '
            'hand-writing layer files. Run ag_analyze after every change '
            'and fix what it reports.',
      ) {
    registerTool(_rulesTool, _rules);
    registerTool(_initTool, _init);
    registerTool(_generateModuleTool, _generateModule);
    registerTool(_analyzeTool, _analyze);
    registerTool(_listModulesTool, _listModules);
  }

  final Directory _workingDirectory;

  /// Generators log through a [Logger]; on stdio that would write into the
  /// protocol stream, so the server's is always silent.
  final _quietLogger = Logger(level: Level.quiet);

  static final StringSchema _projectRoot = Schema.string(
    description:
        'Absolute path of the Flutter project (the folder with pubspec.yaml). '
        "Defaults to the client's workspace root, then the server's directory.",
  );

  static final BooleanSchema _dryRun = Schema.bool(
    description: 'Report the planned file operations without writing.',
  );

  // Output schemas: the MCP spec requires structured results to conform
  // to the tool's declared `outputSchema`, so clients can validate them.

  static final ObjectSchema _filesOutput = Schema.object(
    properties: {
      'dry_run': Schema.bool(),
      'files': Schema.list(
        items: Schema.object(
          properties: {
            'path': Schema.string(description: 'Relative to the project root.'),
            'action': Schema.string(enumValues: ['create', 'update', 'skip']),
          },
          required: ['path', 'action'],
        ),
      ),
    },
    required: ['dry_run', 'files'],
  );

  static final ObjectSchema _analyzeOutput = Schema.object(
    properties: {
      'issues': Schema.list(
        items: Schema.object(
          properties: {
            'category': Schema.string(
              enumValues: [for (final c in AnalyzeCategory.values) c.name],
            ),
            'file': Schema.string(description: 'Relative to the project root.'),
            'message': Schema.string(),
          },
          required: ['category', 'file', 'message'],
        ),
      ),
      'resolved_checks_ran': Schema.bool(
        description:
            'False when dependencies are not resolved yet (run pub get): the '
            'dependency-direction and detail-argument checks were skipped.',
      ),
    },
    required: ['issues', 'resolved_checks_ran'],
  );

  static final ObjectSchema _modulesOutput = Schema.object(
    properties: {
      'modules': Schema.list(
        items: Schema.object(
          properties: {
            'module_path': Schema.string(),
            'kind': Schema.string(enumValues: ['collection', 'detail']),
            'route_name': Schema.string(),
            'route_path': Schema.string(),
            'model': Schema.string(description: 'Absent when the module is untyped.'),
          },
          required: ['module_path', 'kind', 'route_name', 'route_path'],
        ),
      ),
    },
    required: ['modules'],
  );

  final _rulesTool = Tool(
    name: 'ag_rules',
    description:
        'The AG Flow architecture standard: layers, folders, generator use '
        'and what is not allowed. Read it before changing a project.',
    inputSchema: Schema.object(),
    annotations: ToolAnnotations(readOnlyHint: true, idempotentHint: true),
  );

  final _initTool = Tool(
    name: 'ag_init',
    description:
        'Bootstrap a project for AG: writes lib/core/ and the architecture '
        'files (AGENTS.md, CI workflow, git hook). Existing files are '
        'never overwritten.',
    inputSchema: Schema.object(
      properties: {'project_root': _projectRoot, 'dry_run': _dryRun},
    ),
    outputSchema: _filesOutput,
    annotations: ToolAnnotations(destructiveHint: false, idempotentHint: true),
  );

  final _generateModuleTool = Tool(
    name: 'ag_generate_module',
    description:
        'Generate a feature module (page, controller, repo, service, '
        'binding, components, starter test) and wire its route — the same '
        'as "ag g m". Existing files are never overwritten.',
    inputSchema: Schema.object(
      properties: {
        'module_path': Schema.string(
          description: 'e.g. "product" (collection) or "product/details" (detail).',
        ),
        'project_root': _projectRoot,
        'model': Schema.string(
          description: 'Model class name, e.g. "Product". Types the whole stack.',
        ),
        'json_sample': Schema.string(
          description:
              'A real API response body as JSON text; the model fields are '
              'inferred from it. A list or an envelope such as {"data": [...]} '
              'is understood.',
        ),
        'methods': Schema.string(
          description:
              'Comma-separated subset of create,update,destroy, or "none". '
              'Defaults to all.',
        ),
        'paginate': Schema.bool(
          description: 'Page the list (collection modules only).',
        ),
        'test': Schema.bool(
          description: 'Write a starter test. Defaults to true.',
        ),
        'plural': Schema.string(
          description: 'Override the pluralized prefix of a root module, e.g. "companies".',
        ),
        'dry_run': _dryRun,
      },
      required: ['module_path'],
    ),
    outputSchema: _filesOutput,
    annotations: ToolAnnotations(destructiveHint: false, idempotentHint: true),
  );

  final _analyzeTool = Tool(
    name: 'ag_analyze',
    description:
        "Check a project against AG's architecture rules. Returns every "
        'violation with its category and file; an empty list means clean.',
    inputSchema: Schema.object(properties: {'project_root': _projectRoot}),
    outputSchema: _analyzeOutput,
    annotations: ToolAnnotations(readOnlyHint: true, idempotentHint: true),
  );

  final _listModulesTool = Tool(
    name: 'ag_list_modules',
    description: 'List the modules a project has, read from its route table.',
    inputSchema: Schema.object(properties: {'project_root': _projectRoot}),
    outputSchema: _modulesOutput,
    annotations: ToolAnnotations(readOnlyHint: true, idempotentHint: true),
  );

  FutureOr<CallToolResult> _rules(CallToolRequest request) =>
      CallToolResult(content: [TextContent(text: agentsStandard)]);

  Future<CallToolResult> _init(CallToolRequest request) async {
    final dir = await _projectDir(request);
    final project = _projectAt(dir);
    if (project == null) return _noProject(dir);
    final ops = InitGenerator(project: project).plan();
    return _applied(project, ops, dryRun: _flag(request, 'dry_run'));
  }

  Future<CallToolResult> _generateModule(CallToolRequest request) async {
    final dir = await _projectDir(request);
    final project = _projectAt(dir);
    if (project == null) return _noProject(dir);
    final args = request.arguments ?? const {};

    final ModulePath modulePath;
    try {
      modulePath = ModulePath.parse(args['module_path']! as String);
      final plural = args['plural'] as String?;
      final generator = ModuleGenerator(
        project: project,
        pluralizer: plural == null ? defaultPluralizer : (_) => pascalCase(plural),
        methods: parseMethods(args['methods'] as String?),
        model: resolveModel(
          modulePath,
          project,
          model: args['model'] as String?,
          jsonText: args['json_sample'] as String?,
          jsonLabel: 'json_sample',
        ),
        paginate: _flag(request, 'paginate'),
        withTests: _flag(request, 'test', defaultValue: true),
      );
      final ops = await generator.plan(modulePath);
      return await _applied(project, ops, dryRun: _flag(request, 'dry_run'));
    } on FormatException catch (e) {
      return _error(e.message);
    } on ParentModuleNotFoundException catch (e) {
      return _error('$e');
    } on AggregatorFileNotFoundException catch (e) {
      return _error('$e Call ag_init first.');
    } on RouteConflictException catch (e) {
      return _error('$e');
    }
  }

  Future<CallToolResult> _analyze(CallToolRequest request) async {
    final dir = await _projectDir(request);
    final project = _projectAt(dir);
    if (project == null) return _noProject(dir);
    final analyzer = ProjectAnalyzer(project: project);
    try {
      final issues = await analyzer.analyze();
      return _json({
        'issues': [
          for (final issue in issues)
            {
              'category': issue.category.name,
              'file': issue.file,
              'message': issue.message,
            },
        ],
        // The resolved-model checks (dependency direction, unused detail
        // arguments) need `pub get`; say so instead of implying they passed.
        'resolved_checks_ran': await analyzer.dependenciesResolved,
      });
    } on ProjectNotInitializedException catch (e) {
      return _error('$e Call ag_init first.');
    }
  }

  Future<CallToolResult> _listModules(CallToolRequest request) async {
    final dir = await _projectDir(request);
    final project = _projectAt(dir);
    if (project == null) return _noProject(dir);
    final appRoutes = File(p.join(project.libDir.path, 'core', 'routes', 'app_routes.dart'));
    if (!appRoutes.existsSync()) {
      return _error('${const ProjectNotInitializedException()} Call ag_init first.');
    }
    final modules = <Map<String, Object?>>[];
    for (final route in parseRouteTable(appRoutes.readAsStringSync())) {
      // Same derivation as `ag analyze`: drop `:param` segments to get the
      // module path the route was generated from.
      final structural = route.path
          .split('/')
          .where((segment) => segment.isNotEmpty && !segment.startsWith(':'))
          .join('/');
      final ModulePath modulePath;
      try {
        modulePath = ModulePath.parse(structural);
      } on FormatException {
        continue; // A hand-written route that no module produced.
      }
      modules.add({
        'module_path': modulePath.asString,
        'kind': modulePath.isRoot ? 'collection' : 'detail',
        'route_name': route.name,
        'route_path': route.path,
        if (existingModel(modulePath.rootSegment, project) case final model?)
          'model': model.className,
      });
    }
    return _json({'modules': modules});
  }

  Future<CallToolResult> _applied(
    Project project,
    List<FileOp> ops, {
    required bool dryRun,
  }) async {
    if (!dryRun) {
      await Executor(dryRun: false, logger: _quietLogger).execute(ops);
    }
    return _json({
      'dry_run': dryRun,
      'files': [
        for (final op in ops)
          {
            'path': p.relative(op.path, from: project.root.path),
            'action': switch (op.kind) {
              FileOpKind.create => 'create',
              FileOpKind.update => 'update',
              FileOpKind.skipExisting => 'skip',
            },
          },
      ],
    });
  }

  /// The project a call targets: its `project_root`, else the client's
  /// workspace when it shares exactly one `file:` root (MCP roots), else
  /// the directory the server was started in.
  Future<Directory> _projectDir(CallToolRequest request) async {
    final root = request.arguments?['project_root'] as String?;
    if (root != null) {
      return Directory(p.normalize(p.absolute(_workingDirectory.path, root)));
    }
    if (supportsRoots) {
      final fileRoots = [
        for (final r in await roots)
          if (Uri.parse(r.uri) case final uri when uri.isScheme('file')) uri,
      ];
      if (fileRoots.length == 1) return Directory(fileRoots.single.toFilePath());
    }
    return _workingDirectory;
  }

  static Project? _projectAt(Directory dir) =>
      File(p.join(dir.path, 'pubspec.yaml')).existsSync() ? Project(dir) : null;

  static CallToolResult _noProject(Directory dir) =>
      _error('No pubspec.yaml found in ${dir.path} — pass project_root.');

  static bool _flag(CallToolRequest request, String name, {bool defaultValue = false}) =>
      request.arguments?[name] as bool? ?? defaultValue;

  static CallToolResult _json(Map<String, Object?> data) => CallToolResult(
    content: [TextContent(text: jsonEncode(data))],
    structuredContent: data,
  );

  static CallToolResult _error(String message) =>
      CallToolResult(content: [TextContent(text: message)], isError: true);
}
