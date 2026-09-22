import 'package:ag_flow/ag_flow.dart';
import 'package:ag_flow_example/core/auth/auth_service.dart';

/// Registers app-wide singletons that live for the entire app lifetime.
///
/// Two permanent singletons are registered here:
///   • [ApiProvider]   — the shared HTTP client every Service uses.
///   • [AuthService]   — the single source of truth for login state,
///                       read synchronously by every [AgGuard].
class InitialBinding extends AgBinding {
  @override
  void dependencies() {
    put<ApiProvider>(
      // TODO: set your API's real base URL.
      ApiProvider(baseUrl: 'https://example.com'),
      permanent: true,
    );

    // AuthService must be permanent so guards can always find it,
    // even before any route has pushed its own binding.
    put<AuthService>(AuthService(), permanent: true);
  }
}
