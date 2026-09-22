import 'dart:io';

import 'package:ag_flow_cli/src/generators/init_generator.dart';
import 'package:ag_flow_cli/src/io/executor.dart';
import 'package:ag_flow_cli/src/io/file_op.dart';
import 'package:ag_flow_cli/src/io/project.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

Directory _createBareApp() {
  final dir = Directory.systemTemp.createTempSync('ag_flow_cli_init_test_');
  File(
    p.join(dir.path, 'pubspec.yaml'),
  ).writeAsStringSync('name: sample_app\n');
  return dir;
}

void main() {
  final quietLogger = Logger(level: Level.quiet);
  late Directory appDir;

  setUp(() => appDir = _createBareApp());
  tearDown(() => appDir.deleteSync(recursive: true));

  group('InitGenerator', () {
    test('creates the full core/ skeleton on a bare project', () async {
      final ops = InitGenerator(project: Project(appDir)).plan();
      final written = await Executor(
        dryRun: false,
        logger: quietLogger,
      ).execute(ops);

      expect(written, 10);
      for (final relativePath in [
        'core/arguments/arguments.dart',
        'core/endpoints.dart',
        'core/routes/app_routes.dart',
        'core/routes/app_pages.dart',
        'core/routes/route_management.dart',
        'core/bindings/initial_binding.dart',
      ]) {
        expect(
          File(p.join(appDir.path, 'lib', relativePath)).existsSync(),
          isTrue,
          reason: relativePath,
        );
      }
    });

    test(
      'scaffolds the agent standard and the gate that enforces it',
      () async {
        final ops = InitGenerator(project: Project(appDir)).plan();
        await Executor(dryRun: false, logger: quietLogger).execute(ops);

        String rootFile(String relativePath) =>
            File(p.join(appDir.path, relativePath)).readAsStringSync();

        // The standard itself, at the project root where a coding agent
        // picks it up without being told.
        expect(
          rootFile('AGENTS.md'),
          allOf(
            contains('Page → Controller → Repo → Service → ApiProvider'),
            contains('ag g m'),
            contains('You MUST NOT'),
          ),
        );
        expect(
          rootFile('CLAUDE.md'),
          contains('AGENTS.md'),
          reason: 'CLAUDE.md points at the standard rather than duplicating it',
        );

        // Instructions are advisory; the gate is not.
        expect(
          rootFile(p.join('.github', 'workflows', 'ag.yaml')),
          contains('ag analyze'),
        );
        expect(
          rootFile(p.join('.githooks', 'pre-commit')),
          contains('ag analyze'),
        );
      },
    );

    test(
      'the pre-commit hook is written executable',
      () async {
        final ops = InitGenerator(project: Project(appDir)).plan();
        await Executor(dryRun: false, logger: quietLogger).execute(ops);

        final hook = File(p.join(appDir.path, '.githooks', 'pre-commit'));
        final mode = await Process.run('test', ['-x', hook.path]);
        expect(
          mode.exitCode,
          0,
          reason: 'git silently ignores a hook without the executable bit',
        );
      },
      skip: Platform.isWindows ? 'POSIX mode bits only' : null,
    );

    test(
      'the generated skeleton has a valid AppRoutes/_Routes/AppPages/RouteManagement shape',
      () async {
        final ops = InitGenerator(project: Project(appDir)).plan();
        await Executor(dryRun: false, logger: quietLogger).execute(ops);

        final appRoutes = File(
          p.join(appDir.path, 'lib', 'core', 'routes', 'app_routes.dart'),
        ).readAsStringSync();
        expect(appRoutes, contains('abstract class AppRoutes'));
        expect(appRoutes, contains('abstract class _Routes'));
        expect(appRoutes, contains("static const String initial = '/';"));

        final appPages = File(
          p.join(appDir.path, 'lib', 'core', 'routes', 'app_pages.dart'),
        ).readAsStringSync();
        expect(appPages, contains('abstract class AppPages'));
        expect(
          appPages,
          contains('static final List<AgRoute> pages = [];'),
        );

        final routeManagement = File(
          p.join(appDir.path, 'lib', 'core', 'routes', 'route_management.dart'),
        ).readAsStringSync();
        expect(routeManagement, contains('abstract class RouteManagement'));

        final initialBinding = File(
          p.join(
            appDir.path,
            'lib',
            'core',
            'bindings',
            'initial_binding.dart',
          ),
        ).readAsStringSync();
        expect(
          initialBinding,
          contains('class InitialBinding extends AgBinding'),
        );
        expect(initialBinding, contains('put<ApiProvider>('));
      },
    );

    test(
      'running init twice never overwrites an already-initialized project',
      () async {
        final generator = InitGenerator(project: Project(appDir));
        await Executor(
          dryRun: false,
          logger: quietLogger,
        ).execute(generator.plan());

        final appRoutesPath = p.join(
          appDir.path,
          'lib',
          'core',
          'routes',
          'app_routes.dart',
        );
        File(appRoutesPath).writeAsStringSync(
          '// a developer already started customizing this file\n',
        );

        final secondOps = generator.plan();
        expect(
          secondOps,
          everyElement(
            isA<FileOp>().having(
              (op) => op.kind,
              'kind',
              FileOpKind.skipExisting,
            ),
          ),
        );
        final written = await Executor(
          dryRun: false,
          logger: quietLogger,
        ).execute(secondOps);

        expect(written, 0);
        expect(
          File(appRoutesPath).readAsStringSync(),
          '// a developer already started customizing this file\n',
        );
      },
    );

    test(
      'dry-run reports the planned files without writing anything',
      () async {
        final ops = InitGenerator(project: Project(appDir)).plan();
        final written = await Executor(
          dryRun: true,
          logger: quietLogger,
        ).execute(ops);

        expect(written, 0);
        expect(Directory(p.join(appDir.path, 'lib')).existsSync(), isFalse);
      },
    );
  });
}
