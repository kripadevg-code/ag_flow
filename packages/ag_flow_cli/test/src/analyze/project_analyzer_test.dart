import 'dart:io';

import 'package:ag_flow_cli/src/analyze/analyze_issue.dart';
import 'package:ag_flow_cli/src/analyze/project_analyzer.dart';
import 'package:ag_flow_cli/src/generators/init_generator.dart';
import 'package:ag_flow_cli/src/generators/module_generator.dart';
import 'package:ag_flow_cli/src/io/executor.dart';
import 'package:ag_flow_cli/src/io/project.dart';
import 'package:ag_flow_cli/src/naming/module_path.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

final _quietLogger = Logger(level: Level.quiet);

/// Builds a real, freshly-generated project — `ag init` + `ag g m product`
/// (and, if [includeDetail], `ag g m product/details`) — via the actual
/// generators, not a hand-typed fixture. Every per-rule test below starts
/// from this known-clean baseline and mutates exactly one thing, so a
/// passing "zero issues" baseline test is what proves each mutation below
/// is really isolating a single rule.
Future<Directory> _buildCleanProject({bool includeDetail = false}) async {
  final dir = Directory.systemTemp.createTempSync('ag_analyze_test_');
  File(
    p.join(dir.path, 'pubspec.yaml'),
  ).writeAsStringSync('name: sample_app\n');

  final project = Project(dir);
  await Executor(
    dryRun: false,
    logger: _quietLogger,
  ).execute(InitGenerator(project: project).plan());

  final generator = ModuleGenerator(project: project);
  await Executor(
    dryRun: false,
    logger: _quietLogger,
  ).execute(await generator.plan(ModulePath.parse('product')));

  if (includeDetail) {
    await Executor(
      dryRun: false,
      logger: _quietLogger,
    ).execute(await generator.plan(ModulePath.parse('product/details')));
  }

  return dir;
}

Future<List<AnalyzeIssue>> _analyze(Directory dir) =>
    ProjectAnalyzer(project: Project(dir)).analyze();

