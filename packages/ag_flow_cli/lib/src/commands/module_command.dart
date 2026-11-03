import 'dart:io';

import 'package:ag_flow_cli/src/generators/aggregator_updater.dart';
import 'package:ag_flow_cli/src/generators/app_routes_updater.dart';
import 'package:ag_flow_cli/src/generators/module_generator.dart';
import 'package:ag_flow_cli/src/generators/module_options.dart';
import 'package:ag_flow_cli/src/io/executor.dart';
import 'package:ag_flow_cli/src/io/file_op.dart';
import 'package:ag_flow_cli/src/io/project.dart';
import 'package:ag_flow_cli/src/naming/case_convert.dart';
import 'package:ag_flow_cli/src/naming/model_spec.dart';
import 'package:ag_flow_cli/src/naming/module_path.dart';
import 'package:ag_flow_cli/src/naming/pluralizer.dart';
import 'package:args/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';

/// `ag generate module <module_path>` (aliased `ag g m <module_path>`).
class ModuleCommand extends Command<int> {
  ModuleCommand({required this.logger}) {
    argParser
      ..addOption(
        'plural',
        help:
            'Override the pluralized class/file prefix for a root module '
            '(e.g. "company" would default to "Companys" — pass '
            '--plural=companies to fix it). Only meaningful for root '
            'modules; ignored for detail/child modules, which are never '
            'pluralized.',
      )
      ..addOption(
        'methods',
        help:
            'Which mutation-method stubs to generate across '
            'Service/Repo/Controller, beyond the always-present read '
            'method — a comma-separated subset of create,update,destroy '
            '(create is silently dropped for detail modules, which have '
            'no "create a new one" concept). Defaults to all of them; '
            'pass --methods=none to generate only the read method.',
      )
      ..addFlag(
        'paginate',
        negatable: false,
        help:
            'Make a collection module page its list: the Service declares '
            'an AgPagination (?page=1&limit=20 by default) and the '
            'Controller mixes in AgLoadMore. Ignored for detail modules.',
      )
      ..addFlag(
        'test',
        defaultsTo: true,
        help:
            'Write a starter test for the module under '
            'test/modules/<root>/. Pass --no-test to skip it.',
      )
      ..addOption(
        'model',
        help:
            'The model type this module works with, e.g. --model=Product. '
            'Generates the model class and threads the real type through '
            'the Service, Repo, Controller, Page and item component, so '
            'the module compiles against your data instead of leaving '
            '`dynamic` placeholders to replace by hand.',
      )
      ..addOption(
        'from-json',
        help:
            'Path to a JSON file holding a sample API response for this '
            'module. The model type and its fields are inferred from it — '
            'paste a real response body; a list and a single-key envelope '
            'such as {"data": [...]} are both understood. Implies --model, '
            'whose value (or the module name) becomes the class name.',
      );
  }

  final Logger logger;

  @override
  final name = 'module';

  @override
  final aliases = ['m'];

  @override
  final description = 'Generate a feature module: ag g m <module_path>';

  @override
  String get invocation => 'ag generate module <module_path>';

  @override
  Future<int> run() async {
    final rest = argResults!.rest;
    if (rest.isEmpty) {
      usageException(
        'Missing <module_path>, e.g. "ag g m product" or "ag g m product/details".',
      );
    }
    if (rest.length > 1) {
      usageException(
        'Expected exactly one <module_path>, got: ${rest.join(' ')}',
      );
    }

    final ModulePath modulePath;
    try {
      modulePath = ModulePath.parse(rest.single);
    } on FormatException catch (e) {
      logger.err(e.message);
      return ExitCode.usage.code;
    }

    final dryRun = globalResults?['dry-run'] as bool? ?? false;
    final project = Project(Directory.current);
    final pluralOverride = argResults!['plural'] as String?;

    final Set<String> methods;
    try {
      methods = parseMethods(argResults!['methods'] as String?);
    } on FormatException catch (e) {
      usageException(e.message);
    }

    final ModelSpec? model;
    try {
      final fromJson = argResults!['from-json'] as String?;
      model = resolveModel(
        modulePath,
        project,
        model: argResults!['model'] as String?,
        jsonText: fromJson == null ? null : File(fromJson).readAsStringSync(),
        jsonLabel: '--from-json file $fromJson',
        onInfo: logger.info,
      );
    } on FormatException catch (e) {
      logger.err(e.message);
      return ExitCode.usage.code;
    } on FileSystemException catch (e) {
      logger.err('Could not read --from-json file: ${e.path}');
      return ExitCode.noInput.code;
    }

    final generator = ModuleGenerator(
      project: project,
      pluralizer: pluralOverride == null ? defaultPluralizer : (_) => pascalCase(pluralOverride),
      methods: methods,
      model: model,
      paginate: argResults!['paginate'] as bool,
      withTests: argResults!['test'] as bool,
    );

    final List<FileOp> ops;
    try {
      ops = await generator.plan(modulePath);
    } on ParentModuleNotFoundException catch (e) {
      logger.err('$e');
      return ExitCode.usage.code;
    } on AggregatorFileNotFoundException catch (e) {
      logger.err('$e');
      return ExitCode.config.code;
    } on RouteConflictException catch (e) {
      logger.err('$e');
      return ExitCode.software.code;
    }

    final executor = Executor(dryRun: dryRun, logger: logger);
    final written = await executor.execute(ops);

    if (dryRun) {
      logger.info('\nDry run — no files were written.');
    } else if (written == 0) {
      logger.info('\nNothing to do — ${modulePath.asString} already exists.');
    } else {
      logger.success(
        '\nGenerated $written file(s) for ${modulePath.asString}.',
      );
    }
    return ExitCode.success.code;
  }
}
