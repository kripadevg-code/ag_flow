import 'package:ag_flow/ag_flow.dart';
import 'package:ag_showcase_blog/core/arguments/arguments.dart';
import 'package:ag_showcase_blog/modules/post/models/comment.dart';
import 'package:ag_showcase_blog/modules/post/repos/post_details_comments_repo.dart';

/// A detail-shaped module whose data happens to be a `List<Comment>` —
/// jsonplaceholder returns every comment for a post in one call, with no
/// pagination needed, so this is genuinely a single-read "detail" list
/// rather than a collection module fighting the wrong shape.
class PostDetailsCommentsController extends AgBaseController<List<Comment>>
    with AgList<Comment> {
  /// Rebuilds this page's argument from the route's path parameters,
  /// so it opens correctly from a deep link as well as an in-app push.
  PostDetailsCommentsController(this._repo)
    : argument = PostDetailsCommentsPageArgument.fromPathParameters(
        AgRouteData.pathParameters,
      );

  final PostDetailsCommentsRepo _repo;

  final PostDetailsCommentsPageArgument argument;

  @override
  Future<List<Comment>> list() => _repo.listFor(argument);
}
