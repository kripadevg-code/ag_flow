import 'dart:io';

import 'package:ag_flow_cli/src/generators/module_generator.dart';
import 'package:ag_flow_cli/src/io/executor.dart';
import 'package:ag_flow_cli/src/io/file_op.dart';
import 'package:ag_flow_cli/src/io/project.dart';
import 'package:ag_flow_cli/src/naming/module_path.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

Directory _createSampleApp() {
  final dir = Directory.systemTemp.createTempSync('ag_flow_cli_test_');
  File(
    p.join(dir.path, 'pubspec.yaml'),
  ).writeAsStringSync('name: sample_app\n');
  return dir;
}

/// Every file under [root], as paths relative to [root], sorted.
List<String> _listFiles(Directory root) {
  if (!root.existsSync()) return const [];
  return root
      .listSync(recursive: true)
      .whereType<File>()
      .map((f) => p.relative(f.path, from: root.path))
      .toList()
    ..sort();
}

/// Asserts [generatedRoot]'s file set and every file's content exactly
/// matches [goldenRoot].
void _expectMatchesGolden(Directory generatedRoot, Directory goldenRoot) {
  final generatedFiles = _listFiles(generatedRoot);
  final goldenFiles = _listFiles(goldenRoot);
  expect(
    generatedFiles,
    goldenFiles,
    reason: 'generated file set does not match the golden file set',
  );

  for (final relativePath in goldenFiles) {
    final actual = File(
      p.join(generatedRoot.path, relativePath),
    ).readAsStringSync();
    final expected = File(
      p.join(goldenRoot.path, relativePath),
    ).readAsStringSync();
    expect(actual, expected, reason: 'content mismatch for $relativePath');
  }
}

/// Fakes a module as "already generated" without running a real
/// generation — enough to satisfy [ModuleGenerator]'s parent-existence
/// check, for tests that only care about a *child* module's own output.
void _touchParentController(Directory appDir, ModulePath parentPath) {
  final project = Project(appDir);
  // A minimal, throwaway pluralizer-independent stand-in is unnecessary
  // here — the parent-existence check only looks at whether the parent's
  // controller file exists, not its content.
  final parentFileName = parentPath.isRoot
      ? '${_pluralizeRootForTest(parentPath.rootSegment)}_controller.dart'
      : '${parentPath.segments.join('_')}_controller.dart';
  final controllerPath = p.join(
    project.moduleRootDir(parentPath.rootSegment),
    'controllers',
    parentFileName,
  );
  File(controllerPath)
    ..createSync(recursive: true)
    ..writeAsStringSync('// stand-in for a real generated controller\n');
}

// A tiny, deliberately-duplicated pluralization for root segments used in
// this test file only, matching the real default for the words used here
// ("product" -> "products", "ticket" -> "tickets") — avoids depending on
// the pluralize package's exact behavior in a *different* place than the
// naming module already tests it.
String _pluralizeRootForTest(String rootSegment) => '${rootSegment}s';

