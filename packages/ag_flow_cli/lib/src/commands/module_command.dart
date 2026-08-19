import 'dart:io';

import 'package:ag_flow_cli/src/generators/aggregator_updater.dart';
import 'package:ag_flow_cli/src/generators/app_routes_updater.dart';
import 'package:ag_flow_cli/src/generators/module_generator.dart';
import 'package:ag_flow_cli/src/io/executor.dart';
import 'package:ag_flow_cli/src/io/file_op.dart';
import 'package:ag_flow_cli/src/io/project.dart';
import 'package:ag_flow_cli/src/naming/module_path.dart';
import 'package:args/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';

/// `ag generate module <module_path>` (aliased `ag g m <module_path>`).
class ModuleCommand extends Command<int> {
  ModuleCommand({required this.logger});

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
    final generator = ModuleGenerator(project: project);

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