void main() {
  late Directory appDir;
  tearDown(() => appDir.deleteSync(recursive: true));

  test(
    'a freshly generated root-only project has zero issues',
    () async {
      appDir = await _buildCleanProject();
      expect(await _analyze(appDir), isEmpty);
    },
  );

  test(
    'a freshly generated project with a detail module has zero issues',
    () async {
      appDir = await _buildCleanProject(includeDetail: true);
      expect(await _analyze(appDir), isEmpty);
    },
  );

  test(
    'flags a missing architectural layer file',
    () async {
      appDir = await _buildCleanProject();
      File(
        p.join(
          appDir.path,
          'lib',
          'modules',
          'product',
          'repos',
          'products_repo.dart',
        ),
      ).deleteSync();

      final issues = await _analyze(appDir);
      expect(issues, hasLength(1));
      expect(issues.single.category, AnalyzeCategory.missingLayerFile);
      expect(issues.single.message, contains('products_repo.dart'));
    },
  );

  test(
    'flags a route with no AgRoute entry',
    () async {
      appDir = await _buildCleanProject();
      final appPagesFile = File(
        p.join(appDir.path, 'lib', 'core', 'routes', 'app_pages.dart'),
      );
      appPagesFile.writeAsStringSync(
        appPagesFile.readAsStringSync().replaceFirst(
          RegExp(r'AgRoute\(.*?\),', dotAll: true),
          '',
        ),
      );

      final issues = await _analyze(appDir);
      expect(issues, hasLength(1));
      expect(issues.single.category, AnalyzeCategory.missingRouteWiring);
      expect(issues.single.message, contains('AgRoute'));
    },
  );

  test(
    'flags a route with no navigation method',
    () async {
      appDir = await _buildCleanProject();
      final routeManagementFile = File(
        p.join(appDir.path, 'lib', 'core', 'routes', 'route_management.dart'),
      );
      routeManagementFile.writeAsStringSync(
        routeManagementFile.readAsStringSync().replaceFirst(
          RegExp(r'static void goToProductsPage\(\) \{.*?\}', dotAll: true),
          '',
        ),
      );

      final issues = await _analyze(appDir);
      expect(issues, hasLength(1));
      expect(issues.single.category, AnalyzeCategory.missingRouteWiring);
      expect(issues.single.message, contains('goToProductsPage'));
    },
  );

  test(
    'flags a detail route missing its argument class',
    () async {
      appDir = await _buildCleanProject(includeDetail: true);
      final argumentsFile = File(
        p.join(appDir.path, 'lib', 'core', 'arguments', 'arguments.dart'),
      );
      argumentsFile.writeAsStringSync(
        argumentsFile.readAsStringSync().replaceFirst(
          RegExp(
            r'class ProductDetailsPageArgument \{.*?\}',
            dotAll: true,
          ),
          '',
        ),
      );

      final issues = await _analyze(appDir);
      expect(issues, hasLength(1));
      expect(issues.single.category, AnalyzeCategory.missingRouteWiring);
      expect(issues.single.message, contains('ProductDetailsPageArgument'));
    },
  );

  test(
    'flags two route constants pointing at the identical path',
    () async {
      appDir = await _buildCleanProject();
      final appRoutesFile = File(
        p.join(appDir.path, 'lib', 'core', 'routes', 'app_routes.dart'),
      );
      appRoutesFile.writeAsStringSync(
        appRoutesFile
            .readAsStringSync()
            .replaceFirst(
              'abstract class AppRoutes {',
              'abstract class AppRoutes {\n'
                  '  static const String productAlias = _Routes.productAlias;',
            )
            .replaceFirst(
              'abstract class _Routes {',
              'abstract class _Routes {\n'
                  "  static const String productAlias = '/product';",
            ),
      );
      // Give the alias its own AgRoute entry too, so the *only* remaining
      // issue is the duplicate-path one this test targets — otherwise the
      // route-wiring check (correctly) also flags the alias as missing an
      // AgRoute of its own, since that check keys off the route's own
      // name, not the module path it happens to share with "product".
      final appPagesFile = File(
        p.join(appDir.path, 'lib', 'core', 'routes', 'app_pages.dart'),
      );
      appPagesFile.writeAsStringSync(
        appPagesFile.readAsStringSync().replaceFirst(
          'pages = [',
          'pages = [\n'
              '    AgRoute(\n'
              '      path: AppRoutes.productAlias,\n'
              '      page: ProductsPage.new,\n'
              '      binding: ProductsBinding(),\n'
              '      transition: AppPages.defaultTransition,\n'
              '    ),',
        ),
      );

      final issues = await _analyze(appDir);
      expect(issues, hasLength(1));
      expect(issues.single.category, AnalyzeCategory.duplicateRoute);
      expect(issues.single.message, contains('product'));
      expect(issues.single.message, contains('productAlias'));
    },
  );

  test(
    'flags a nested subfolder under an architectural layer',
    () async {
      appDir = await _buildCleanProject();
      File(
        p.join(
          appDir.path,
          'lib',
          'modules',
          'product',
          'controllers',
          'nested',
          'stray.dart',
        ),
      ).createSync(recursive: true);

      final issues = await _analyze(appDir);
      expect(issues, hasLength(1));
      expect(issues.single.category, AnalyzeCategory.nestedFolder);
      expect(issues.single.message, contains('controllers'));
    },
  );

  test(
    'flags a nested subfolder under a component namespace',
    () async {
      appDir = await _buildCleanProject();
      File(
        p.join(
          appDir.path,
          'lib',
          'modules',
          'product',
          'components',
          'product',
          'nested',
          'stray.dart',
        ),
      ).createSync(recursive: true);

      final issues = await _analyze(appDir);
      expect(issues, hasLength(1));
      expect(issues.single.category, AnalyzeCategory.nestedFolder);
      expect(issues.single.message, contains('components/product'));
    },
  );

  test(
    'flags a hard-coded route string outside route_management.dart',
    () async {
      appDir = await _buildCleanProject();
      File(
        p.join(
          appDir.path,
          'lib',
          'modules',
          'product',
          'pages',
          'rogue_page.dart',
        ),
      ).writeAsStringSync('''
class RogueNavigator {
  void go() {
    AgNavigator.toNamed('/product');
  }
}
''');

      final issues = await _analyze(appDir);
      expect(issues, hasLength(1));
      expect(issues.single.category, AnalyzeCategory.hardcodedRoute);
      expect(issues.single.message, contains('/product'));
    },
  );

  test(
    'never flags a literal-looking AgNavigator.toNamed(AppRoutes.x) call — only a '
    'raw string literal argument counts',
    () async {
      appDir = await _buildCleanProject();
      final issues = await _analyze(appDir);
      expect(
        issues.where((i) => i.category == AnalyzeCategory.hardcodedRoute),
        isEmpty,
      );
    },
  );

  test(
    'does NOT flag a Page calling a Service directly when dependencies '
    "haven't been resolved — the resolved-model checks need "
    '.dart_tool/package_config.json and are skipped without it, on a '
    'plain bare-pubspec fixture like every other test in this file',
    () async {
      appDir = await _buildCleanProject();
      final pageFile = File(
        p.join(
          appDir.path,
          'lib',
          'modules',
          'product',
          'pages',
          'products_page.dart',
        ),
      );
      pageFile.writeAsStringSync(
        '${pageFile.readAsStringSync()}\n'
        'class _DirectServiceCall {\n'
        '  void run() {\n'
        '    ProductsService(apiProvider: throw UnimplementedError());\n'
        '  }\n'
        '}\n',
      );

      expect(
        await ProjectAnalyzer(project: Project(appDir)).dependenciesResolved,
        isFalse,
      );
      expect(await _analyze(appDir), isEmpty);
    },
  );

  test(
    'throws ProjectNotInitializedException on an un-init-ed project',
    () async {
      appDir = Directory.systemTemp.createTempSync('ag_analyze_test_');
      File(
        p.join(appDir.path, 'pubspec.yaml'),
      ).writeAsStringSync('name: sample_app\n');

      await expectLater(
        () => _analyze(appDir),
        throwsA(isA<ProjectNotInitializedException>()),
      );
    },
  );
}
