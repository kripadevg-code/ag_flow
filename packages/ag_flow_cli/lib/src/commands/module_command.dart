import 'dart:io';

import 'package:ag_flow_cli/src/generators/aggregator_updater.dart';
import 'package:ag_flow_cli/src/generators/app_routes_updater.dart';
import 'package:ag_flow_cli/src/generators/module_generator.dart';
import 'package:ag_flow_cli/src/io/executor.dart';
import 'package:ag_flow_cli/src/io/file_op.dart';
import 'package:ag_flow_cli/src/io/project.dart';
import 'package:ag_flow_cli/src/naming/case_convert.dart';
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
            'method — a comma-separated subset of add,update,delete '
            '(add is silently dropped for detail modules, which have '
            'no "create a new one" concept). Defaults to all of them; '
            'pass --methods=none to generate only the read method.',
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

    final methodsOption = argResults!['methods'] as String?;
    final Set<String> methods;
    if (methodsOption == null) {
      methods = generatableMethods;
    } else if (methodsOption == 'none') {
      methods = const {};
    } else {
      methods = methodsOption.split(',').map((m) => m.trim()).toSet();
      final unknown = methods.difference(generatableMethods);
      if (unknown.isNotEmpty) {
        usageException(
          'Unrecognized --methods value(s): ${unknown.join(', ')}. '
          'Expected a comma-separated subset of '
          '${generatableMethods.join(', ')}, or "none".',
        );
      }
    }

    final generator = ModuleGenerator(
      project: project,
      pluralizer: pluralOverride == null
          ? defaultPluralizer
          : (_) => pascalCase(pluralOverride),
      methods: methods,
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
