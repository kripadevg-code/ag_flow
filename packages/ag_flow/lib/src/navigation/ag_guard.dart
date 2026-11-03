/// A single route guard — AG's hook for intercepting a navigation push
/// before the destination page is built.
///
/// Implement this class and run one or more instances from a go_router
/// route's `redirect` via [check].  When the route is about to be pushed,
/// every guard's [redirect] is called **in order**.  The first guard that
/// returns a non-null route name wins; the remaining guards are skipped
/// and the navigator goes to that route instead.  Returning `null` means
/// "let this route proceed".
///
/// ---
/// ### Minimal example — auth guard
///
/// ```dart
/// class AuthGuard extends AgGuard {
///   @override
///   String? redirect(String path) {
///     final isLoggedIn = AgLocator.find<AuthService>().isLoggedIn;
///     return isLoggedIn ? null : AppRoutes.login;
///   }
/// }
/// ```
///
/// Attach it to every protected route:
///
/// ```dart
/// GoRoute(
///   path: AppRoutes.home,
///   name: AppRoutes.home,
///   redirect: (context, state) =>
///       AgGuard.check(const [AuthGuard()], state.fullPath!),
///   pageBuilder: (context, state) => AgRoutePage(
///     key: state.pageKey,
///     binding: HomeBinding(),
///     child: HomePage(key: state.pageKey),
///   ),
/// )
/// ```
///
/// ---
/// ### Multiple guards on one route
///
/// Guards run **left to right**.  As soon as one redirects, the rest are
/// skipped.  Use this to combine concerns cleanly without writing a
/// single mega-guard:
///
/// ```dart
/// redirect: (context, state) => AgGuard.check(
///   const [AuthGuard(), AdminGuard()],   // auth first, role second
///   state.fullPath!,
/// ),
/// ```
///
/// ---
/// ### Async state
///
/// [redirect] is intentionally synchronous so guard resolution never
/// blocks the navigation pipeline.  For guards that depend on async
/// state (e.g. a token loaded from secure storage), load that state
/// once during app start-up (typically in [AgBinding.dependencies] or
/// your `InitialBinding`) and keep it in a service that [redirect] reads
/// synchronously.
abstract class AgGuard {
  const AgGuard();

  /// Called before the route at [path] is built.
  ///
  /// - Return `null`  → allow navigation to proceed as normal.
  /// - Return a route name (e.g. `AppRoutes.login`) → redirect there
  ///   instead, replacing the current route so the user can't go back
  ///   to the blocked destination via the back button.
  ///
  /// [path] is the route's *template* (`/product/:id`), not the
  /// resolved location, so it compares directly against the `AppRoutes`
  /// constant. It lets a single guard instance serve multiple routes
  /// while behaving differently per route:
  ///
  /// ```dart
  /// @override
  /// String? redirect(String path) {
  ///   if (!_auth.isLoggedIn) return AppRoutes.login;
  ///   if (path == AppRoutes.admin && !_auth.isAdmin) {
  ///     return AppRoutes.home;   // logged in but not admin
  ///   }
  ///   return null;
  /// }
  /// ```
  String? redirect(String path);

  /// Runs [guards] in order and returns the first redirect, or null to
  /// allow. Wire it into a go_router route as
  /// `redirect: (context, state) => AgGuard.check(guards, state.fullPath!)`.
  static String? check(List<AgGuard> guards, String path) {
    for (final guard in guards) {
      final redirectTo = guard.redirect(path);
      if (redirectTo != null) return redirectTo;
    }
    return null;
  }
}
