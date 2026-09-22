import 'dart:io';

import 'package:ag_flow_cli/src/generators/init_generator.dart';
import 'package:ag_flow_cli/src/generators/module_generator.dart';
import 'package:ag_flow_cli/src/io/executor.dart';
import 'package:ag_flow_cli/src/io/project.dart';
import 'package:ag_flow_cli/src/naming/module_path.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

/// Proves Phase 4 (`ag init`) and Phase 3 (the aggregator engine) work
/// together on a genuinely bare project — not a hand-seeded fixture.
void main() {
  final quietLogger = Logger(level: Level.quiet);
  late Directory appDir;

  setUp(() {
    appDir = Directory.systemTemp.createTempSync(
      'ag_flow_cli_integration_test_',
    );
    File(
      p.join(appDir.path, 'pubspec.yaml'),
    ).writeAsStringSync('name: sample_app\n');
  });

  tearDown(() => appDir.deleteSync(recursive: true));

  test(
    'ag init followed by ag g m product/details produces a project with no dangling references '
    'in the aggregator files',
    () async {
      final project = Project(appDir);

      final initOps = InitGenerator(project: project).plan();
      final initWritten = await Executor(
        dryRun: false,
        logger: quietLogger,
      ).execute(initOps);
      expect(
        initWritten,
        10,
        reason:
            'a bare project gets the core/ skeleton plus the agent '
            'standard, CI gate and pre-commit hook',
      );

      final generator = ModuleGenerator(project: project);
      final productOps = await generator.plan(ModulePath.parse('product'));
      await Executor(dryRun: false, logger: quietLogger).execute(productOps);

      final detailOps = await generator.plan(
        ModulePath.parse('product/details'),
      );
      await Executor(dryRun: false, logger: quietLogger).execute(detailOps);

      final appPages = File(
        p.join(appDir.path, 'lib', 'core', 'routes', 'app_pages.dart'),
      ).readAsStringSync();
      expect(appPages, contains('ProductsPage'));
      expect(appPages, contains('ProductDetailsPage'));

      final argumentsFile = File(
        p.join(appDir.path, 'lib', 'core', 'arguments', 'arguments.dart'),
      ).readAsStringSync();
      expect(argumentsFile, contains('class ProductDetailsPageArgument'));

      // Re-running both, from the freshly-initialized state, must be a
      // pure no-op — proving init's skeleton is itself a valid,
      // idempotency-compatible starting point for the generator.
      final reOps = [
        ...await generator.plan(ModulePath.parse('product')),
        ...await generator.plan(ModulePath.parse('product/details')),
      ];
      final reWritten = await Executor(
        dryRun: false,
        logger: quietLogger,
      ).execute(reOps);
      expect(reWritten, 0);
    },
  );
}
