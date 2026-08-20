import 'package:dio/dio.dart' show CancelToken;

/// A handle for cancelling an in-flight `ApiProvider.send` call —
/// `ApiProvider`'s own dio-free equivalent of dio's `CancelToken`, so
/// callers never need to import `package:dio` themselves just to cancel a
/// request in flight.
class AgCancelToken {
  /// The underlying dio token — `ApiProvider.send`'s own internal wiring,
  /// not meant for application code. Use [cancel]/[isCancelled]/
  /// [whenCancel] instead.
  final CancelToken dioToken = CancelToken();

  /// Cancels the request this token is attached to, if it's still in
  /// flight.
  void cancel([Object? reason]) => dioToken.cancel(reason);

  /// Whether [cancel] has already been called.
  bool get isCancelled => dioToken.isCancelled;

  /// Completes when [cancel] is called.
  Future<void> get whenCancel => dioToken.whenCancel;
}
