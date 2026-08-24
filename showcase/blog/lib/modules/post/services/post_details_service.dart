import 'package:ag_flow/ag_flow.dart';
import 'package:ag_showcase_blog/core/arguments/arguments.dart';
import 'package:ag_showcase_blog/core/endpoints.dart';
import 'package:ag_showcase_blog/modules/post/models/post.dart';

class PostDetailsService extends AgBaseService {
  PostDetailsService(super.apiProvider);

  Future<Post> getByArgument(PostDetailsPageArgument argument) async {
    final response = await send<Map<String, dynamic>>(
      AgRequest(
        endpoint: PostEndpoints.postById,
        pathParams: {'id': '${argument.postId}'},
      ),
      decode: (json) => json as Map<String, dynamic>,
    );
    return Post.fromJson(response.data);
  }

  Future<Post> update(PostDetailsPageArgument argument, Post item) async {
    final response = await send<Map<String, dynamic>>(
      AgRequest(
        endpoint: PostEndpoints.postById,
        method: AgHttpMethod.put,
        pathParams: {'id': '${argument.postId}'},
        body: item.toJson(),
      ),
      decode: (json) => json as Map<String, dynamic>,
    );
    return Post.fromJson(response.data);
  }

  Future<void> delete(PostDetailsPageArgument argument) async {
    await send<void>(
      AgRequest(
        endpoint: PostEndpoints.postById,
        method: AgHttpMethod.delete,
        pathParams: {'id': '${argument.postId}'},
      ),
    );
  }
}
