import 'package:ag_flow/src/controller/ag_base_controller.dart';
import 'package:ag_flow/src/page/ag_page.dart';
import 'package:ag_flow/src/widgets/ag_empty.dart';
import 'package:ag_flow/src/widgets/ag_error.dart';
import 'package:ag_flow/src/widgets/ag_loading.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Base class for a full-screen AG page.
///
/// Works for both collection and detail modules: `C` already carries all
/// the type information AG needs, including navigation arguments for
/// detail pages (see `AgDetailController.arguments`) — there is no
/// separate "detail" variant of this class, and no argument type to state
/// a second time on the page itself.
///
/// Subclasses provide [buildSuccess] and may independently override
/// [loadingBuilder], [errorBuilder], and [emptyBuilder]; anything left
/// null falls back to the AG default.
abstract class AgBasePage<C extends AgBaseController<dynamic>>
    extends GetView<C> {
  const AgBasePage({super.key});

  /// Whether this page wraps its content in a [Scaffold]. Set to false to
  /// embed this page's content inside another Scaffold (e.g. as tab
  /// content).
  bool get useScaffold => true;

  /// The app bar to use when [useScaffold] is true. Null = no app bar.
  PreferredSizeWidget? appBar(BuildContext context) => null;

  /// The floating action button to use when [useScaffold] is true.
  Widget? floatingActionButton(BuildContext context) => null;

  /// Whether pulling down on the success content triggers [onRefresh].
  bool get enablePullToRefresh => true;

  /// Overrides the default [AgLoading]. Null = AG default.
  WidgetBuilder? get loadingBuilder => null;

  /// Overrides the default [AgError]. Null = AG default.
  Widget Function(
    BuildContext context,
    Object error,
    StackTrace? stackTrace,
    VoidCallback retry,
  )?
  get errorBuilder => null;

  /// Overrides the default [AgEmpty]. Null = AG default.
  WidgetBuilder? get emptyBuilder => null;

  /// Called on pull-to-refresh, when [enablePullToRefresh] is true.
  /// Defaults to [AgBaseController.refresh].
  Future<void> onRefresh() => controller.refresh();

  /// Builds this page's content for the success state. Read `controller
  /// .state`/`controller.pagination` directly rather than receiving data
  /// as a parameter — `controller` is already available via [GetView].
  Widget buildSuccess(BuildContext context);

  @override
  Widget build(BuildContext context) {
    final page = AgPage<dynamic>(
      controller: controller,
      loadingBuilder: loadingBuilder,
      errorBuilder: errorBuilder,
      emptyBuilder: emptyBuilder,
      onRefresh: enablePullToRefresh ? onRefresh : null,
      builder: (context, _) => buildSuccess(context),
    );

    if (!useScaffold) return page;

    return Scaffold(
      appBar: appBar(context),
      floatingActionButton: floatingActionButton(context),
      body: page,
    );
  }
}
