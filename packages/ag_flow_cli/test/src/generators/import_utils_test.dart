import 'package:ag_flow_cli/src/generators/import_utils.dart';
import 'package:test/test.dart';

void main() {
  group('sortImports', () {
    test(
      'groups dart:/package:/relative imports, not a flat alphabetical sort',
      () {
        // A flat alphabetical sort would put 'app_routes.dart' (starts with
        // "a") before any package: import (starts with "p") — this is the
        // exact regression this test guards: grouping must win over plain
        // per-line alphabetical order.
        const input = '''
import 'app_routes.dart';

import 'package:ag_flow/ag_flow.dart';
import 'package:sample_app/product/bindings/products_binding.dart';
import 'package:sample_app/product/pages/products_page.dart';

abstract class AppPages {}
''';

        const expected = '''
import 'package:ag_flow/ag_flow.dart';
import 'package:sample_app/product/bindings/products_binding.dart';
import 'package:sample_app/product/pages/products_page.dart';

import 'app_routes.dart';

abstract class AppPages {}
''';

        expect(sortImports(input), expected);
      },
    );

    test(
      'dart: imports sort before package: imports, which sort before relative imports',
      () {
        const input = '''
import 'app_routes.dart';
import 'package:sample_app/product/pages/products_page.dart';
import 'dart:async';

abstract class AppPages {}
''';

        final result = sortImports(input);
        final dartIndex = result.indexOf("import 'dart:async'");
        final packageIndex = result.indexOf("import 'package:sample_app");
        final relativeIndex = result.indexOf("import 'app_routes.dart'");

        expect(dartIndex, lessThan(packageIndex));
        expect(packageIndex, lessThan(relativeIndex));
      },
    );

    test('is a no-op when there are no imports', () {
      const input = 'abstract class Foo {}\n';
      expect(sortImports(input), input);
    });

    test('is idempotent — sorting already-sorted imports changes nothing', () {
      const input = '''
import 'package:ag_flow/ag_flow.dart';

import 'app_routes.dart';

abstract class AppPages {}
''';
      expect(sortImports(sortImports(input)), sortImports(input));
    });

    test('preserves content before the first import and after the last', () {
      const input = '''
// A leading file comment.
import 'package:z_package/z.dart';
import 'package:a_package/a.dart';

class Foo {}
''';
      final result = sortImports(input);
      expect(result, startsWith('// A leading file comment.\n'));
      expect(result, endsWith('\n\nclass Foo {}\n'));
      expect(
        result.indexOf('a_package'),
        lessThan(result.indexOf('z_package')),
      );
    });
  });
}
