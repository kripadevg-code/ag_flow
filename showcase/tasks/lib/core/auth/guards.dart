import 'package:ag_flow/ag_flow.dart';
import 'package:ag_showcase_tasks/core/auth/auth_service.dart';
import 'package:ag_showcase_tasks/core/routes/app_routes.dart';

/// [AuthGuard] — attach to any route that requires authentication.
///
/// If the user is NOT logged in → redirect to [AppRoutes.login].
/// If the user IS  logged in   → allow through (return null).
///
/// ```dart
/// AgRoute(
///   path: AppRoutes.tasks,
///   page: TasksPage.new,
///   guards: [const AuthGuard()],
/// )
/// ```
class AuthGuard extends AgGuard {
  const AuthGuard();

  @override
  String? redirect(String path) {
    return AuthService.instance.isLoggedIn ? null : AppRoutes.login;
  }
}

/// [GuestGuard] — attach to auth routes (/login, /register).
///
/// If the user IS already logged in → redirect to [AppRoutes.tasks].
/// If the user is NOT logged in    → allow through (return null).
///
/// Prevents a logged-in user reaching the login screen via a deep link
/// or the back button.
///
/// ```dart
/// AgRoute(
///   path: AppRoutes.login,
///   page: LoginPage.new,
///   guards: [const GuestGuard()],
/// )
/// ```
class GuestGuard extends AgGuard {
  const GuestGuard();

  @override
  String? redirect(String path) {
    return AuthService.instance.isLoggedIn ? AppRoutes.tasks : null;
  }
}
