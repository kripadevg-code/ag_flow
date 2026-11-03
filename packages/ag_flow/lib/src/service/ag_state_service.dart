import 'package:flutter/foundation.dart';

/// Base class for app-wide state services that hold reactive state but do
/// not make network calls (no [ApiProvider] dependency).
///
/// Common examples: `AuthService`, `ThemeService`, `CartService`,
/// `LocaleService` — services that own mutable app-level state, broadcast
/// changes via [notifyListeners], and live for the entire app lifetime as
/// permanent [AgLocator] singletons.
///
/// Extends [ChangeNotifier] so any widget or controller can listen to
/// state changes directly without a separate stream or reactive wrapper.
///
/// Contrast with [AgBaseService], which owns HTTP communication and always
/// receives an [ApiProvider] in its constructor.  Use [AgStateService] when
/// there is no network layer involved.
///
/// ### Usage
///
/// ```dart
/// class AuthService extends AgStateService {
///   bool get isLoggedIn => _isLoggedIn;
///   bool _isLoggedIn = false;
///
///   void login() {
///     _isLoggedIn = true;
///     notifyListeners();
///   }
/// }
/// ```
///
/// Register it once (`AgLocator.put(AuthService(), permanent: true)` in the
/// initial binding) and resolve it anywhere:
///
/// ```dart
/// final authService = AgLocator.find<AuthService>();
/// ```
abstract class AgStateService extends ChangeNotifier {
  AgStateService();
}
