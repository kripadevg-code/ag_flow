import 'package:ag_flow/ag_flow.dart';
import 'package:ag_flow/testing.dart';
{{#has_model}}import 'package:{{app_package_name}}/{{{module_import_path}}}/models/{{model_file_base}}.dart';
{{/has_model}}import 'package:{{app_package_name}}/{{{module_import_path}}}/controllers/{{module_file_base}}_controller.dart';
import 'package:{{app_package_name}}/{{{module_import_path}}}/repos/{{module_file_base}}_repo.dart';
import 'package:{{app_package_name}}/{{{module_import_path}}}/services/{{module_file_base}}_service.dart';
import 'package:flutter_test/flutter_test.dart';

/// A Service that returns [items] or throws [error], so the Repo and the
/// Controller are tested without a network or real endpoints. Once the
/// Service points at real endpoints, test it against an
/// [AgFakeApiProvider] too.
class _FakeService extends {{module_class_prefix}}Service {
  _FakeService() : super(AgFakeApiProvider());

  List<{{model_class}}> items = [];
  Exception? error;

  @override
  Future<List<{{model_class}}>> list({{#paginate}}{int page = 1}{{/paginate}}) async {
    if (error case final error?) throw error;
    return items;
  }
}

const _offline = AgApiException(message: 'offline', type: AgApiErrorType.connection);

void main() {
  late _FakeService service;

  setUp(() {
    service = _FakeService();
  });

  group('{{module_class_prefix}}Repo', () {
    test('list returns what the Service returns', () async {
      expect(await {{module_class_prefix}}Repo(service).list(), service.items);
    });

    test('a network error reaches the Controller as AgRepoErrorKind.network', () {
      service.error = _offline;
      expect(
        {{module_class_prefix}}Repo(service).list(),
        throwsA(
          isA<AgRepoException>().having((e) => e.kind, 'kind', AgRepoErrorKind.network),
        ),
      );
    });
  });

  group('{{module_class_prefix}}Controller', () {
    late {{module_class_prefix}}Controller controller;

    setUp(() {
      controller = {{module_class_prefix}}Controller({{module_class_prefix}}Repo(service));
      addTearDown(controller.dispose);
    });

    test('shows the empty state when there are no items', () async {
      await controller.loadInitial();
      expect(controller.state, isA<AgPageEmpty<List<{{model_class}}>>>());
    });

    test('shows the error state when loading fails', () async {
      service.error = _offline;
      await controller.loadInitial();
      expect(controller.state, isA<AgPageError<List<{{model_class}}>>>());
    });
  });
}
