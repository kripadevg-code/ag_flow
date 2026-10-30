import 'package:ag_flow/ag_flow.dart';
import 'package:ag_flow/testing.dart';
{{#has_model}}import 'package:{{app_package_name}}/{{{module_import_path}}}/models/{{model_file_base}}.dart';
{{/has_model}}import 'package:{{app_package_name}}/{{{module_import_path}}}/controllers/{{module_file_base}}_controller.dart';
import 'package:{{app_package_name}}/{{{module_import_path}}}/repos/{{module_file_base}}_repo.dart';
import 'package:{{app_package_name}}/{{{module_import_path}}}/services/{{module_file_base}}_service.dart';
import 'package:flutter_test/flutter_test.dart';

/// A Service that records each lookup and then fails, so the Repo and the
/// Controller are tested without a network or real endpoints. Once the
/// Service points at real endpoints, test it against an
/// [AgFakeApiProvider] too.
class _FakeService extends {{module_class_prefix}}Service {
  _FakeService() : super(AgFakeApiProvider());

  final List<{{id_type}}> lookups = [];

  @override
  Future<{{model_class}}> retrieve({{id_type}} id) async {
    lookups.add(id);
    throw const AgApiException(message: 'offline', type: AgApiErrorType.connection);
  }
}

void main() {
  late _FakeService service;
  late {{module_class_prefix}}Controller controller;

  setUp(() {
    resetAgFlow();
    // What the route's `/:id` holds when this page opens.
    AgRouteData.pathParameters = {'id': '1'};
    service = _FakeService();
    controller = {{module_class_prefix}}Controller({{module_class_prefix}}Repo(service));
    addTearDown(controller.dispose);
  });

  test('the Controller looks up the id from the route', () async {
    await controller.loadInitial();
    expect(service.lookups, [controller.lookupId]);
  });

  test('a network error reaches the Controller as AgRepoErrorKind.network', () async {
    await controller.loadInitial();
    expect(
      controller.state,
      isA<AgPageError<{{model_class}}>>().having(
        (s) => s.error,
        'error',
        isA<AgRepoException>().having((e) => e.kind, 'kind', AgRepoErrorKind.network),
      ),
    );
  });
}
