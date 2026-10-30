import 'package:ag_flow/ag_flow.dart';
import 'package:ag_showcase_blog/modules/post/models/post.dart';
import 'package:ag_showcase_blog/modules/post/services/post_details_service.dart';

class PostDetailsRepo extends AgBaseRepo {
  const PostDetailsRepo(this._service);

  final PostDetailsService _service;

  Future<Post> retrieve(int id) => guard(() => _service.retrieve(id));

  Future<Post> update(int id, Post item) => guard(() => _service.update(id, item));

  Future<void> destroy(int id) => guard(() => _service.destroy(id));
}
