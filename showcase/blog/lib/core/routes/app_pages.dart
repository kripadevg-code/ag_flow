import 'package:ag_flow/ag_flow.dart';
import 'package:ag_showcase_blog/modules/post/bindings/post_details_binding.dart';
import 'package:ag_showcase_blog/modules/post/bindings/post_details_comments_binding.dart';
import 'package:ag_showcase_blog/modules/post/bindings/posts_binding.dart';
import 'package:ag_showcase_blog/modules/post/pages/post_details_comments_page.dart';
import 'package:ag_showcase_blog/modules/post/pages/post_details_page.dart';
import 'package:ag_showcase_blog/modules/post/pages/posts_page.dart';

import 'app_routes.dart';

abstract class AppPages {
  static const AgTransition defaultTransition = AgTransition.rightToLeft;

  static final List<AgRoute> pages = [
    AgRoute(
      name: AppRoutes.post,
      page: PostsPage.new,
      binding: PostsBinding(),
      transition: AppPages.defaultTransition,
    ),

    AgRoute(
      name: AppRoutes.postDetails,
      page: PostDetailsPage.new,
      binding: PostDetailsBinding(),
      transition: AppPages.defaultTransition,
    ),

    AgRoute(
      name: AppRoutes.postDetailsComments,
      page: PostDetailsCommentsPage.new,
      binding: PostDetailsCommentsBinding(),
      transition: AppPages.defaultTransition,
    ),
  ];
}
