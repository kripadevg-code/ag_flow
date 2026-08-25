import 'package:ag_flow/src/service/ag_envelope.dart';
import 'package:flutter/foundation.dart';

/// What comes after the page that was just fetched.
@immutable
class AgNextPage<PageKeyType extends Object> {
  const AgNextPage({required this.hasMore, this.nextPageKey});

  /// Whether another page exists after this one.
  final bool hasMore;

  /// The key to request that next page with. Null when [hasMore] is
  /// false.
  final PageKeyType? nextPageKey;
}

/// How a backend expresses pagination — the query parameters a page key
/// becomes, and how to tell what comes next.
///
/// Every backend paginates differently (page numbers, offsets, opaque
/// cursors, or not at all), and before this existed, that difference
/// forced developers off AG's declarative Service shape and into
/// hand-written query params, decoding, and `hasMore` arithmetic — which
/// is precisely where consistency between modules died. A strategy is a
/// value you *declare*; the paging itself stays framework-owned.
///
/// Pick one of the four built-ins — [AgPageNumberStrategy],
/// [AgOffsetStrategy], [AgCursorStrategy], [AgSinglePageStrategy] — or
/// subclass this for a backend none of them describe.
abstract class AgPageStrategy<PageKeyType extends Object> {
  const AgPageStrategy();

  /// The page key used for the very first page.
  PageKeyType get initialPageKey;

  /// The query parameters that request [pageKey].
  Map<String, dynamic> queryParamsFor(PageKeyType pageKey);

  /// Given the page just received, decide what comes next.
  ///
  /// [body] is the raw decoded response and [envelope] the one that
  /// unwrapped it — together they let a cursor-style strategy read a
  /// `nextCursor` token that sits *beside* the payload rather than in it.
  AgNextPage<PageKeyType> nextAfter({
    required PageKeyType requestedKey,
    required Object? body,
    required AgEnvelope envelope,
    required int itemCount,
  });
}

/// Page-number paging: `?page=1&limit=20` — the most common REST shape.
///
/// "Has more" is inferred from a full page arriving; a short page means
/// the end. That's the standard heuristic when a backend reports no
/// total. If yours does, subclass [AgPageStrategy] and read it.
class AgPageNumberStrategy extends AgPageStrategy<int> {
  const AgPageNumberStrategy({
    this.pageParam = 'page',
    this.sizeParam = 'limit',
    this.pageSize = 20,
    this.firstPage = 1,
  });

  final String pageParam;
  final String sizeParam;
  final int pageSize;
  final int firstPage;

  @override
  int get initialPageKey => firstPage;

  @override
  Map<String, dynamic> queryParamsFor(int pageKey) => {
    pageParam: '$pageKey',
    sizeParam: '$pageSize',
  };

  @override
  AgNextPage<int> nextAfter({
    required int requestedKey,
    required Object? body,
    required AgEnvelope envelope,
    required int itemCount,
  }) {
    final hasMore = itemCount >= pageSize;
    return AgNextPage(
      hasMore: hasMore,
      nextPageKey: hasMore ? requestedKey + 1 : null,
    );
  }
}

/// Offset/limit paging: `?offset=0&limit=20`. The page key is the offset,
/// advancing by [pageSize].
class AgOffsetStrategy extends AgPageStrategy<int> {
  const AgOffsetStrategy({
    this.offsetParam = 'offset',
    this.limitParam = 'limit',
    this.pageSize = 20,
  });

  final String offsetParam;
  final String limitParam;
  final int pageSize;

  @override
  int get initialPageKey => 0;

  @override
  Map<String, dynamic> queryParamsFor(int pageKey) => {
    offsetParam: '$pageKey',
    limitParam: '$pageSize',
  };

  @override
  AgNextPage<int> nextAfter({
    required int requestedKey,
    required Object? body,
    required AgEnvelope envelope,
    required int itemCount,
  }) {
    final hasMore = itemCount >= pageSize;
    return AgNextPage(
      hasMore: hasMore,
      nextPageKey: hasMore ? requestedKey + pageSize : null,
    );
  }
}

/// Cursor/token paging: the backend returns an opaque token for the next
/// page, read from [nextTokenKey] beside the payload.
///
/// The first page is requested with no cursor parameter at all, which is
/// what [initialPageKey]'s empty string means.
class AgCursorStrategy extends AgPageStrategy<String> {
  const AgCursorStrategy({
    this.cursorParam = 'cursor',
    this.nextTokenKey = 'next',
    this.sizeParam,
    this.pageSize,
  });

  final String cursorParam;
  final String nextTokenKey;
  final String? sizeParam;
  final int? pageSize;

  @override
  String get initialPageKey => '';

  @override
  Map<String, dynamic> queryParamsFor(String pageKey) => {
    if (pageKey.isNotEmpty) cursorParam: pageKey,
    if (sizeParam != null && pageSize != null) sizeParam!: '$pageSize',
  };

  @override
  AgNextPage<String> nextAfter({
    required String requestedKey,
    required Object? body,
    required AgEnvelope envelope,
    required int itemCount,
  }) {
    final token = envelope.metaOf(body, nextTokenKey);
    final next = token is String && token.isNotEmpty ? token : null;
    return AgNextPage(hasMore: next != null, nextPageKey: next);
  }
}

/// The backend returns the entire collection in one response and does not
/// paginate. Sends no paging query parameters and always reports "no more
/// pages".
///
/// A first-class case rather than something each developer hand-codes: it
/// keeps a non-paginating backend on the exact same Service shape as a
/// paginating one, which is the entire point of these strategies.
class AgSinglePageStrategy extends AgPageStrategy<int> {
  const AgSinglePageStrategy();

  @override
  int get initialPageKey => 1;

  @override
  Map<String, dynamic> queryParamsFor(int pageKey) => const {};

  @override
  AgNextPage<int> nextAfter({
    required int requestedKey,
    required Object? body,
    required AgEnvelope envelope,
    required int itemCount,
  }) => const AgNextPage(hasMore: false);
}
