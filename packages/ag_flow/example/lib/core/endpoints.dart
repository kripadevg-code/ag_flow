import 'package:ag_flow/ag_flow.dart';

/// Reusable API endpoint definitions, grouped by backend domain — not by
/// frontend module hierarchy (see requirments/ag_endpoint_rules.md §5).
/// Backed by https://jsonplaceholder.typicode.com's `/posts` resource for
/// this example (a stable, no-auth public API), re-labeled as "product" to
/// match the module names used throughout the AG spec.
abstract class ProductEndpoints {
  static const products = AgEndpoint(
    '/posts',
    methods: {AgHttpMethod.get, AgHttpMethod.post},
  );
  static const productById = AgEndpoint(
    '/posts/{id}',
    methods: {AgHttpMethod.get, AgHttpMethod.put, AgHttpMethod.delete},
  );
}
