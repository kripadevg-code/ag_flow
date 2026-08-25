import 'package:ag_flow/ag_flow.dart';
import 'package:ag_showcase_blog/core/arguments/arguments.dart';
import 'package:ag_showcase_blog/core/endpoints.dart';
import 'package:ag_showcase_blog/modules/post/models/post.dart';

/// The same declarative shape as every other Service. The only
/// app-specific line is [idOf] — which field of the navigation argument
/// identifies the post.
class PostDetailsService extends AgBaseService with AgCrudService<Post, int> {
  PostDetailsService(super.apiProvider);

  @override
  AgEndpoint get collectionEndpoint => PostEndpoints.posts;

  @override
  AgEndpoint get resourceEndpoint => PostEndpoints.postById;

  @override
  Post fromJson(Map<String, dynamic> json) => Post.fromJson(json);

  @override
  Map<String, dynamic> toJson(Post item) => item.toJson();

  int idOf(PostDetailsPageArgument argument) => argument.postId;

  Future<Post> getByArgument(PostDetailsPageArgument argument) =>
      getById(idOf(argument));

  Future<Post> updateByArgument(PostDetailsPageArgument argument, Post item) =>
      update(idOf(argument), item);

  Future<void> deleteByArgument(PostDetailsPageArgument argument) =>
      delete(idOf(argument));
}
