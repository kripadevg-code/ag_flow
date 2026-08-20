import 'package:ag_flow/ag_flow.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AgRequest / AgEndpoint isolation (ag_endpoint_rules.md §29-30)', () {
    test(
      'two concurrent requests sharing one endpoint resolve independently',
      () async {
        const endpoint = AgEndpoint('/products/{id}');

        Future<String> resolveLater(Object id) {
          // Simulate two in-flight requests racing against each other.
          return Future<void>.delayed(const Duration(milliseconds: 1)).then(
            (_) => AgRequest(
              endpoint: endpoint,
              pathParams: {'id': id},
            ).resolvePath(),
          );
        }

        final results = await Future.wait([
          resolveLater(123),
          resolveLater(456),
        ]);

        expect(results, ['/products/123', '/products/456']);
      },
    );

    test('resolving a request never mutates the shared endpoint template', () {
      const endpoint = AgEndpoint('/products/{id}');

      AgRequest(endpoint: endpoint, pathParams: {'id': 123}).resolvePath();
      AgRequest(endpoint: endpoint, pathParams: {'id': 456}).resolvePath();

      expect(endpoint.path, '/products/{id}');
    });

    test(
      'the same AgEndpoint instance is safely reused by unrelated requests',
      () {
        const endpoint = AgEndpoint(
          '/products/{id}',
          methods: {AgHttpMethod.get, AgHttpMethod.delete},
        );

        final getRequest = AgRequest(endpoint: endpoint, pathParams: {'id': 1});
        final deleteRequest = AgRequest(
          endpoint: endpoint,
          method: AgHttpMethod.delete,
          pathParams: {'id': 1},
        );

        expect(getRequest.method, AgHttpMethod.get);
        expect(deleteRequest.method, AgHttpMethod.delete);
        expect(identical(getRequest.endpoint, deleteRequest.endpoint), isTrue);
      },
    );

    test(
      'an unsupported method for the endpoint fails fast with a real '
      'exception, not an assert stripped from release builds',
      () {
        const endpoint = AgEndpoint('/products');
        expect(
          () => AgRequest(endpoint: endpoint, method: AgHttpMethod.delete),
          throwsA(isA<AgUnsupportedMethodException>()),
        );
      },
    );

    test(
      'a body and form-data together fail fast with a real exception',
      () {
        const endpoint = AgEndpoint('/products', methods: {AgHttpMethod.post});
        expect(
          () => AgRequest(
            endpoint: endpoint,
            body: {'a': 1},
            formFields: {'b': '2'},
          ),
          throwsArgumentError,
        );
      },
    );
  });
}
