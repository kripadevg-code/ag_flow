import 'package:ag_flow/ag_flow.dart';
import 'package:ag_showcase_blog/core/arguments/arguments.dart';
import 'package:ag_showcase_blog/modules/post/models/comment.dart';
import 'package:ag_showcase_blog/modules/post/services/post_details_comments_service.dart';

class PostDetailsCommentsRepo extends AgBaseRepo {
  const PostDetailsCommentsRepo(this._service);

  final PostDetailsCommentsService _service;

  Future<List<Comment>> getByArgument(
    PostDetailsCommentsPageArgument argument,
  ) => _service.getByArgument(argument);
}
