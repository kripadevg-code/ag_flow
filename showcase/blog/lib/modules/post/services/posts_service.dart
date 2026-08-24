import 'package:ag_flow/ag_flow.dart';
import 'package:ag_showcase_blog/core/endpoints.dart';
import 'package:ag_showcase_blog/modules/post/models/post.dart';

class PostsService extends AgBaseService {
  PostsService(super.apiProvider);

  Future<AgListPage<Post, int>> getPage(int pageKey) async {
    final response = await send<List<dynamic>>(
      AgRequest(
        endpoint: PostEndpoints.posts,
        queryParams: {'_page': '$pageKey', '_limit': '10'},
      ),
      decode: (json) => json as List<dynamic>,
    );
    final items = response.data
        .map((j) => Post.fromJson(j as Map<String, dynamic>))
        .toList();
    return AgListPage(
      items: items,
      hasMore: items.length == 10,
      nextPageKey: pageKey + 1,
    );
  }

  Future<Post> add(Post item) async {
    final response = await send<Map<String, dynamic>>(
      AgRequest(
        endpoint: PostEndpoints.posts,
        method: AgHttpMethod.post,
        body: item.toJson(),
      ),
      decode: (json) => json as Map<String, dynamic>,
    );
    return Post.fromJson(response.data);
  }

  Future<void> delete(int id) async {
    await send<void>(
      AgRequest(
        endpoint: PostEndpoints.postById,
        method: AgHttpMethod.delete,
        pathParams: {'id': '$id'},
      ),
    );
  }
}
