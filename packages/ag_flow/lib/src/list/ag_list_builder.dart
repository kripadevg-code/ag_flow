import 'dart:async';

import 'package:ag_flow/src/controller/ag_list_controller.dart';
import 'package:ag_flow/src/controller/ag_pagination_state.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Renders a collection driven by an [AgListController]: item rendering,
/// scrolling, and load-more.
///
/// Deliberately does not expose page-level loading/error/empty slots —
/// those belong to `AgPage`/`AgBasePage`. This widget only ever renders
/// once the page is already in its success state, and only ever owns
/// "how is this collection rendered and continued", never "what state is
/// this page in".
class AgListBuilder<ItemType, PageKeyType extends Object>
    extends StatelessWidget {
  const AgListBuilder({
    required this.controller,
    required this.itemBuilder,
    super.key,
    this.separatorBuilder,
    this.loadMoreBuilder,
    this.loadMoreErrorBuilder,
    this.noMoreItemsBuilder,
    this.loadMoreThreshold = 300.0,
    this.padding,
    this.physics,
  });

  /// The controller whose [AgListController.pagination] drives this
  /// widget.
  final AgListController<ItemType, PageKeyType> controller;

  /// Builds one item.
  final Widget Function(BuildContext context, ItemType item, int index)
  itemBuilder;

  /// Builds the separator between items. Null = no separator.
  final IndexedWidgetBuilder? separatorBuilder;

  /// Overrides the default load-more indicator. Null = AG default.
  final WidgetBuilder? loadMoreBuilder;

  /// Overrides the default load-more error/retry UI. Null = AG default.
  final Widget Function(BuildContext context, Object error, VoidCallback retry)?
  loadMoreErrorBuilder;

  /// Overrides the default "no more items" trailing widget (shown when
  /// the list is exhausted). Null = AG default (nothing).
  final WidgetBuilder? noMoreItemsBuilder;

  /// How close to the bottom (in pixels) triggers [AgListController
  /// .loadMore].
  final double loadMoreThreshold;

  final EdgeInsetsGeometry? padding;
  final ScrollPhysics? physics;

  bool _onScrollNotification(ScrollNotification notification) {
    final metrics = notification.metrics;
    final remaining = metrics.maxScrollExtent - metrics.pixels;
    if (remaining <= loadMoreThreshold) {
      unawaited(controller.loadMore());
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final pagination = controller.pagination;
      final items = pagination.items;
      final hasTrailing =
          pagination.hasNextPage ||
          pagination.isLoadingMore ||
          pagination.loadMoreError != null;
      final itemCount = items.length + (hasTrailing ? 1 : 0);

      Widget itemAt(BuildContext context, int index) {
        if (index < items.length) {
          return itemBuilder(context, items[index], index);
        }
        return _buildTrailing(context, pagination);
      }

      final list = separatorBuilder == null
          ? ListView.builder(
              padding: padding,
              physics: physics,
              itemCount: itemCount,
              itemBuilder: itemAt,
            )
          : ListView.separated(
              padding: padding,
              physics: physics,
              itemCount: itemCount,
              itemBuilder: itemAt,
              separatorBuilder: separatorBuilder!,
            );

      return NotificationListener<ScrollNotification>(
        onNotification: _onScrollNotification,
        child: list,
      );
    });
  }

  Widget _buildTrailing(
    BuildContext context,
    AgPaginationState<ItemType, PageKeyType> pagination,
  ) {
    final error = pagination.loadMoreError;
    if (error != null) {
      return loadMoreErrorBuilder?.call(
            context,
            error,
            controller.retryLoadMore,
          ) ??
          _DefaultLoadMoreError(
            error: error,
            onRetry: controller.retryLoadMore,
          );
    }
    if (pagination.isLoadingMore) {
      return loadMoreBuilder?.call(context) ??
          const _DefaultLoadMoreIndicator();
    }
    if (!pagination.hasNextPage) {
      return noMoreItemsBuilder?.call(context) ?? const SizedBox.shrink();
    }
    return const SizedBox.shrink();
  }
}

class _DefaultLoadMoreIndicator extends StatelessWidget {
  const _DefaultLoadMoreIndicator();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }
}

class _DefaultLoadMoreError extends StatelessWidget {
  const _DefaultLoadMoreError({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Failed to load more: $error', textAlign: TextAlign.center),
            const SizedBox(height: 8),
            OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
