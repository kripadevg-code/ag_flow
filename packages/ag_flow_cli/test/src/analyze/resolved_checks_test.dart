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

/// Returns the absolute path to `packages/ag_flow` — resolved by searching
/// upward from [Directory.current] for the workspace root that contains
/// both `packages/ag_flow_cli` and `packages/ag_flow`, so it works
/// regardless of the working directory (workspace root in CI or Melos,
/// package root when run directly via `dart test`).
String _agFlowPackagePath() {
  var dir = Directory.current;
  while (true) {
    final candidate = Directory(p.join(dir.path, 'packages', 'ag_flow'));
    if (candidate.existsSync()) return candidate.path;
    final parent = dir.parent;
    if (parent.path == dir.path) break;
    dir = parent;
  }
  // Fallback: one level up from the package root (works when CWD is the
  // ag_flow_cli package directory).
  return p.join(Directory.current.parent.path, 'ag_flow');
}

/// The two resolved-model checks ([AnalyzeCategory.dependencyDirection],
/// [AnalyzeCategory.unusedDetailArgument]) need `ag_flow`'s own types to
/// actually resolve — unlike every other check in `project_analyzer_test
/// .dart`, a bare-pubspec fixture with no dependencies isn't enough here.
///
/// Building that once via a real `dart pub get` against the real
/// `ag_flow` package (as a path dependency) and copying the whole
/// directory — `.dart_tool/package_config.json` included — for each test
/// avoids re-resolving dependencies per test case, since every entry in
/// that file is an absolute `file://` URI and stays valid regardless of
/// where the directory is copied to.
late Directory _baseProjectDir;

Future<void> _copyRecursive(Directory from, Directory to) async {
  to.createSync(recursive: true);
  await for (final entity in from.list()) {
    final name = p.basename(entity.path);
    final destPath = p.join(to.path, name);
    if (entity is Directory) {
      await _copyRecursive(entity, Directory(destPath));
    } else if (entity is File) {
      await entity.copy(destPath);
    }
  }
}

Future<Directory> _freshResolvedProject() async {
  final dir = Directory.systemTemp.createTempSync('ag_analyze_resolved_test_');
  await _copyRecursive(_baseProjectDir, dir);
  return dir;
}

Future<List<AnalyzeIssue>> _analyze(Directory dir) =>
    ProjectAnalyzer(project: Project(dir)).analyze();

