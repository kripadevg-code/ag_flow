import 'package:ag_flow/src/controller/ag_pagination_state.dart';
import 'package:ag_flow/src/network/ag_endpoint.dart';
import 'package:ag_flow/src/network/ag_request.dart';
import 'package:ag_flow/src/service/ag_base_service.dart';
import 'package:ag_flow/src/service/ag_page_strategy.dart';

/// Gives a Service the `getPage` that `AgListController.fetchPage` needs,
/// implemented once by the framework rather than hand-written per module.
///
/// This is the piece whose absence used to break consistency: with no
/// framework-owned paging, every paginated collection dropped out of the
/// declarative Service shape and hand-rolled its own query parameters,
/// decoding, and `hasMore` arithmetic — so no two modules looked alike,
/// and each one silently encoded its backend's quirks in imperative code.
///
/// Backend differences are absorbed by two declared values instead:
/// [pageStrategy] (paging dialect) and [envelope] (where the payload sits
/// in the response). A Service using this mixin contains no request
/// plumbing at all:
///
/// ```dart
/// class PostsService extends AgBaseService
///     with AgCrudService<Post, int>, AgPagedService<Post, int> {
///   PostsService(super.apiProvider);
///
///   @override
///   AgEndpoint get collectionEndpoint => PostEndpoints.posts;
///   @override
///   AgEndpoint get resourceEndpoint => PostEndpoints.postById;
///   @override
///   AgPageStrategy<int> get pageStrategy =>
///       const AgPageNumberStrategy(pageParam: '_page', sizeParam: '_limit');
///   @override
///   Post fromJson(Map<String, dynamic> json) => Post.fromJson(json);
///   @override
///   Map<String, dynamic> toJson(Post item) => item.toJson();
/// }
/// ```
///
/// Composes with `AgCrudService` — both declare [collectionEndpoint] and
/// [fromJson], which the class satisfies once. Use this alone for a
/// read-only paginated list, `AgCrudService` alone for a resource that
/// isn't a list, or both together for the usual collection module.
mixin AgPagedService<T, PageKeyType extends Object> on AgBaseService {
  /// The collection endpoint pages are read from — no path parameters.
  AgEndpoint get collectionEndpoint;

  /// Decodes a single item.
  T fromJson(Map<String, dynamic> json);

  /// How this backend paginates.
  AgPageStrategy<PageKeyType> get pageStrategy;

  /// Extra query parameters sent with every page request — a category
  /// filter, a search term, a sort order. Merged with (and overridden by)
  /// whatever [pageStrategy] contributes.
  Map<String, dynamic> get pageQueryParams => const {};

  /// Fetches one page. Wire this straight into
  /// `AgListController.fetchPage`.
  Future<AgListPage<T, PageKeyType>> getPage(PageKeyType pageKey) async {
    final response = await send<Object?>(
      AgRequest(
        endpoint: collectionEndpoint,
        queryParams: {
          ...pageQueryParams,
          ...pageStrategy.queryParamsFor(pageKey),
        },
      ),
      decode: (json) => json,
    );

    final body = response.data;
    final items = decodeListPayload<T>(body, fromJson);
    final next = pageStrategy.nextAfter(
      requestedKey: pageKey,
      body: body,
      envelope: envelope,
      itemCount: items.length,
    );

    return AgListPage<T, PageKeyType>(
      items: items,
      hasMore: next.hasMore,
      nextPageKey: next.nextPageKey,
    );
  }
}
