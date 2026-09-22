import 'dart:convert';
import 'dart:io';

import 'package:ag_flow_cli/src/generators/aggregator_updater.dart';
import 'package:ag_flow_cli/src/generators/app_routes_updater.dart';
import 'package:ag_flow_cli/src/generators/module_generator.dart';
import 'package:ag_flow_cli/src/io/executor.dart';
import 'package:ag_flow_cli/src/io/file_op.dart';
import 'package:ag_flow_cli/src/io/project.dart';
import 'package:ag_flow_cli/src/naming/model_spec.dart';
import 'package:ag_flow_cli/src/naming/module_path.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

const _appRoutesSeed = '''
abstract class AppRoutes {
  static const String initial = _Routes.initial;
  static const String login = _Routes.login;
}

abstract class _Routes {
  static const String initial = '/';
  static const String login = '/login';
}
''';

const _appPagesSeed = '''
import 'package:ag_flow/ag_flow.dart';

import 'app_routes.dart';

abstract class AppPages {
  static const AgTransition defaultTransition = AgTransition.rightToLeft;

  static final List<AgRoute> pages = [];
}
''';

// The exact hand-customized navigation method from requirments/routes.md
// §19 — the canonical example of developer-owned routing logic that must
// survive regeneration untouched, no matter what else gets generated.
const _routeManagementSeed = '''
import 'package:ag_flow/ag_flow.dart';

import 'app_routes.dart';

abstract class RouteManagement {
  static void goToLoginPage({
    LoginPageArgument? model,
    bool canPopCurrentRoute = false,
  }) {
    AgLocator.delete<LoginController>();
    if (canPopCurrentRoute) {
      AgNavigator.offNamed(AppRoutes.login, arguments: model);
    } else {
      AgNavigator.toNamed(AppRoutes.login, arguments: model);
    }
  }
}
''';

const _argumentsSeed = '// Navigation argument classes.\n';

void _seedAggregatorFiles(Directory appDir) {
  final coreDir = p.join(appDir.path, 'lib', 'core');
  File(p.join(coreDir, 'routes', 'app_routes.dart'))
    ..createSync(recursive: true)
    ..writeAsStringSync(_appRoutesSeed);
  File(p.join(coreDir, 'routes', 'app_pages.dart'))
    ..createSync(recursive: true)
    ..writeAsStringSync(_appPagesSeed);
  File(p.join(coreDir, 'routes', 'route_management.dart'))
    ..createSync(recursive: true)
    ..writeAsStringSync(_routeManagementSeed);
  File(p.join(coreDir, 'arguments', 'arguments.dart'))
    ..createSync(recursive: true)
    ..writeAsStringSync(_argumentsSeed);
}

