import 'package:ag_flow/ag_flow.dart';
import 'package:ag_showcase_blog/core/arguments/arguments.dart';
import 'package:ag_showcase_blog/modules/post/models/comment.dart';
import 'package:ag_showcase_blog/modules/post/repos/post_details_comments_repo.dart';

/// A detail-shaped module whose data happens to be a `List<Comment>` —
/// jsonplaceholder returns every comment for a post in one call, with no
/// pagination needed, so this is genuinely a single-fetch "detail" read
/// rather than a collection module fighting the wrong shape.
class PostDetailsCommentsController
    extends AgDetailController<List<Comment>, PostDetailsCommentsPageArgument> {
  PostDetailsCommentsController(this._repo);

  final PostDetailsCommentsRepo _repo;

  /// Rebuilds this page's argument from the route's path parameters,
  /// so it opens correctly from a deep link as well as an in-app push.
  @override
  PostDetailsCommentsPageArgument? argumentsFromPath(
    Map<String, String> pathParameters,
  ) => PostDetailsCommentsPageArgument.fromPathParameters(pathParameters);

  @override
  Future<List<Comment>> fetch() => _repo.getByArgument(arguments);
}
