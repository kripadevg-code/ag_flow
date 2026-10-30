import 'package:ag_showcase_blog/core/arguments/arguments.dart';

import 'app_pages.dart';
import 'app_routes.dart';

/// The only place the app navigates by route — every screen calls a
/// `goToXPage(...)` method here, never a literal path.
abstract class RouteManagement {
  static void goToPostsPage() {
    AppPages.router.pushNamed<void>(AppRoutes.post);
  }

  static void goToPostDetailsPage(PostDetailsPageArgument argument) {
    AppPages.router.pushNamed<void>(
      AppRoutes.postDetails,
      pathParameters: argument.toPathParameters(),
    );
  }

  static void goToPostDetailsCommentsPage(
    PostDetailsCommentsPageArgument argument,
  ) {
    AppPages.router.pushNamed<void>(
      AppRoutes.postDetailsComments,
      pathParameters: argument.toPathParameters(),
    );
  }

  /// Pops the current page, if there is one to pop back to.
  static void back() {
    if (AppPages.router.canPop()) AppPages.router.pop();
  }
}
