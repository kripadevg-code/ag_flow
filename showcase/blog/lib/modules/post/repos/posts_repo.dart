import 'package:ag_flow/ag_flow.dart';
import 'package:ag_showcase_blog/modules/post/models/post.dart';
import 'package:ag_showcase_blog/modules/post/services/posts_service.dart';

class PostsRepo extends AgBaseRepo {
  const PostsRepo(this._service);

  final PostsService _service;

  Future<AgListPage<Post, int>> getPage(int pageKey) =>
      _service.getPage(pageKey);

  Future<Post> add(Post item) => _service.add(item);

  Future<void> delete(int id) => _service.delete(id);
}
