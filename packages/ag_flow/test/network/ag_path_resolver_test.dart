import 'package:ag_flow/ag_flow.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AgPathResolver.resolve', () {
    test('substitutes a single path parameter', () {
      final resolved = AgPathResolver.resolve('/products/{id}', {'id': 123});
      expect(resolved, '/products/123');
    });

    test('substitutes multiple path parameters', () {
      final resolved = AgPathResolver.resolve(
        '/products/{productId}/reviews/{reviewId}',
        {'productId': 100, 'reviewId': 25},
      );
      expect(resolved, '/products/100/reviews/25');
    });

    test('URL-encodes parameter values', () {
      final resolved = AgPathResolver.resolve('/search/{query}', {
        'query': 'a b/c',
      });
      expect(resolved, '/search/${Uri.encodeComponent('a b/c')}');
    });

    test(
      'throws AgMissingPathParameterException with the exact spec-mandated message '
      'when a required parameter is missing',
      () {
        expect(
          () => AgPathResolver.resolve('/products/{id}', const {}),
          throwsA(
            isA<AgMissingPathParameterException>().having(
              (e) => e.toString(),
              'message',
              'Missing required path parameter: id\nEndpoint: /products/{id}',
            ),
          ),
        );
      },
    );

    test('throws when a parameter is present but null', () {
      expect(
        () => AgPathResolver.resolve('/products/{id}', {'id': null}),
        throwsA(isA<AgMissingPathParameterException>()),
      );
    });

    test(
      'reports every missing parameter, in template order, for multiple gaps',
      () {
        expect(
          () => AgPathResolver.resolve(
            '/products/{productId}/reviews/{reviewId}',
            const {},
          ),
          throwsA(
            isA<AgMissingPathParameterException>().having(
              (e) => e.parameterNames,
              'parameterNames',
              ['productId', 'reviewId'],
            ),
          ),
        );
      },
    );

    test(
      'does not resolve a partially-missing template — no unresolved {token} ever leaks out',
      () {
        expect(
          () => AgPathResolver.resolve(
            '/products/{productId}/reviews/{reviewId}',
            {'productId': 1},
          ),
          throwsA(isA<AgMissingPathParameterException>()),
        );
      },
    );
  });

  group('AgRequest.resolvePath', () {
    test('resolves through the endpoint it was built from', () {
      const endpoint = AgEndpoint('/products/{id}');
      final request = AgRequest(endpoint: endpoint, pathParams: {'id': 42});
      expect(request.resolvePath(), '/products/42');
    });

    test(
      'throws before any request would be dispatched — resolvePath() is a pure, '
      'side-effect-free call site evaluated ahead of ApiProvider.send()',
      () {
        const endpoint = AgEndpoint('/products/{id}');
        final request = AgRequest(endpoint: endpoint);
        expect(
          request.resolvePath,
          throwsA(isA<AgMissingPathParameterException>()),
        );
      },
    );
  });
}
