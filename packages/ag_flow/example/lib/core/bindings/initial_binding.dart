import 'package:ag_flow/ag_flow.dart';
import 'package:ag_flow_example/core/auth/auth_service.dart';

/// Registers app-wide singletons that live for the entire app lifetime.
///
/// Two permanent singletons are registered here:
///   • [ApiProvider]   — the shared HTTP client every Service uses.
///   • [AuthService]   — the app's [AgAuth]: login state for the guards,
///                       the token for every request.
class InitialBinding extends AgBinding {
  @override
  void dependencies() {
    // AuthService must be permanent so guards can always find it,
    // even before any route has pushed its own binding.
    final auth = AuthService();
    put<AuthService>(auth, permanent: true);

    put<ApiProvider>(
      // TODO: set your API's real base URL.
      // `auth:` adds the token header to every request.
      ApiProvider(baseUrl: 'https://example.com', auth: auth),
      permanent: true,
    );
  }
}
