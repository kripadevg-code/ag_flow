import 'package:ag_flow/ag_flow.dart';
import 'package:ag_showcase_blog/core/arguments/arguments.dart';
import 'package:ag_showcase_blog/modules/post/models/post.dart';
import 'package:ag_showcase_blog/modules/post/repos/post_details_repo.dart';

class PostDetailsController
    extends AgDetailController<Post, PostDetailsPageArgument> {
  PostDetailsController(this._repo);

  final PostDetailsRepo _repo;

  @override
  Future<Post> fetch() => _repo.getByArgument(arguments);

  Future<void> update(Post item) async {
    final updated = await _repo.update(arguments, item);
    emit(AgPageState.success(updated));
  }

  /// jsonplaceholder never actually removes the post — this is a live
  /// demo of the DELETE call itself, not a persistence guarantee — so on
  /// success we simply pop back to the list rather than trying to reflect
  /// the deletion anywhere.
  Future<void> delete() async {
    await _repo.delete(arguments);
    AgNavigator.back<void>();
  }
}
