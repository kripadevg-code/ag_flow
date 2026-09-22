// The single application-level file for every navigation argument class
// (see requirments/routes.md §3). `ag g m` maintains this automatically
// for detail/child modules — there must never be more than one of this
// file in the application.

class PostDetailsPageArgument {
  const PostDetailsPageArgument({required this.postId});

  /// Rebuilds this argument from the route's path parameters, so the
  /// page opens correctly from a deep link as well as an in-app tap.
  /// Path parameters are always strings; this module's id is an int, so
  /// the conversion lives here.
  factory PostDetailsPageArgument.fromPathParameters(
    Map<String, String> pathParameters,
  ) {
    final raw = pathParameters['id'];
    final postId = raw == null ? null : int.tryParse(raw);
    if (postId == null) {
      throw ArgumentError(
        'Route was opened with an invalid "id" path parameter: $raw',
      );
    }
    return PostDetailsPageArgument(postId: postId);
  }

  final int postId;

  Map<String, String> toPathParameters() => {'id': '$postId'};
}

class PostDetailsCommentsPageArgument {
  const PostDetailsCommentsPageArgument({required this.postId});

  /// Rebuilds this argument from the route's path parameters, so the
  /// page opens correctly from a deep link as well as an in-app tap.
  /// Path parameters are always strings; this module's id is an int, so
  /// the conversion lives here.
  factory PostDetailsCommentsPageArgument.fromPathParameters(
    Map<String, String> pathParameters,
  ) {
    final raw = pathParameters['id'];
    final postId = raw == null ? null : int.tryParse(raw);
    if (postId == null) {
      throw ArgumentError(
        'Route was opened with an invalid "id" path parameter: $raw',
      );
    }
    return PostDetailsCommentsPageArgument(postId: postId);
  }

  final int postId;

  Map<String, String> toPathParameters() => {'id': '$postId'};
}