void main() {
  setUpAll(() async {
    _baseProjectDir = Directory.systemTemp.createTempSync(
      'ag_analyze_resolved_base_',
    );
    File(
      p.join(_baseProjectDir.path, 'pubspec.yaml'),
    ).writeAsStringSync('''
name: sample_app
environment:
  sdk: ^3.11.0
dependencies:
  ag_flow:
    path: ${_agFlowPackagePath()}
''');

    final project = Project(_baseProjectDir);
    await Executor(
      dryRun: false,
      logger: _quietLogger,
    ).execute(InitGenerator(project: project).plan());

    final generator = ModuleGenerator(project: project);
    await Executor(
      dryRun: false,
      logger: _quietLogger,
    ).execute(await generator.plan(ModulePath.parse('product')));
    await Executor(
      dryRun: false,
      logger: _quietLogger,
    ).execute(await generator.plan(ModulePath.parse('product/details')));

    final pubGet = await Process.run('dart', [
      'pub',
      'get',
    ], workingDirectory: _baseProjectDir.path);
    if (pubGet.exitCode != 0) {
      throw StateError(
        'dart pub get failed in the shared resolved-checks fixture:\n'
        '${pubGet.stdout}\n${pubGet.stderr}',
      );
    }
  });

  tearDownAll(() => _baseProjectDir.deleteSync(recursive: true));

  late Directory appDir;
  tearDown(() => appDir.deleteSync(recursive: true));

  test(
    'a freshly generated, pub-get-resolved project has zero issues',
    () async {
      appDir = await _freshResolvedProject();
      expect(
        await ProjectAnalyzer(project: Project(appDir)).dependenciesResolved,
        isTrue,
      );
      expect(await _analyze(appDir), isEmpty);
    },
  );

  test(
    'flags a Page directly instantiating a Service',
    () async {
      appDir = await _freshResolvedProject();
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
        "import 'package:sample_app/modules/product/services/products_service.dart';\n"
        '${pageFile.readAsStringSync()}\n'
        'class _Rogue {\n'
        '  void run() {\n'
        '    ProductsService(throw UnimplementedError());\n'
        '  }\n'
        '}\n',
      );

      final issues = await _analyze(appDir);
      final violations = issues
          .where((i) => i.category == AnalyzeCategory.dependencyDirection)
          .toList();
      expect(violations, hasLength(1));
      expect(violations.single.message, contains('AgBaseService'));
      expect(violations.single.file, contains('products_page.dart'));
    },
  );

  test(
    'flags a Page directly referencing a Repo type',
    () async {
      appDir = await _freshResolvedProject();
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
        "import 'package:sample_app/modules/product/repos/products_repo.dart';\n"
        '${pageFile.readAsStringSync()}\n'
        'class _Rogue {\n'
        '  ProductsRepo? repo;\n'
        '}\n',
      );

      final issues = await _analyze(appDir);
      final violations = issues
          .where((i) => i.category == AnalyzeCategory.dependencyDirection)
          .toList();
      expect(violations, hasLength(1));
      expect(violations.single.message, contains('AgBaseRepo'));
    },
  );

  test(
    'flags a Controller directly referencing ApiProvider',
    () async {
      appDir = await _freshResolvedProject();
      final controllerFile = File(
        p.join(
          appDir.path,
          'lib',
          'modules',
          'product',
          'controllers',
          'products_controller.dart',
        ),
      );
      controllerFile.writeAsStringSync(
        '${controllerFile.readAsStringSync()}\n'
        'class _Rogue {\n'
        '  ApiProvider? provider;\n'
        '}\n',
      );

      final issues = await _analyze(appDir);
      final violations = issues
          .where((i) => i.category == AnalyzeCategory.dependencyDirection)
          .toList();
      expect(violations, hasLength(1));
      expect(violations.single.message, contains('ApiProvider'));
      expect(violations.single.file, contains('products_controller.dart'));
    },
  );

  test(
    'flags a Repo directly referencing ApiProvider',
    () async {
      appDir = await _freshResolvedProject();
      final repoFile = File(
        p.join(
          appDir.path,
          'lib',
          'modules',
          'product',
          'repos',
          'products_repo.dart',
        ),
      );
      repoFile.writeAsStringSync(
        '${repoFile.readAsStringSync()}\n'
        'class _Rogue {\n'
        '  ApiProvider? provider;\n'
        '}\n',
      );

      final issues = await _analyze(appDir);
      final violations = issues
          .where((i) => i.category == AnalyzeCategory.dependencyDirection)
          .toList();
      expect(violations, hasLength(1));
      expect(violations.single.message, contains('ApiProvider'));
      expect(violations.single.file, contains('products_repo.dart'));
    },
  );

  test(
    'never flags the framework base classes themselves referencing each '
    "other — only a project's own layer files are scanned",
    () async {
      appDir = await _freshResolvedProject();
      final issues = await _analyze(appDir);
      expect(
        issues.where((i) => i.category == AnalyzeCategory.dependencyDirection),
        isEmpty,
      );
    },
  );

  test(
    'flags a detail controller that never uses its inherited arguments',
    () async {
      appDir = await _freshResolvedProject();
      // Replaces the whole file (rather than patching fetch() in place)
      // because the default-generated controller also has update()/
      // delete() methods that legitimately reference arguments — a
      // partial patch leaving those in place would no longer produce a
      // genuinely zero-usage class, and the "unused" issue wouldn't fire.
      File(
        p.join(
          appDir.path,
          'lib',
          'modules',
          'product',
          'controllers',
          'product_details_controller.dart',
        ),
      ).writeAsStringSync('''
import 'package:ag_flow/ag_flow.dart';
import 'package:sample_app/core/arguments/arguments.dart';
import 'package:sample_app/modules/product/repos/product_details_repo.dart';

class ProductDetailsController
    extends AgDetailController<dynamic, ProductDetailsPageArgument> {
  ProductDetailsController(this._repo);

  final ProductDetailsRepo _repo;

  @override
  Future<dynamic> fetch() async => 'stub';
}
''');

      final issues = await _analyze(appDir);
      final violations = issues
          .where((i) => i.category == AnalyzeCategory.unusedDetailArgument)
          .toList();
      expect(violations, hasLength(1));
      expect(
        violations.single.message,
        contains('ProductDetailsController'),
      );
      expect(
        violations.single.file,
        contains('product_details_controller.dart'),
      );
    },
  );

  test(
    'does NOT flag the freshly generated detail controller — it already '
    'reads "arguments" via _repo.getByArgument(arguments)',
    () async {
      appDir = await _freshResolvedProject();
      final issues = await _analyze(appDir);
      expect(
        issues.where(
          (i) => i.category == AnalyzeCategory.unusedDetailArgument,
        ),
        isEmpty,
      );
    },
  );
}
