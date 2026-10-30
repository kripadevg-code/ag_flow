import 'package:ag_flow/ag_flow.dart';
import 'package:ag_showcase_blog/core/arguments/arguments.dart';
import 'package:ag_showcase_blog/core/bindings/initial_binding.dart';
import 'package:ag_showcase_blog/core/routes/route_management.dart';
import 'package:ag_showcase_blog/main.dart';
import 'package:ag_showcase_blog/modules/post/controllers/post_details_comments_controller.dart';
import 'package:ag_showcase_blog/modules/post/controllers/post_details_controller.dart';
import 'package:ag_showcase_blog/modules/post/controllers/posts_controller.dart';
import 'package:ag_showcase_blog/modules/post/models/post.dart';
import 'package:flutter_test/flutter_test.dart';

/// Serves every request from memory — no network — with objects carrying
/// every field this app's models read, and records `METHOD path`.
class FakeApi implements ApiProvider {
  final List<String> calls = [];

  static Map<String, dynamic> item(int id) => {
    'id': id,
    'userId': 1,
    'postId': 1,
    'title': 'Item $id',
    'body': 'body',
    'name': 'name',
    'email': 'a@b.c',
    'completed': false,
    'category': 'tools',
    'description': 'd',
    'image': '',
    'price': 10,
    'rating': {'rate': 4, 'count': 1},
  };

  @override
  Future<AgResponse<D>> send<D>(
    AgRequest request, {
    D Function(Object? json)? decode,
    AgCancelToken? cancelToken,
    void Function(int, int)? onSendProgress,
    void Function(int, int)? onReceiveProgress,
  }) async {
    final path = request.resolvePath();
    calls.add('${request.method.name} $path');
    final Object? json;
    if (request.method == AgHttpMethod.delete) {
      json = <String, dynamic>{};
    } else if (path.endsWith('/categories')) {
      json = ['tools', 'toys'];
    } else if (request.method == AgHttpMethod.post) {
      json = item(99); // a newly created resource gets a new id
    } else if (request.method != AgHttpMethod.get ||
        RegExp(r'/\d+$').hasMatch(path)) {
      json = item(1);
    } else {
      json = [for (var i = 1; i <= 3; i++) item(i)];
    }
    return AgResponse<D>(
      statusCode: 200,
      data: decode != null ? decode(json) : json as D,
      headers: const {},
      duration: Duration.zero,
    );
  }
}

void main() {
  testWidgets('posts → details (update, comments) → back, offline', (
    tester,
  ) async {
    final api = FakeApi();
    InitialBinding().dependencies();
    AgLocator.put<ApiProvider>(api, permanent: true);

    await tester.pumpWidget(const BlogShowcaseApp());
    await tester.pumpAndSettle();
    final posts = AgLocator.find<PostsController>();
    expect(posts.state.dataOrNull, hasLength(3));
    expect(find.text('Item 1'), findsWidgets);

    RouteManagement.goToPostDetailsPage(
      const PostDetailsPageArgument(postId: 1),
    );
    await tester.pumpAndSettle();
    final details = AgLocator.find<PostDetailsController>();
    expect(details.lookupId, 1);
    expect(details.state, isA<AgPageSuccess<Post>>());

    await details.update(Post.fromJson(FakeApi.item(1)));
    RouteManagement.goToPostDetailsCommentsPage(
      const PostDetailsCommentsPageArgument(postId: 1),
    );
    await tester.pumpAndSettle();
    expect(
      AgLocator.find<PostDetailsCommentsController>().state,
      isA<AgPageSuccess<dynamic>>(),
    );

    RouteManagement.back();
    await tester.pumpAndSettle();
    RouteManagement.back();
    await tester.pumpAndSettle();
    expect(AgLocator.find<PostDetailsController>, throwsStateError);

    expect(api.calls, contains('GET /posts/1'));
    expect(api.calls, contains('PUT /posts/1'));
    expect(api.calls, contains('GET /posts/1/comments'));
  });
}
