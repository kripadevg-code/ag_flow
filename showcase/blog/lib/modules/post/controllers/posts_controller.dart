import 'package:ag_flow/ag_flow.dart';
import 'package:ag_showcase_blog/modules/post/models/post.dart';
import 'package:ag_showcase_blog/modules/post/repos/posts_repo.dart';

class PostsController extends AgBaseController<List<Post>>
    with AgLoadMore<Post> {
  PostsController(this._repo);

  final PostsRepo _repo;

  @override
  Future<List<Post>> list({int page = 1}) => _repo.list(page: page);

  @override
  bool isLastPage(List<Post> items) => _repo.isLastPage(items);

  /// jsonplaceholder never persists writes, so a `refresh()` would not show
  /// the change — the shown list is updated in place instead.
  Future<void> create(Post item) async {
    final created = await _repo.create(item);
    emit(AgPageState.success([created, ...?state.dataOrNull]));
  }

  Future<void> destroy(int id) async {
    await _repo.destroy(id);
    final shown = state.dataOrNull ?? const <Post>[];
    emit(AgPageState.success(shown.where((p) => p.id != id).toList()));
  }
}