void main() {
  final quietLogger = Logger(level: Level.quiet);
  final goldensDir = Directory(
    p.join(Directory.current.path, 'test', 'goldens'),
  );

  late Directory appDir;

  setUp(() {
    appDir = _createSampleApp();
  });

  tearDown(() {
    appDir.deleteSync(recursive: true);
  });

  group('ModuleGenerator — golden file tests', () {
    test('a fresh root module matches the collection_module golden', () async {
      final ops = await ModuleGenerator(
        project: Project(appDir),
      ).plan(ModulePath.parse('product'));
      await Executor(dryRun: false, logger: quietLogger).execute(ops);

      _expectMatchesGolden(
        Directory(p.join(appDir.path, 'lib')),
        Directory(p.join(goldensDir.path, 'collection_module', 'lib')),
      );
    });

    test('a fresh detail module matches the detail_module golden', () async {
      _touchParentController(appDir, ModulePath.parse('product'));

      final ops = await ModuleGenerator(
        project: Project(appDir),
      ).plan(ModulePath.parse('product/details'));
      await Executor(dryRun: false, logger: quietLogger).execute(ops);

      final goldenDetailFiles = _listFiles(
        Directory(p.join(goldensDir.path, 'detail_module', 'lib')),
      );
      for (final relativePath in goldenDetailFiles) {
        final actual = File(
          p.join(appDir.path, 'lib', relativePath),
        ).readAsStringSync();
        final expected = File(
          p.join(goldensDir.path, 'detail_module', 'lib', relativePath),
        ).readAsStringSync();
        expect(actual, expected, reason: 'content mismatch for $relativePath');
      }
    });
  });

  group('ModuleGenerator — idempotency and parent handling', () {
    test(
      're-running the same module a second time performs no writes and changes nothing on disk',
      () async {
        final generator = ModuleGenerator(project: Project(appDir));
        final modulePath = ModulePath.parse('product');

        final firstOps = await generator.plan(modulePath);
        await Executor(dryRun: false, logger: quietLogger).execute(firstOps);
        final afterFirstRun = {
          for (final f in _listFiles(Directory(p.join(appDir.path, 'lib'))))
            f: File(p.join(appDir.path, 'lib', f)).readAsStringSync(),
        };

        final secondOps = await generator.plan(modulePath);
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

        final afterSecondRun = {
          for (final f in _listFiles(Directory(p.join(appDir.path, 'lib'))))
            f: File(p.join(appDir.path, 'lib', f)).readAsStringSync(),
        };
        expect(afterSecondRun, afterFirstRun);
      },
    );

    test(
      'generating a child module whose parent does not exist throws with the exact spec-mandated '
      'message and writes nothing at all',
      () async {
        final generator = ModuleGenerator(project: Project(appDir));

        await expectLater(
          generator.plan(ModulePath.parse('ticket/details')),
          throwsA(
            isA<ParentModuleNotFoundException>().having(
              (e) => e.toString(),
              'message',
              'ERROR: Parent module "ticket" does not exist.\n'
                  '\n'
                  'Create it first:\n'
                  '\n'
                  'ag g m ticket',
            ),
          ),
        );

        expect(Directory(p.join(appDir.path, 'lib')).existsSync(), isFalse);
      },
    );

    test(
      'dry-run reports create operations but writes nothing to disk',
      () async {
        final ops = await ModuleGenerator(
          project: Project(appDir),
        ).plan(ModulePath.parse('product'));
        final written = await Executor(
          dryRun: true,
          logger: quietLogger,
        ).execute(ops);

        expect(written, 0);
        expect(ops, isNotEmpty);
        expect(
          ops,
          everyElement(
            isA<FileOp>().having((op) => op.kind, 'kind', FileOpKind.create),
          ),
        );
        expect(Directory(p.join(appDir.path, 'lib')).existsSync(), isFalse);
      },
    );
  });

  group('ModuleGenerator — structural invariants', () {
    test(
      'a 4-deep nested detail module stays flat: no nested folders under any architectural '
      'layer, and exactly one (bare-leaf) component namespace',
      () async {
        _touchParentController(appDir, ModulePath.parse('product'));
        _touchParentController(appDir, ModulePath.parse('product/details'));
        _touchParentController(
          appDir,
          ModulePath.parse('product/details/reviews'),
        );

        final ops = await ModuleGenerator(
          project: Project(appDir),
        ).plan(ModulePath.parse('product/details/reviews/comments'));
        await Executor(dryRun: false, logger: quietLogger).execute(ops);

        final productRoot = Directory(p.join(appDir.path, 'lib', 'product'));
        for (final layer in [
          'controllers',
          'services',
          'repos',
          'bindings',
          'pages',
        ]) {
          final layerDir = Directory(p.join(productRoot.path, layer));
          final entries = layerDir.listSync();
          expect(
            entries,
            everyElement(isA<File>()),
            reason: '$layer/ must stay flat — no nested folders, even at depth',
          );
        }

        final componentsDir = Directory(p.join(productRoot.path, 'components'));
        final namespaces = componentsDir
            .listSync()
            .whereType<Directory>()
            .map((d) => p.basename(d.path))
            .toList();
        expect(
          namespaces,
          ['comments'],
          reason: 'component namespace must be the bare last segment only',
        );

        final commentsNamespace = Directory(
          p.join(componentsDir.path, 'comments'),
        );
        expect(
          commentsNamespace.listSync(),
          everyElement(isA<File>()),
          reason: 'no nested component namespaces',
        );
      },
    );

    test(
      'never generates an "Impl" class or a per-module ApiProvider/endpoints file',
      () async {
        _touchParentController(appDir, ModulePath.parse('product'));

        final rootOps = await ModuleGenerator(
          project: Project(appDir),
        ).plan(ModulePath.parse('product'));
        final detailOps = await ModuleGenerator(
          project: Project(appDir),
        ).plan(ModulePath.parse('product/details'));

        for (final op in [...rootOps, ...detailOps]) {
          expect(p.basename(op.path), isNot(contains('endpoints')));
          expect(
            p.basename(op.path),
            isNot(matches(RegExp('api_?provider', caseSensitive: false))),
          );
          if (op.kind == FileOpKind.create) {
            expect(op.content, isNot(contains('Impl')));
            expect(
              op.content,
              isNot(contains('ApiProvider(')),
              reason: 'no module should construct its own ApiProvider',
            );
          }
        }
      },
    );

    test(
      'sibling branches sharing a leaf segment name generate independent, non-colliding files',
      () async {
        _touchParentController(appDir, ModulePath.parse('product'));
        _touchParentController(appDir, ModulePath.parse('product/pricing'));
        _touchParentController(appDir, ModulePath.parse('product/shipping'));

        final generator = ModuleGenerator(project: Project(appDir));
        final aOps = await generator.plan(
          ModulePath.parse('product/pricing/details'),
        );
        await Executor(dryRun: false, logger: quietLogger).execute(aOps);
        final bOps = await generator.plan(
          ModulePath.parse('product/shipping/details'),
        );
        await Executor(dryRun: false, logger: quietLogger).execute(bOps);

        // Neither run should have been forced to skip anything — if the
        // naming scheme collided, the second run's files would already
        // exist (written by the first) and be silently skipped instead.
        expect(
          aOps,
          everyElement(
            isA<FileOp>().having((op) => op.kind, 'kind', FileOpKind.create),
          ),
        );
        expect(
          bOps,
          everyElement(
            isA<FileOp>().having((op) => op.kind, 'kind', FileOpKind.create),
          ),
        );

        final controllersDir = Directory(
          p.join(appDir.path, 'lib', 'product', 'controllers'),
        );
        final fileNames = controllersDir
            .listSync()
            .map((f) => p.basename(f.path))
            .toSet();
        expect(
          fileNames,
          containsAll([
            'product_pricing_details_controller.dart',
            'product_shipping_details_controller.dart',
          ]),
        );
      },
    );
  });
}
