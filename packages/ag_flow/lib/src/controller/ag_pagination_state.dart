import 'package:flutter/foundation.dart';

/// One page of items returned by `AgPaginationMixin.fetchPage`.
@immutable
class AgListPage<ItemType, PageKeyType> {
  const AgListPage({
    required this.items,
    required this.hasMore,
    this.nextPageKey,
  });

  /// The items in this page.
  final List<ItemType> items;

  /// Whether another page exists after this one.
  final bool hasMore;

  /// The key to request the next page with. May be null when [hasMore] is
  /// false.
  final PageKeyType? nextPageKey;
}

/// Pagination/load-more state owned by `AgPaginationMixin`.
///
/// Deliberately separate from the page-level `AgPageState`: a failure
/// while loading more items (see [loadMoreError]) must never be conflated
/// with a page-level error for the initial load.
@immutable
class AgPaginationState<ItemType, PageKeyType extends Object> {
  const AgPaginationState({
    this.items = const [],
    this.nextPageKey,
    this.hasNextPage = true,
    this.isLoadingMore = false,
    this.loadMoreError,
  });

  final List<ItemType> items;
  final PageKeyType? nextPageKey;
  final bool hasNextPage;
  final bool isLoadingMore;
  final Object? loadMoreError;

  AgPaginationState<ItemType, PageKeyType> copyWith({
    List<ItemType>? items,
    PageKeyType? nextPageKey,
    bool clearNextPageKey = false,
    bool? hasNextPage,
    bool? isLoadingMore,
    Object? loadMoreError,
    bool clearLoadMoreError = false,
  }) {
    return AgPaginationState<ItemType, PageKeyType>(
      items: items ?? this.items,
      nextPageKey: clearNextPageKey ? null : (nextPageKey ?? this.nextPageKey),
      hasNextPage: hasNextPage ?? this.hasNextPage,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      loadMoreError: clearLoadMoreError
          ? null
          : (loadMoreError ?? this.loadMoreError),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is AgPaginationState<ItemType, PageKeyType> &&
      listEquals(other.items, items) &&
      other.nextPageKey == nextPageKey &&
      other.hasNextPage == hasNextPage &&
      other.isLoadingMore == isLoadingMore &&
      other.loadMoreError == loadMoreError;

  @override
  int get hashCode => Object.hash(
    Object.hashAll(items),
    nextPageKey,
    hasNextPage,
    isLoadingMore,
    loadMoreError,
  );

  @override
  String toString() =>
      'AgPaginationState(items: ${items.length}, hasNextPage: $hasNextPage, '
      'isLoadingMore: $isLoadingMore, loadMoreError: $loadMoreError)';
}
