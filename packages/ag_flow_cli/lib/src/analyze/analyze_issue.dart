import 'package:meta/meta.dart';

/// The kind of structural problem an [AnalyzeIssue] reports.
///
/// This is the v1 (mechanical/structural) scope only — see
/// `ag_flow_cli/README.md` for what's deliberately deferred to v2+
/// (dependency-direction violations, detail-route-without-argument checks)
/// and why: both need a resolved element model via `analyzer`, not just
/// syntax, and are prone to false positives if rushed.
enum AnalyzeCategory {
  missingLayerFile,
  missingRouteWiring,
  duplicateRoute,
  nestedFolder,
  hardcodedRoute,
}

/// A single structural problem `ag analyze` found in a project.
@immutable
class AnalyzeIssue {
  const AnalyzeIssue({
    required this.category,
    required this.message,
    required this.file,
  });

  final AnalyzeCategory category;

  /// A human-readable description of the problem.
  final String message;

  /// The file this issue is anchored to, relative to the project root
  /// (e.g. `lib/product/controllers/products_controller.dart`).
  final String file;

  @override
  String toString() => '$file: $message';
}
