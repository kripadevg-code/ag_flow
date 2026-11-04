import 'dart:async';

import 'package:ag_flow/ag_flow.dart';

/// The app's [AgAuth]: the login state routes are guarded by, and the token
/// [ApiProvider] sends with every request.
///
/// Registered as a permanent singleton in `InitialBinding`. A real app keeps
/// the token in secure storage; this demo keeps it in memory.
class AuthService extends AgAuth {
  /// Resolves this service from [AgLocator].
  static AuthService get instance => AgLocator.find<AuthService>();

  String? _token;
  UserRole _role = UserRole.guest;

  UserRole get role => _role;

  @override
  String? readToken() => _token;

  @override
  void clearToken() {
    _token = null;
    _role = UserRole.guest;
  }

  /// Stores the token a login call returned, then marks the session active.
  void login({UserRole role = UserRole.user}) {
    _token = 'demo-token-${role.name}';
    _role = role;
    logIn();
  }

  /// Ends the session; the router leaves protected routes on its own.
  void logout() => unawaited(logOut());
}

enum UserRole { guest, user, admin }
