import 'package:ag_flow/ag_flow.dart';
import 'package:ag_showcase_blog/core/endpoints.dart';
import 'package:ag_showcase_blog/modules/post/models/post.dart';

/// jsonplaceholder pages with `?_page=N&_limit=N` and returns a bare
/// array. That entire difference from any other backend is the one
/// [pagination] line below — `list` just sends `pagination.query(page)`,
/// and there is no `hasMore` code in this file.
class PostsService extends AgBaseService
    with AgListMixin<Post>, AgCreateMixin<Post>, AgDestroyMixin<int> {
  PostsService(super.apiProvider);

  @override
  AgPagination get pagination => const AgPageNumberPagination(
    pageParam: '_page',
    sizeParam: '_limit',
    pageSize: 10,
  );

  @override
  Future<List<Post>> list({int page = 1}) => get(
    PostEndpoints.posts,
    queryParams: pagination.query(page),
    decode: (json) => [
      for (final item in json! as List<Object?>) Post.fromJson(item! as Map<String, dynamic>),
    ],
  );

  @override
  Future<Post> create(Post item) => post(
    PostEndpoints.posts,
    body: item.toJson(),
    decode: (json) => Post.fromJson(json! as Map<String, dynamic>),
  );

  @override
  Future<void> destroy(int id) => delete(PostEndpoints.postById, pathParams: {'id': id});
}