Directory _createSampleApp({bool seedAggregatorFiles = true}) {
  final dir = Directory.systemTemp.createTempSync('ag_flow_cli_test_');
  File(
    p.join(dir.path, 'pubspec.yaml'),
  ).writeAsStringSync('name: sample_app\n');
  if (seedAggregatorFiles) _seedAggregatorFiles(dir);
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

String _coreFile(Directory appDir, String relativePath) =>
    File(p.join(appDir.path, 'lib', 'core', relativePath)).readAsStringSync();

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

  group('ModuleGenerator — golden file tests (fresh-file layer only)', () {
    test('a fresh root module matches the collection_module golden', () async {
      final ops = await ModuleGenerator(
        project: Project(appDir),
      ).plan(ModulePath.parse('product'));
      await Executor(dryRun: false, logger: quietLogger).execute(ops);

      _expectMatchesGolden(
        Directory(p.join(appDir.path, 'lib', 'modules', 'product')),
        Directory(
          p.join(
            goldensDir.path,
            'collection_module',
            'lib',
            'modules',
            'product',
          ),
        ),
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

  group('ModuleGenerator — aggregator file updates', () {
    test(
      'generating a root module registers its route and AgRoute entry, and never touches arguments.dart',
      () async {
        final ops = await ModuleGenerator(
          project: Project(appDir),
        ).plan(ModulePath.parse('product'));
        await Executor(dryRun: false, logger: quietLogger).execute(ops);

        final appRoutes = _coreFile(
          appDir,
          p.join('routes', 'app_routes.dart'),
        );
        expect(
          appRoutes,
          contains('static const String product = _Routes.product;'),
        );
        expect(
          appRoutes,
          contains("static const String product = '/product';"),
        );

        final appPages = _coreFile(appDir, p.join('routes', 'app_pages.dart'));
        expect(appPages, contains('path: AppRoutes.product,'));
        expect(appPages, contains('page: ProductsPage.new,'));
        expect(appPages, contains('binding: ProductsBinding(),'));

        final routeManagement = _coreFile(
          appDir,
          p.join('routes', 'route_management.dart'),
        );
        expect(routeManagement, contains('static void goToProductsPage()'));
        expect(
          routeManagement,
          contains('AgNavigator.toNamed<dynamic>(AppRoutes.product);'),
        );

        expect(
          _coreFile(appDir, p.join('arguments', 'arguments.dart')),
          _argumentsSeed,
          reason: 'root modules take no argument',
        );
      },
    );

    test(
      'generating a detail module registers its argument class, route, AgRoute entry, and nav method',
      () async {
        _touchParentController(appDir, ModulePath.parse('product'));

        final ops = await ModuleGenerator(
          project: Project(appDir),
        ).plan(ModulePath.parse('product/details'));
        await Executor(dryRun: false, logger: quietLogger).execute(ops);

        final arguments = _coreFile(
          appDir,
          p.join('arguments', 'arguments.dart'),
        );
        expect(arguments, contains('class ProductDetailsPageArgument {'));

        final appRoutes = _coreFile(
          appDir,
          p.join('routes', 'app_routes.dart'),
        );
        expect(
          appRoutes,
          contains(
            'static const String productDetails = _Routes.productDetails;',
          ),
        );
        expect(
          appRoutes,
          contains(
            "static const String productDetails = '/product/details/:id';",
          ),
          reason:
              'a detail route declares a path parameter so the page is '
              'reachable from a deep link, not only an in-app push',
        );

        final appPages = _coreFile(appDir, p.join('routes', 'app_pages.dart'));
        expect(appPages, contains('path: AppRoutes.productDetails,'));
        expect(appPages, contains('page: ProductDetailsPage.new,'));
        expect(appPages, contains('binding: ProductDetailsBinding(),'));
        expect(
          appPages,
          contains(
            "import 'package:sample_app/modules/product/pages/product_details_page.dart';",
          ),
        );
        expect(
          appPages,
          contains(
            "import 'package:sample_app/modules/product/bindings/product_details_binding.dart';",
          ),
        );

        final routeManagement = _coreFile(
          appDir,
          p.join('routes', 'route_management.dart'),
        );
        expect(
          routeManagement,
          contains(
            'static void goToProductDetailsPage(ProductDetailsPageArgument argument)',
          ),
        );
        expect(
          routeManagement,
          contains(
            'pathParameters: argument.toPathParameters(),',
          ),
        );
        expect(
          routeManagement,
          contains(
            "import 'package:sample_app/core/arguments/arguments.dart';",
          ),
        );
      },
    );

    test(
      'a hand-customized navigation method survives generating an unrelated new module, byte-for-byte',
      () async {
        final ops = await ModuleGenerator(
          project: Project(appDir),
        ).plan(ModulePath.parse('product'));
        await Executor(dryRun: false, logger: quietLogger).execute(ops);

        final routeManagement = _coreFile(
          appDir,
          p.join('routes', 'route_management.dart'),
        );
        expect(
          routeManagement,
          contains(
            'static void goToLoginPage({\n'
            '    LoginPageArgument? model,\n'
            '    bool canPopCurrentRoute = false,\n'
            '  }) {\n'
            '    AgLocator.delete<LoginController>();\n'
            '    if (canPopCurrentRoute) {\n'
            '      AgNavigator.offNamed(AppRoutes.login, arguments: model);\n'
            '    } else {\n'
            '      AgNavigator.toNamed(AppRoutes.login, arguments: model);\n'
            '    }\n'
            '  }',
          ),
        );
      },
    );

    test(
      're-running the same module leaves every aggregator file byte-identical the second time',
      () async {
        final generator = ModuleGenerator(project: Project(appDir));
        final modulePath = ModulePath.parse('product');

        final firstOps = await generator.plan(modulePath);
        await Executor(dryRun: false, logger: quietLogger).execute(firstOps);
        final coreFiles = [
          'routes/app_routes.dart',
          'routes/app_pages.dart',
          'routes/route_management.dart',
        ];
        final afterFirstRun = {
          for (final f in coreFiles) f: _coreFile(appDir, f),
        };

        final secondOps = await generator.plan(modulePath);
        final aggregatorOps = secondOps.where(
          (op) => op.path.contains('${p.separator}core${p.separator}'),
        );
        expect(
          aggregatorOps,
          everyElement(
            isA<FileOp>().having(
              (op) => op.kind,
              'kind',
              FileOpKind.skipExisting,
            ),
          ),
        );
        await Executor(dryRun: false, logger: quietLogger).execute(secondOps);

        final afterSecondRun = {
          for (final f in coreFiles) f: _coreFile(appDir, f),
        };
        expect(afterSecondRun, afterFirstRun);
      },
    );

    test(
      'a route constant that already exists pointing at a different path is reported as a conflict, and '
      'nothing at all is written',
      () async {
        final appRoutesPath = p.join(
          appDir.path,
          'lib',
          'core',
          'routes',
          'app_routes.dart',
        );
        File(appRoutesPath).writeAsStringSync('''
abstract class AppRoutes {
  static const String initial = _Routes.initial;
  static const String product = _Routes.product;
}

abstract class _Routes {
  static const String initial = '/';
  static const String product = '/something-else-entirely';
}
''');

        final generator = ModuleGenerator(project: Project(appDir));
        await expectLater(
          generator.plan(ModulePath.parse('product')),
          throwsA(
            isA<RouteConflictException>()
                .having((e) => e.routeConstant, 'routeConstant', 'product')
                .having(
                  (e) => e.existingPath,
                  'existingPath',
                  '/something-else-entirely',
                )
                .having((e) => e.newPath, 'newPath', '/product'),
          ),
        );

        expect(
          Directory(
            p.join(appDir.path, 'lib', 'modules', 'product'),
          ).existsSync(),
          isFalse,
        );
        expect(
          File(appRoutesPath).readAsStringSync(),
          isNot(contains('ProductsPage')),
        );
      },
    );

    test(
      'a project that has not run "ag init" (missing aggregator files) reports a clear error',
      () async {
        final freshAppDir = _createSampleApp(seedAggregatorFiles: false);
        addTearDown(() => freshAppDir.deleteSync(recursive: true));

        final generator = ModuleGenerator(project: Project(freshAppDir));
        await expectLater(
          generator.plan(ModulePath.parse('product')),
          throwsA(
            isA<AggregatorFileNotFoundException>().having(
              (e) => e.toString(),
              'message',
              contains('lib/core/routes/app_routes.dart does not exist'),
            ),
          ),
        );
      },
    );
  });

  group('ModuleGenerator — idempotency and parent handling', () {
    test(
      're-running the same module a second time performs no fresh-file writes and changes nothing under it',
      () async {
        final generator = ModuleGenerator(project: Project(appDir));
        final modulePath = ModulePath.parse('product');

        final firstOps = await generator.plan(modulePath);
        await Executor(dryRun: false, logger: quietLogger).execute(firstOps);
        final productDir = Directory(
          p.join(appDir.path, 'lib', 'modules', 'product'),
        );
        final afterFirstRun = {
          for (final f in _listFiles(productDir))
            f: File(p.join(productDir.path, f)).readAsStringSync(),
        };

        final secondOps = await generator.plan(modulePath);
        final freshFileOps = secondOps.where(
          (op) => !op.path.contains('${p.separator}core${p.separator}'),
        );
        expect(
          freshFileOps,
          everyElement(
            isA<FileOp>().having(
              (op) => op.kind,
              'kind',
              FileOpKind.skipExisting,
            ),
          ),
        );
        await Executor(dryRun: false, logger: quietLogger).execute(secondOps);

        final afterSecondRun = {
          for (final f in _listFiles(productDir))
            f: File(p.join(productDir.path, f)).readAsStringSync(),
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

        expect(
          Directory(
            p.join(appDir.path, 'lib', 'modules', 'ticket'),
          ).existsSync(),
          isFalse,
        );
        expect(
          Directory(
            p.join(appDir.path, 'lib', 'modules', 'product'),
          ).existsSync(),
          isFalse,
        );
      },
    );

    test(
      'dry-run reports create/update operations but writes nothing to disk',
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
          Directory(
            p.join(appDir.path, 'lib', 'modules', 'product'),
          ).existsSync(),
          isFalse,
        );
        expect(
          _coreFile(appDir, p.join('routes', 'app_routes.dart')),
          _appRoutesSeed,
        );
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

        final productRoot = Directory(
          p.join(appDir.path, 'lib', 'modules', 'product'),
        );
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
        await Executor(dryRun: false, logger: quietLogger).execute(rootOps);
        final detailOps = await ModuleGenerator(
          project: Project(appDir),
        ).plan(ModulePath.parse('product/details'));

        for (final op in [...rootOps, ...detailOps]) {
          if (op.path.contains('${p.separator}core${p.separator}')) continue;
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

        // Neither run should have been forced to skip a *fresh* file — if
        // the naming scheme collided, the second run's files would already
        // exist (written by the first) and be silently skipped instead.
        final aFreshOps = aOps.where(
          (op) => !op.path.contains('${p.separator}core${p.separator}'),
        );
        final bFreshOps = bOps.where(
          (op) => !op.path.contains('${p.separator}core${p.separator}'),
        );
        expect(
          aFreshOps,
          everyElement(
            isA<FileOp>().having((op) => op.kind, 'kind', FileOpKind.create),
          ),
        );
        expect(
          bFreshOps,
          everyElement(
            isA<FileOp>().having((op) => op.kind, 'kind', FileOpKind.create),
          ),
        );

        final controllersDir = Directory(
          p.join(appDir.path, 'lib', 'modules', 'product', 'controllers'),
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

  group('ModuleGenerator — typed models', () {
    String moduleFile(Directory appDir, String relativePath) => File(
      p.join(appDir.path, 'lib', 'modules', 'product', relativePath),
    ).readAsStringSync();

    ModelSpec productSpec() => ModelSpec.fromJsonSample(
      'Product',
      jsonDecode('{"id": 1, "title": "t", "price": 1.5}'),
    );

    test(
      'generates the model and threads its type through every layer',
      () async {
        final ops = await ModuleGenerator(
          project: Project(appDir),
          model: productSpec(),
        ).plan(ModulePath.parse('product'));
        await Executor(dryRun: false, logger: quietLogger).execute(ops);

        expect(
          File(
            p.join(
              appDir.path,
              'lib',
              'modules',
              'product',
              'models',
              'product.dart',
            ),
          ).existsSync(),
          isTrue,
        );

        expect(
          moduleFile(appDir, p.join('services', 'products_service.dart')),
          allOf(
            contains('AgCrudService<Product, int>'),
            contains('AgPagedService<Product, int>'),
            contains('Product fromJson(Map<String, dynamic> json) =>'),
            contains(
              'Map<String, dynamic> toJson(Product item) => item.toJson()',
            ),
            isNot(contains("UnimplementedError('ProductsService.fromJson')")),
          ),
        );
        expect(
          moduleFile(appDir, p.join('controllers', 'products_controller.dart')),
          allOf(
            contains('AgListController<Product, int>'),
            contains('AgListPage<Product, int>'),
            contains('add(Product item)'),
          ),
        );
        expect(
          moduleFile(appDir, p.join('repos', 'products_repo.dart')),
          contains('AgListPage<Product, int>'),
        );
        expect(
          moduleFile(appDir, p.join('pages', 'products_page.dart')),
          contains('AgListBuilder<Product, int>'),
        );
        expect(
          moduleFile(
            appDir,
            p.join('components', 'product', 'product_item.dart'),
          ),
          contains('final Product item;'),
        );
      },
    );

    test(
      'a detail module converts the String path parameter to the id type',
      () async {
        _touchParentController(appDir, ModulePath.parse('product'));

        final ops = await ModuleGenerator(
          project: Project(appDir),
          model: productSpec(),
        ).plan(ModulePath.parse('product/details'));
        await Executor(dryRun: false, logger: quietLogger).execute(ops);

        expect(
          moduleFile(
            appDir,
            p.join('services', 'product_details_service.dart'),
          ),
          contains(
            'int idOf(ProductDetailsPageArgument argument) => '
            'int.parse(argument.id);',
          ),
          reason:
              'path parameters are always strings, so an int id needs the '
              'parse written for it',
        );
      },
    );

    test('without a model the generated stack is unchanged', () async {
      final ops = await ModuleGenerator(
        project: Project(appDir),
      ).plan(ModulePath.parse('product'));
      await Executor(dryRun: false, logger: quietLogger).execute(ops);

      expect(
        Directory(
          p.join(appDir.path, 'lib', 'modules', 'product', 'models'),
        ).existsSync(),
        isFalse,
        reason: 'no model was asked for, so none is invented',
      );
      expect(
        moduleFile(appDir, p.join('controllers', 'products_controller.dart')),
        contains('AgListController<dynamic, int>'),
      );
    });

    test('an existing model file is never overwritten', () async {
      final modelPath = p.join(
        appDir.path,
        'lib',
        'modules',
        'product',
        'models',
        'product.dart',
      );
      File(modelPath)
        ..createSync(recursive: true)
        ..writeAsStringSync('// hand-edited\n');

      final ops = await ModuleGenerator(
        project: Project(appDir),
        model: productSpec(),
      ).plan(ModulePath.parse('product'));
      await Executor(dryRun: false, logger: quietLogger).execute(ops);

      expect(File(modelPath).readAsStringSync(), '// hand-edited\n');
    });
  });
}
