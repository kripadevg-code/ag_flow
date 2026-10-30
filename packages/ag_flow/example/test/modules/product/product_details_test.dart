import 'package:ag_flow/ag_flow.dart';
import 'package:ag_flow/testing.dart';
import 'package:ag_flow_example/modules/product/controllers/product_details_controller.dart';
import 'package:ag_flow_example/modules/product/repos/product_details_repo.dart';
import 'package:ag_flow_example/modules/product/services/product_details_service.dart';
import 'package:flutter_test/flutter_test.dart';

/// A Service that records each lookup and then fails, so the Repo and the
/// Controller are tested without a network or real endpoints. Once the
/// Service points at real endpoints, test it against an
/// [AgFakeApiProvider] too.
class _FakeService extends ProductDetailsService {
  _FakeService() : super(AgFakeApiProvider());

  final List<Object> lookups = [];

  @override
  Future<dynamic> retrieve(Object id) async {
    lookups.add(id);
    throw const AgApiException(
      message: 'offline',
      type: AgApiErrorType.connection,
    );
  }
}

void main() {
  late _FakeService service;
  late ProductDetailsController controller;

  setUp(() {
    resetAgFlow();
    // What the route's `/:id` holds when this page opens.
    AgRouteData.pathParameters = {'id': '1'};
    service = _FakeService();
    controller = ProductDetailsController(ProductDetailsRepo(service));
    addTearDown(controller.dispose);
  });

  test('the Controller looks up the id from the route', () async {
    await controller.loadInitial();
    expect(service.lookups, [controller.lookupId]);
  });

  test(
    'a network error reaches the Controller as AgRepoErrorKind.network',
    () async {
      await controller.loadInitial();
      expect(
        controller.state,
        isA<AgPageError<dynamic>>().having(
          (s) => s.error,
          'error',
          isA<AgRepoException>().having(
            (e) => e.kind,
            'kind',
            AgRepoErrorKind.network,
          ),
        ),
      );
    },
  );
}
