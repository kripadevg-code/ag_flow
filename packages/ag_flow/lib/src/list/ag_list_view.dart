import 'dart:async';
import 'dart:math' as math;

import 'package:ag_flow/src/controller/ag_base_controller.dart';
import 'package:ag_flow/src/page/ag_page_state.dart';
import 'package:ag_flow/src/state/ag_builder.dart';
import 'package:flutter/material.dart';

/// A scrollable list of a controller's items.
///
/// Works with any `AgBaseController<List<T>>`. When the controller also
/// mixes in [AgLoadMore], scrolling near the end loads the next page and a
/// footer shows its progress; otherwise this is a plain list. The page
/// code is the same either way.
///
/// Internally a `CustomScrollView` + `SliverList` rather than a `ListView`,
/// so it can later compose inside a larger sliver-based scroll view without
/// an API change. Doesn't own the controller's lifecycle — an `AgBinding`
/// does — so it never disposes it.
class AgListView<T> extends StatelessWidget {
  const AgListView({
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

  /// The controller whose `state` holds the items.
  final AgBaseController<List<T>> controller;

  /// Builds the row for [item] at [index].
  final Widget Function(BuildContext context, T item, int index) itemBuilder;

  /// Builds the separator after the item at the given index, if any.
  final IndexedWidgetBuilder? separatorBuilder;

  /// The footer while a page is loading. Defaults to a small spinner.
  final WidgetBuilder? loadMoreBuilder;

  /// The footer after a page failed; `retry` loads it again.
  final Widget Function(BuildContext context, Object error, VoidCallback retry)?
  loadMoreErrorBuilder;

  /// The footer once every page is loaded. Defaults to nothing.
  final WidgetBuilder? noMoreItemsBuilder;

  /// How close to the end, in pixels, scrolling triggers the next page.
  final double loadMoreThreshold;

  /// Padding around the items.
  final EdgeInsetsGeometry? padding;

  /// The scroll physics.
  final ScrollPhysics? physics;

  AgLoadMore<T>? get _pager {
    final controller = this.controller;
    return controller is AgLoadMore<T> ? controller : null;
  }

  bool _onScrollNotification(ScrollNotification notification) {
    final pager = _pager;
    if (pager == null) return false;

    // Only this list's own scrollable. A nested scrollable (a horizontal
    // carousel inside a row, say) bubbles *its* metrics up to this
    // listener, and a short inner list always reads as "near the
    // bottom" — which would load page after page of the outer list
    // while the user scrolls something else entirely.
    if (notification.depth != 0) return false;

    // Scroll position only changes on these; start/end-of-drag and
    // user-scroll notifications carry no new offset to act on.
    if (notification is! ScrollUpdateNotification &&
        notification is! OverscrollNotification) {
      return false;
    }

    // Checked here, synchronously, rather than relying on loadMore()'s
    // own guard: this runs on every scroll frame, and an async call
    // allocates a Future each time even when it returns immediately.
    if (!pager.hasMore || pager.isLoadingMore) return false;

    // A failed page must not retry itself. Without this, a backend that
    // is erroring gets hammered once per scroll frame for as long as the
    // user keeps moving; recovery is the retry in the error footer, a
    // deliberate user action.
    if (pager.loadMoreError != null) return false;

    final metrics = notification.metrics;
    if (metrics.maxScrollExtent - metrics.pixels > loadMoreThreshold) {
      return false;
    }

    unawaited(pager.loadMore());
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return AgBuilder(
      listenable: controller,
      builder: (context) {
        final items = controller.state.dataOrNull ?? const [];
        final pager = _pager;
        final footer = pager == null ? null : _buildFooter(context, pager);
        final itemCount = items.length + (footer == null ? 0 : 1);

        Widget itemAt(BuildContext context, int index) {
          if (index < items.length) {
            return itemBuilder(context, items[index], index);
          }
          return footer!;
        }

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

  /// The trailing slot, or null when nothing should be reserved for it.
  Widget? _buildFooter(BuildContext context, AgLoadMore<T> pager) {
    final error = pager.loadMoreError;
    if (error != null) {
      return loadMoreErrorBuilder?.call(context, error, pager.loadMore) ??
          _DefaultLoadMoreError(error: error, onRetry: pager.loadMore);
    }
    if (pager.isLoadingMore) {
      return loadMoreBuilder?.call(context) ??
          const _DefaultLoadMoreIndicator();
    }
    if (pager.hasMore) return const SizedBox.shrink();
    return noMoreItemsBuilder?.call(context);
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
