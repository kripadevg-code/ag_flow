import 'package:ag_flow/ag_flow.dart';

/// Registers the single, shared [ApiProvider] used by every Service in
/// the app (see requirments/ag_endpoint_rules.md §22).
///
/// `retryPolicy` demonstrates [AgRetryPolicy]: fakestoreapi.com is a free
/// public demo API with no SLA, so a transient 502/503/504 or connection
/// hiccup is retried automatically (default: up to 3 attempts, backing off)
/// before an error ever reaches the UI.
class InitialBinding extends AgBinding {
  @override
  void dependencies() {
    put<ApiProvider>(
      ApiProvider(
        baseUrl: 'https://fakestoreapi.com',
        retryPolicy: const AgRetryPolicy(),
      ),
      permanent: true,
    );
  }
}
