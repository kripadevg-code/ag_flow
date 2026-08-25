import 'package:ag_flow/ag_flow.dart';
import 'package:ag_showcase_blog/core/endpoints.dart';
import 'package:ag_showcase_blog/modules/post/models/post.dart';

/// jsonplaceholder pages with `?_page=N&_limit=N` and returns a bare
/// array. That entire difference from any other backend is the one
/// [pageStrategy] line below — there is no request, decoding, or
/// `hasMore` code in this file, and there shouldn't be in yours either.
class PostsService extends AgBaseService
    with AgCrudService<Post, int>, AgPagedService<Post, int> {
  PostsService(super.apiProvider);

  @override
  AgEndpoint get collectionEndpoint => PostEndpoints.posts;

  @override
  AgEndpoint get resourceEndpoint => PostEndpoints.postById;

  @override
  AgPageStrategy<int> get pageStrategy => const AgPageNumberStrategy(
    pageParam: '_page',
    sizeParam: '_limit',
    pageSize: 10,
  );

  @override
  Post fromJson(Map<String, dynamic> json) => Post.fromJson(json);

  @override
  Map<String, dynamic> toJson(Post item) => item.toJson();
}
