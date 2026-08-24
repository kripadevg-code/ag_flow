import 'package:ag_flow/ag_flow.dart';

/// Registers the single, shared [ApiProvider] used by every Service in
/// the app (see requirments/ag_endpoint_rules.md §22).
class InitialBinding extends AgBinding {
  @override
  void dependencies() {
    put<ApiProvider>(
      // TODO: set your API's real base URL.
      ApiProvider(baseUrl: 'https://example.com'),
      permanent: true,
    );
  }
}
