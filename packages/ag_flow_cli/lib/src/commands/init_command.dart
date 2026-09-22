import 'dart:io';

import 'package:ag_flow_cli/src/generators/init_generator.dart';
import 'package:ag_flow_cli/src/io/executor.dart';
import 'package:ag_flow_cli/src/io/project.dart';
import 'package:args/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:path/path.dart' as p;

/// `ag init` — bootstraps the current project's `core/` skeleton so
/// `ag g m` has somewhere to wire generated modules into.
class InitCommand extends Command<int> {
  InitCommand({required this.logger});

  final Logger logger;

  @override
  final name = 'init';

  @override
  final description =
      'Bootstrap this project for AG: creates the lib/core/ skeleton.';

  @override
  Future<int> run() async {
    final projectRoot = Directory.current;
    if (!File(p.join(projectRoot.path, 'pubspec.yaml')).existsSync()) {
      logger.err(
        'No pubspec.yaml found in ${projectRoot.path} — is this a Dart/Flutter project?',
      );
      return ExitCode.usage.code;
    }

    final dryRun = globalResults?['dry-run'] as bool? ?? false;
    final ops = InitGenerator(project: Project(projectRoot)).plan();
    final written = await Executor(dryRun: dryRun, logger: logger).execute(ops);

    if (dryRun) {
      logger.info('\nDry run — no files were written.');
    } else if (written == 0) {
      logger.info('\nNothing to do — this project is already initialized.');
    } else {
      logger
        ..success('\nInitialized $written file(s).')
        ..info('\nNext steps:')
        ..info(
          '  1. In pubspec.yaml: ag_flow under dependencies, and '
          'ag_flow_cli under dev_dependencies (the architecture gate '
          'runs it via "dart run ag_flow_cli:ag").',
        )
        ..info(
          '  2. Set a real API base URL in lib/core/bindings/initial_binding.dart.',
        )
        ..info('  3. Wire AgApp in your main.dart:')
        ..info('       AgApp(')
        ..info('         initialRoute: AppRoutes.initial,')
        ..info('         initialBinding: InitialBinding(),')
        ..info('         routes: AppPages.pages,')
        ..info('       )')
        ..info('  4. Run "ag g m <module>" to generate your first module.')
        ..info(
          '  5. Enable the local architecture gate (optional, recommended):',
        )
        ..info('       git config core.hooksPath .githooks')
        ..info(
          "\nAGENTS.md now documents this project's architecture standard. "
          'Coding agents read it automatically, so they use "ag g m" and the '
          "framework's patterns instead of inventing their own. "
          '.github/workflows/ag.yaml runs "ag analyze" on every push, so '
          'code that breaks the architecture cannot merge.',
        );
    }
    return ExitCode.success.code;
  }
}
