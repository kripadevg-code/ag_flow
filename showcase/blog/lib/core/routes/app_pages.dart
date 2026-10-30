import 'package:ag_flow/ag_flow.dart';
import 'package:ag_showcase_blog/modules/post/bindings/post_details_binding.dart';
import 'package:ag_showcase_blog/modules/post/bindings/post_details_comments_binding.dart';
import 'package:ag_showcase_blog/modules/post/bindings/posts_binding.dart';
import 'package:ag_showcase_blog/modules/post/pages/post_details_comments_page.dart';
import 'package:ag_showcase_blog/modules/post/pages/post_details_page.dart';
import 'package:ag_showcase_blog/modules/post/pages/posts_page.dart';
import 'package:go_router/go_router.dart';

import 'app_routes.dart';

abstract class AppPages {
  static const AgTransition defaultTransition = AgTransition.rightToLeft;

  /// Hand this to `MaterialApp.router(routerConfig: AppPages.router)`.
  static final GoRouter router = GoRouter(
    initialLocation: AppRoutes.post,
    routes: pages,
  );

  static final List<RouteBase> pages = [
    GoRoute(
      path: AppRoutes.post,
      name: AppRoutes.post,
      pageBuilder: (context, state) => AgRoutePage<void>(
        key: state.pageKey,
        pathParameters: state.pathParameters,
        extra: state.extra,
        binding: PostsBinding(),
        transition: AppPages.defaultTransition,
        child: const PostsPage(),
      ),
    ),

    GoRoute(
      path: AppRoutes.postDetails,
      name: AppRoutes.postDetails,
      pageBuilder: (context, state) => AgRoutePage<void>(
        key: state.pageKey,
        pathParameters: state.pathParameters,
        extra: state.extra,
        binding: PostDetailsBinding(),
        transition: AppPages.defaultTransition,
        child: const PostDetailsPage(),
      ),
    ),

    GoRoute(
      path: AppRoutes.postDetailsComments,
      name: AppRoutes.postDetailsComments,
      pageBuilder: (context, state) => AgRoutePage<void>(
        key: state.pageKey,
        pathParameters: state.pathParameters,
        extra: state.extra,
        binding: PostDetailsCommentsBinding(),
        transition: AppPages.defaultTransition,
        child: const PostDetailsCommentsPage(),
      ),
    ),
  ];
}
