import 'package:ag_flow/src/navigation/ag_guard.dart';
import 'package:ag_flow/src/network/ag_auth.dart';

/// Sends a logged-out user to [loginPath] — the ready-made [AgGuard] for
/// routes that need a session.
///
/// Pass the same [AgAuth] as go_router's `refreshListenable`, so a login
/// state change (a [AgAuth.logOut], or a failed token refresh) re-runs the
/// guards and the user leaves a protected route straight away:
///
/// ```dart
/// final auth = AppAuth(storage);
/// await auth.restoreSession();
///
/// final router = GoRouter(
///   refreshListenable: auth,
///   routes: [
///     GoRoute(
///       path: AppRoutes.home,
///       name: AppRoutes.home,
///       redirect: (context, state) => AgGuard.check(
///         [AgAuthGuard(auth, loginPath: AppRoutes.login)],
///         state.fullPath!,
///       ),
///       pageBuilder: ...,
///     ),
///   ],
/// );
/// ```
class AgAuthGuard extends AgGuard {
  /// A guard that reads [auth]'s login state.
  const AgAuthGuard(this.auth, {required this.loginPath});

  /// The login state this guard reads.
  final AgAuth auth;

  /// Where a logged-out user is sent. Never redirected itself.
  final String loginPath;

  @override
  String? redirect(String path) => auth.isLoggedIn || path == loginPath ? null : loginPath;
}
