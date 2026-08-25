import 'package:ag_flow/ag_flow.dart';
import 'package:ag_showcase_blog/core/arguments/arguments.dart';
import 'package:ag_showcase_blog/core/endpoints.dart';
import 'package:ag_showcase_blog/modules/post/models/comment.dart';

/// A nested collection read in one shot (`/posts/{id}/comments`), so
/// neither CRUD nor paging applies. Even here the read is one declarative
/// line: [fetchList] unwraps via the Service's `envelope` and decodes,
/// exactly like every other read in the app.
class PostDetailsCommentsService extends AgBaseService {
  const PostDetailsCommentsService(super.apiProvider);

  Future<List<Comment>> getByArgument(
    PostDetailsCommentsPageArgument argument,
  ) => fetchList(
    AgRequest(
      endpoint: PostEndpoints.postComments,
      pathParams: {'id': '${argument.postId}'},
    ),
    Comment.fromJson,
  );
}
