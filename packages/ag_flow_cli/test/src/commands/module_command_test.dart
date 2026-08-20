import 'dart:io';

import 'package:ag_flow_cli/src/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

/// Exercises `--plural=` through the real command layer — `args`
/// parsing, `Directory.current`, everything — not just the
/// `ModuleGenerator`/`ModuleSpec` API directly. A prior version of this
/// flag's wiring passed the raw CLI argument straight through as the
/// pluralized class prefix, producing "companiesController" instead of
/// "CompaniesController"; that bug was invisible to any test that only
/// called `ModuleGenerator` with a custom `Pluralizer` function already
/// returning correctly-cased output.
///
/// `ModuleCommand.run()` reads the ambient `Directory.current`, so
/// exercising it for real means overriding that — but only the plain
/// setter (`Directory.current = ...`) mutates the real OS-level process
/// working directory, which every concurrently-running test *file* in
/// the same `dart test` run shares (confirmed the hard way: doing that
/// here made an unrelated golden-file test in a different file
/// intermittently fail, because it resolves its fixture path relative to
/// `Directory.current` too). `IOOverrides.runZoned`'s `getCurrentDirectory`
/// callback is zone-scoped instead — it only affects `Directory.current`
/// reads within this call chain, never the real process CWD or any other
/// test file's zone.
void main() {
  late Directory appDir;

  setUp(() {
    appDir = Directory.systemTemp.createTempSync('ag_module_command_test_');
    File(
      p.join(appDir.path, 'pubspec.yaml'),
    ).writeAsStringSync('name: sample_app\n');
  });

  tearDown(() => appDir.deleteSync(recursive: true));

  Future<int?> run(List<String> args) {
    return IOOverrides.runZoned(
      () => AgCommandRunner(logger: Logger(level: Level.quiet)).run(args),
      getCurrentDirectory: () => appDir,
    );
  }

  test(
    '--plural= overrides the default pluralizer with correct PascalCase, '
    'through the real CommandRunner argv path',
    () async {
      expect(await run(['init']), 0);
      expect(await run(['g', 'm', 'company', '--plural=companies']), 0);

      final controllerFile = File(
        p.join(
          appDir.path,
          'lib',
          'company',
          'controllers',
          'companies_controller.dart',
        ),
      );
      expect(controllerFile.existsSync(), isTrue);
      expect(
        controllerFile.readAsStringSync(),
        contains('class CompaniesController'),
      );
    },
  );

  test('without --plural=, the default pluralizer is used as before', () async {
    expect(await run(['init']), 0);
    expect(await run(['g', 'm', 'product']), 0);

    final controllerFile = File(
      p.join(
        appDir.path,
        'lib',
        'product',
        'controllers',
        'products_controller.dart',
      ),
    );
    expect(controllerFile.existsSync(), isTrue);
    expect(
      controllerFile.readAsStringSync(),
      contains('class ProductsController'),
    );
  });
}
