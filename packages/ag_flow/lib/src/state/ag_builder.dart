import 'package:flutter/widgets.dart';

/// Rebuilds [builder] whenever [listenable] notifies.
///
/// AG's own, consistently-named wrapper around Flutter's built-in
/// [ListenableBuilder] — used internally by `AgPage`/`AgListBuilder`, and
/// exported for any custom AG-style page that wants the same pattern
/// against its own controller or notifier.
class AgBuilder extends StatelessWidget {
  const AgBuilder({required this.listenable, required this.builder, super.key});

  /// What to listen to. Typically an `AgBaseController` itself (for
  /// page-state rebuilds) or an `AgNotifier` (for a separate, narrower
  /// rebuild scope, e.g. `AgPaginationMixin.paginationListenable`).
  final Listenable listenable;

  /// Rebuilt on every notification from [listenable].
  final WidgetBuilder builder;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: listenable,
      builder: (context, _) => builder(context),
    );
  }
}
