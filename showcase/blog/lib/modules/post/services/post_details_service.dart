import 'package:ag_flow/ag_flow.dart';
import 'package:ag_showcase_blog/core/endpoints.dart';
import 'package:ag_showcase_blog/modules/post/models/post.dart';

/// The same declarative shape as every other Service. Which post to load
/// is the controller's `lookupId`, not this file's concern.
class PostDetailsService extends AgBaseService
    with AgRetrieveMixin<Post, int>, AgUpdateMixin<Post, int>, AgDestroyMixin<int> {
  PostDetailsService(super.apiProvider);

  @override
  Future<Post> retrieve(int id) => get(
    PostEndpoints.postById,
    pathParams: {'id': id},
    decode: (json) => Post.fromJson(json! as Map<String, dynamic>),
  );

  @override
  Future<Post> update(int id, Post item) => put(
    PostEndpoints.postById,
    pathParams: {'id': id},
    body: item.toJson(),
    decode: (json) => Post.fromJson(json! as Map<String, dynamic>),
  );

  @override
  Future<void> destroy(int id) => delete(PostEndpoints.postById, pathParams: {'id': id});
}
