import 'package:ag_flow/src/controller/ag_base_controller.dart';
import 'package:ag_flow/src/page/ag_page_state.dart';
import 'package:ag_flow/src/widgets/ag_empty.dart';
import 'package:ag_flow/src/widgets/ag_error.dart';
import 'package:ag_flow/src/widgets/ag_loading.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Composes a page (or a section of one) from an [AgBaseController]'s
/// [AgPageState].
///
/// Every state except success has an AG default and may be independently
/// overridden — supplying only [errorBuilder], for example, does not
/// require also supplying [loadingBuilder] or [emptyBuilder].
class AgPage<T> extends StatelessWidget {
  const AgPage({
    required this.controller,
    required this.builder,
    super.key,
    this.loadingBuilder,
    this.errorBuilder,
    this.emptyBuilder,
    this.onRefresh,
  });

  /// The controller driving this page's state.
  final AgBaseController<T> controller;

  /// Builds the success-state content. The only required slot — AG has no
  /// sensible default for "your actual screen content".
  final Widget Function(BuildContext context, T data) builder;

  /// Overrides the default [AgLoading]. Null = AG default.
  final WidgetBuilder? loadingBuilder;

  /// Overrides the default [AgError]. Null = AG default.
  final Widget Function(
    BuildContext context,
    Object error,
    StackTrace? stackTrace,
    VoidCallback retry,
  )?
  errorBuilder;

  /// Overrides the default [AgEmpty]. Null = AG default.
  final WidgetBuilder? emptyBuilder;

  /// When supplied, wraps success content in a [RefreshIndicator] that
  /// calls this on pull-to-refresh.
  final Future<void> Function()? onRefresh;

  @override
  Widget build(BuildContext context) {
    return GetBuilder<AgBaseController<T>>(
      init: controller,
      global: false,
      // A Binding owns this controller's lifecycle (created via
      // Get.lazyPut, disposed when the route itself is popped) — this
      // widget merely reads it. With global:false, GetBuilder otherwise
      // defaults to deleting it from Get's DI container on its own
      // dispose, which must never happen just because one of possibly
      // several widgets reading the same controller unmounted first.
      autoRemove: false,
      id: AgBaseController.pageStateUpdateId,
      builder: (controller) {
        final currentState = controller.state;
        return switch (currentState) {
          AgPageInitial<T>() || AgPageLoading<T>() =>
            loadingBuilder?.call(context) ?? const AgLoading(),
          AgPageError<T>(:final error, :final stackTrace) =>
            errorBuilder?.call(context, error, stackTrace, controller.retry) ??
                AgError(
                  error: error,
                  stackTrace: stackTrace,
                  onRetry: controller.retry,
                ),
          AgPageEmpty<T>() => emptyBuilder?.call(context) ?? const AgEmpty(),
          AgPageSuccess<T>(:final data, :final isRefreshing) => _buildSuccess(
            context,
            data,
            isRefreshing,
          ),
        };
      },
    );
  }

  Widget _buildSuccess(BuildContext context, T data, bool isRefreshing) {
    var content = builder(context, data);
    if (isRefreshing) {
      content = Stack(
        children: [
          content,
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: LinearProgressIndicator(minHeight: 2),
          ),
        ],
      );
    }
    final refresh = onRefresh;
    if (refresh == null) return content;
    return RefreshIndicator(onRefresh: refresh, child: content);
  }
}
