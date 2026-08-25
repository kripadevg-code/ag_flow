import 'package:ag_flow/ag_flow.dart';
import 'package:ag_showcase_blog/core/arguments/arguments.dart';
import 'package:ag_showcase_blog/modules/post/models/post.dart';
import 'package:ag_showcase_blog/modules/post/services/post_details_service.dart';

class PostDetailsRepo extends AgBaseRepo {
  const PostDetailsRepo(this._service);

  final PostDetailsService _service;

  Future<Post> getByArgument(PostDetailsPageArgument argument) =>
      _service.getByArgument(argument);

  Future<Post> update(PostDetailsPageArgument argument, Post item) =>
      _service.updateByArgument(argument, item);

  Future<void> delete(PostDetailsPageArgument argument) =>
      _service.deleteByArgument(argument);
}
