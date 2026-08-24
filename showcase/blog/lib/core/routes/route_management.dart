import 'package:ag_flow/ag_flow.dart';
import 'package:ag_showcase_blog/core/arguments/arguments.dart';

import 'app_routes.dart';

abstract class RouteManagement {
  static void goToPostsPage() {
    AgNavigator.toNamed<dynamic>(AppRoutes.post);
  }

  static void goToPostDetailsPage(PostDetailsPageArgument argument) {
    AgNavigator.toNamed<dynamic>(AppRoutes.postDetails, arguments: argument);
  }

  static void goToPostDetailsCommentsPage(
    PostDetailsCommentsPageArgument argument,
  ) {
    AgNavigator.toNamed<dynamic>(
      AppRoutes.postDetailsComments,
      arguments: argument,
    );
  }
}
