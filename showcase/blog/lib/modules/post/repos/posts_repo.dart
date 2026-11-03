import 'package:ag_flow/ag_flow.dart';
import 'package:ag_showcase_blog/modules/post/models/post.dart';
import 'package:ag_showcase_blog/modules/post/services/posts_service.dart';

class PostsRepo extends AgBaseRepo {
  const PostsRepo(this._service);

  final PostsService _service;

  Future<List<Post>> list({int page = 1}) => guard(() => _service.list(page: page));

  bool isLastPage(List<Post> items) => _service.pagination.isLastPage(items);

  Future<Post> create(Post item) => guard(() => _service.create(item));

  Future<void> destroy(int id) => guard(() => _service.destroy(id));
}
