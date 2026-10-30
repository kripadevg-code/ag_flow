import 'package:ag_flow/ag_flow.dart';
import 'package:ag_flow/testing.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sample_app/modules/product/controllers/products_controller.dart';
import 'package:sample_app/modules/product/repos/products_repo.dart';
import 'package:sample_app/modules/product/services/products_service.dart';

/// A Service that returns [items] or throws [error], so the Repo and the
/// Controller are tested without a network or real endpoints. Once the
/// Service points at real endpoints, test it against an
/// [AgFakeApiProvider] too.
class _FakeService extends ProductsService {
  _FakeService() : super(AgFakeApiProvider());

  List<dynamic> items = [];
  Exception? error;

  @override
  Future<List<dynamic>> list() async {
    if (error case final error?) throw error;
    return items;
  }
}

const _offline = AgApiException(
  message: 'offline',
  type: AgApiErrorType.connection,
);

void main() {
  late _FakeService service;

  setUp(() {
    service = _FakeService();
  });

  group('ProductsRepo', () {
    test('list returns what the Service returns', () async {
      expect(await ProductsRepo(service).list(), service.items);
    });

    test(
      'a network error reaches the Controller as AgRepoErrorKind.network',
      () {
        service.error = _offline;
        expect(
          ProductsRepo(service).list(),
          throwsA(
            isA<AgRepoException>().having(
              (e) => e.kind,
              'kind',
              AgRepoErrorKind.network,
            ),
          ),
        );
      },
    );
  });

  group('ProductsController', () {
    late ProductsController controller;

    setUp(() {
      controller = ProductsController(ProductsRepo(service));
      addTearDown(controller.dispose);
    });

    test('shows the empty state when there are no items', () async {
      await controller.loadInitial();
      expect(controller.state, isA<AgPageEmpty<List<dynamic>>>());
    });

    test('shows the error state when loading fails', () async {
      service.error = _offline;
      await controller.loadInitial();
      expect(controller.state, isA<AgPageError<List<dynamic>>>());
    });
  });
}
