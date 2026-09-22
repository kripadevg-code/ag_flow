import 'package:ag_flow/ag_flow.dart';

/// Holds the current session state for the whole app.
///
/// Extends [AgStateService] — AG's base for reactive state services that
/// do not make network calls. Registered as a permanent singleton in
/// [InitialBinding] so every guard and widget can resolve it synchronously.
///
/// In a real app, [_isLoggedIn] and [_userId] would be hydrated from
/// secure storage in [InitialBinding.dependencies] before the first frame,
/// so the initial route guard fires with the correct state.
///
/// Usage — no generics at call sites:
/// ```dart
/// final authService = AuthService.instance;
/// if (authService.isLoggedIn) { ... }
/// ```
class AuthService extends AgStateService {
  /// Resolves this service from [AgLocator] without generic syntax.
  static AuthService get instance => AgLocator.find<AuthService>();

  bool _isLoggedIn = false;
  int _userId = 0;
  String _displayName = '';

  bool get isLoggedIn => _isLoggedIn;
  int get userId => _userId;
  String get displayName => _displayName;

  /// Simulates a successful login. In production this would verify
  /// credentials against your API, store a JWT in secure storage, and set
  /// [_isLoggedIn] from the stored token.
  Future<void> login({required String email, required String password}) async {
    // Simulate network latency.
    await Future<void>.delayed(const Duration(milliseconds: 600));

    // Simulate a credential check — accept any non-empty pair.
    if (email.isEmpty || password.isEmpty) {
      throw Exception('Email and password are required.');
    }

    _isLoggedIn = true;
    _userId = 1; // jsonplaceholder user id
    _displayName = email.split('@').first;
    notifyListeners();
  }

  /// Simulates registration — in production: create account, then login.
  Future<void> register({
    required String name,
    required String email,
    required String password,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 800));
    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      throw Exception('All fields are required.');
    }
    _isLoggedIn = true;
    _userId = 1;
    _displayName = name;
    notifyListeners();
  }

  void logout() {
    _isLoggedIn = false;
    _userId = 0;
    _displayName = '';
    notifyListeners();
  }
}
