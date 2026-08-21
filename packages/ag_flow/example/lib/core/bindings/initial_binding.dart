import 'package:ag_flow/ag_flow.dart';

/// Registers the single, shared [ApiProvider] used by every Service in
/// the app (see requirments/ag_endpoint_rules.md §22).
class InitialBinding extends Bindings {
  @override
  void dependencies() {
    Get.put<ApiProvider>(
      // TODO: set your API's real base URL.
      ApiProvider(baseUrl: 'https://example.com'),
      permanent: true,
    );
  }
}
