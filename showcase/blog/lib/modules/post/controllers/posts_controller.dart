import 'package:ag_flow/ag_flow.dart';
import 'package:ag_showcase_blog/modules/post/models/post.dart';
import 'package:ag_showcase_blog/modules/post/repos/posts_repo.dart';

class PostsController extends AgListController<Post, int> {
  PostsController(this._repo) : super(initialPageKey: 1);

  final PostsRepo _repo;

  @override
  Future<AgListPage<Post, int>> fetchPage(int pageKey) =>
      _repo.getPage(pageKey);

  /// jsonplaceholder's POST always echoes back a fixed id and never
  /// actually persists — `refresh()` re-fetching page 1 would never show
  /// the "created" post, so reflect it directly via the pagination
  /// escape hatch instead.
  Future<void> add(Post item) async {
    final created = await _repo.add(item);
    updateItems((items) => [created, ...items]);
  }

  /// Same reasoning as [add] — reflect the delete directly rather than
  /// refetching a backend that doesn't actually persist writes.
  Future<void> delete(int id) async {
    await _repo.delete(id);
    updateItems((items) => items.where((p) => p.id != id).toList());
  }
}
