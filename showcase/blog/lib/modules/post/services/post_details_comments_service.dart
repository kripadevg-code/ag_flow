import 'package:ag_flow/ag_flow.dart';
import 'package:ag_showcase_blog/core/arguments/arguments.dart';
import 'package:ag_showcase_blog/core/endpoints.dart';
import 'package:ag_showcase_blog/modules/post/models/comment.dart';

/// A nested collection read in one shot (`/posts/{id}/comments`), so
/// neither an action mixin nor paging applies — a feature-specific read is
/// just a plain method written with [send], like every other body.
class PostDetailsCommentsService extends AgBaseService {
  const PostDetailsCommentsService(super.apiProvider);

  Future<List<Comment>> listFor(
    PostDetailsCommentsPageArgument argument,
  ) async {
    final response = await send<List<Comment>>(
      AgRequest(
        endpoint: PostEndpoints.postComments,
        pathParams: {'id': '${argument.postId}'},
      ),
      decode: (json) => [
        for (final item in json! as List<Object?>)
          Comment.fromJson(item! as Map<String, dynamic>),
      ],
    );
    return response.data;
  }
}
