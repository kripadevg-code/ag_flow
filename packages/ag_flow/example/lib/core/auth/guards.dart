import 'package:ag_flow/ag_flow.dart';
import 'package:ag_flow_example/core/auth/auth_service.dart';
import 'package:ag_flow_example/core/routes/app_routes.dart';

// ---------------------------------------------------------------------------
// Use-case 1: AuthGuard
// ---------------------------------------------------------------------------
class AuthGuard extends AgGuard {
  const AuthGuard();

  @override
  String? redirect(String routeName) {
    final authService = AuthService.instance;
    return authService.isLoggedIn ? null : AppRoutes.login;
  }
}

// ---------------------------------------------------------------------------
// Use-case 2: GuestGuard
// ---------------------------------------------------------------------------
class GuestGuard extends AgGuard {
  const GuestGuard();

  @override
  String? redirect(String routeName) {
    final authService = AuthService.instance;
    return authService.isLoggedIn ? AppRoutes.home : null;
  }
}

// ---------------------------------------------------------------------------
// Use-case 3: RoleGuard
// ---------------------------------------------------------------------------
class RoleGuard extends AgGuard {
  const RoleGuard(this.requiredRole);

  final UserRole requiredRole;

  @override
  String? redirect(String routeName) {
    final authService = AuthService.instance;
    return authService.role == requiredRole ? null : AppRoutes.home;
  }
}
