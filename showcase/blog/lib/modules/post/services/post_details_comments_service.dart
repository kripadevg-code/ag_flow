import 'package:ag_flow/ag_flow.dart';
import 'package:ag_showcase_blog/core/arguments/arguments.dart';
import 'package:ag_showcase_blog/core/endpoints.dart';
import 'package:ag_showcase_blog/modules/post/models/comment.dart';

class PostDetailsCommentsService extends AgBaseService {
  PostDetailsCommentsService(super.apiProvider);

  Future<List<Comment>> getByArgument(
    PostDetailsCommentsPageArgument argument,
  ) async {
    final response = await send<List<dynamic>>(
      AgRequest(
        endpoint: PostEndpoints.postComments,
        pathParams: {'id': '${argument.postId}'},
      ),
      decode: (json) => json as List<dynamic>,
    );
    return response.data
        .map((j) => Comment.fromJson(j as Map<String, dynamic>))
        .toList();
  }
}
