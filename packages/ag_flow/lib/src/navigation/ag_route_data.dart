import 'package:meta/meta.dart';

/// The parameters of the route currently being entered — what a detail
/// controller builds its typed argument from.
///
/// Router-neutral on purpose: `AgRoutePage` records them from whatever the
/// app's router handed it (with go_router, `state.pathParameters` and
/// `state.extra`), and a detail controller reads them in its constructor
/// (`AgRouteData.pathParameters['id']`). Nothing here depends on which router the app uses.
abstract final class AgRouteData {
  /// Path parameters of the route being entered (`{'id': '7'}` for
  /// `/product/7`).
  static Map<String, String> pathParameters = const {};

  /// The non-URL payload of the route being entered. Not deep-link safe —
  /// a cold start, a reload, or a shared link has no extra — so prefer
  /// putting what a page needs into its path.
  static Object? extra;

  @visibleForTesting
  static void reset() {
    pathParameters = const {};
    extra = null;
  }
}
