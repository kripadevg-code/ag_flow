import 'package:ag_flow/ag_flow.dart';
import 'package:ag_showcase_blog/core/arguments/arguments.dart';
import 'package:ag_showcase_blog/modules/post/models/post.dart';
import 'package:ag_showcase_blog/modules/post/repos/post_details_repo.dart';

class PostDetailsController extends AgBaseController<Post> {
  PostDetailsController(this._repo)
    : argument = PostDetailsPageArgument.fromPathParameters(
        AgRouteData.pathParameters,
      );

  final PostDetailsRepo _repo;

  final PostDetailsPageArgument argument;

  int get lookupId => argument.postId;

  @override
  Future<Post> fetch() => _repo.retrieve(lookupId);

  Future<void> update(Post item) async {
    emit(AgPageState.success(await _repo.update(lookupId, item)));
  }

  Future<void> destroy() => _repo.destroy(lookupId);
}
