abstract class AppRoutes {
  static const String initial = _Routes.initial;
  static const String post = _Routes.post;
  static const String postDetails = _Routes.postDetails;
  static const String postDetailsComments = _Routes.postDetailsComments;
}

abstract class _Routes {
  static const String initial = '/';
  static const String post = '/post';
  static const String postDetails = '/post/details';
  static const String postDetailsComments = '/post/details/comments';
}
