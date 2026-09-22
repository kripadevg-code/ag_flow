import 'package:ag_flow/ag_flow.dart';

/// Holds the current session state for the whole app.
///
/// Registered as a permanent singleton in [InitialBinding] so every
/// guard and widget can read it synchronously.
///
/// Access it anywhere without generics:
/// ```dart
/// final authService = AuthService.instance;
/// ```
class AuthService extends AgStateService {
  /// Resolves this service from [AgLocator] — no generics at call sites:
  /// ```dart
  /// final authService = AuthService.instance;
  /// ```
  static AuthService get instance => AgLocator.find<AuthService>();

  bool _isLoggedIn = false;
  UserRole _role = UserRole.guest;

  bool get isLoggedIn => _isLoggedIn;
  UserRole get role => _role;

  void login({UserRole role = UserRole.user}) {
    _isLoggedIn = true;
    _role = role;
    notifyListeners();
  }

  void logout() {
    _isLoggedIn = false;
    _role = UserRole.guest;
    notifyListeners();
  }
}

enum UserRole { guest, user, admin }
