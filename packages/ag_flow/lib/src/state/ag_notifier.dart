import 'package:flutter/foundation.dart';

/// A [ChangeNotifier] whose [notify] method calls the otherwise-`
/// @protected` [notifyListeners] publicly.
///
/// [ChangeNotifier.notifyListeners] is deliberately `@protected` —
/// intended for a class's own subclasses to call, never an unrelated
/// holder of an instance reference. AG needs exactly that second case:
/// [AgPaginationMixin] holds a *separate* notifier instance (kept apart
/// from the controller's own page-state notifications, so a pagination-
/// only change never also re-triggers `AgPage`'s loading/error/empty/
/// success switch) and must be able to fire it from outside.
class AgNotifier extends ChangeNotifier {
  void notify() => notifyListeners();
}
