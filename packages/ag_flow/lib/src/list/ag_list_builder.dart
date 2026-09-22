import 'dart:async';
import 'dart:math' as math;

import 'package:ag_flow/src/controller/ag_list_controller.dart';
import 'package:ag_flow/src/controller/ag_pagination_state.dart';
import 'package:ag_flow/src/state/ag_builder.dart';
import 'package:flutter/material.dart';

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

  /// How close to the bottom (in pixels) triggers a load of the next
  /// page via [AgListController.loadMore].
  final double loadMoreThreshold;

  final EdgeInsetsGeometry? padding;
  final ScrollPhysics? physics;

  bool _onScrollNotification(ScrollNotification notification) {
    // Only this list's own scrollable. A nested scrollable (a horizontal
    // carousel inside a row, say) bubbles *its* metrics up to this
    // listener, and a short inner list always reads as "near the
    // bottom" — which would load page after page of the outer list
    // while the user scrolls something else entirely.
    if (notification.depth != 0) return false;

    // Scroll position only changes on these; start//end-of-drag and
    // user-scroll notifications carry no new offset to act on.
    if (notification is! ScrollUpdateNotification &&
        notification is! OverscrollNotification) {
      return false;
    }

    // Checked here, synchronously, rather than relying on loadMore()'s
    // own guard: this runs on every scroll frame, and an async call
    // allocates a Future each time even when it returns immediately.
    final pagination = controller.pagination;
    if (!pagination.hasNextPage || pagination.isLoadingMore) return false;

    // A failed page must not retry itself. Without this, a backend that
    // is erroring gets hammered once per scroll frame for as long as the
    // user keeps moving; recovery is `retryLoadMore()`, from the
    // load-more error slot, which is a deliberate user action.
    if (pagination.loadMoreError != null) return false;

    final metrics = notification.metrics;
    if (metrics.maxScrollExtent - metrics.pixels > loadMoreThreshold) {
      return false;
    }

    unawaited(controller.loadMore());
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return AgBuilder(
      listenable: controller.paginationListenable,
      builder: (context) {
        final pagination = controller.pagination;
        final items = pagination.items;
        // The list is exhausted (no error, not loading) only ever needs a
        // trailing slot if the caller actually wants something shown
        // there — otherwise reserving an empty slot just to render
        // SizedBox.shrink() would be pointless.
        final isExhaustedWithCustomEnding =
            !pagination.hasNextPage &&
            !pagination.isLoadingMore &&
            pagination.loadMoreError == null &&
            noMoreItemsBuilder != null;
        final hasTrailing =
            pagination.hasNextPage ||
            pagination.isLoadingMore ||
            pagination.loadMoreError != null ||
            isExhaustedWithCustomEnding;
        final itemCount = items.length + (hasTrailing ? 1 : 0);

        Widget itemAt(BuildContext context, int index) {
          if (index < items.length) {
            return itemBuilder(context, items[index], index);
          }
          return _buildTrailing(context, pagination);
        }

        // Built on CustomScrollView + SliverList (rather than ListView)
        // so this becomes composable inside a larger sliver-based scroll
        // view later without changing this widget's own external API.
        // Separator interleaving mirrors ListView.separated's own
        // technique exactly: double the child count, even indices are
        // items, odd indices are separators.
        final Widget sliver;
        final separator = separatorBuilder;
        if (separator == null) {
          sliver = SliverList(
            delegate: SliverChildBuilderDelegate(itemAt, childCount: itemCount),
          );
        } else {
          sliver = SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final itemIndex = index ~/ 2;
              return index.isEven
                  ? itemAt(context, itemIndex)
                  : separator(context, itemIndex);
            }, childCount: math.max(0, itemCount * 2 - 1)),
          );
        }

        final padding = this.padding;
        return NotificationListener<ScrollNotification>(
          onNotification: _onScrollNotification,
          child: CustomScrollView(
            physics: physics,
            slivers: [
              if (padding == null)
                sliver
              else
                SliverPadding(padding: padding, sliver: sliver),
            ],
          ),
        );
      },
    );
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
