import 'package:meta/meta.dart';

/// The kind of structural problem an [AnalyzeIssue] reports.
///
/// The first five are v1 (mechanical/structural, syntax-only) checks. The
/// last two — [dependencyDirection] and [unusedDetailArgument] — need a
/// *resolved* element model (`AnalysisContextCollection`, not just
/// `parseString`) and only run when the target project's dependencies
/// have already been resolved; see `ag_flow_cli/README.md`.
enum AnalyzeCategory {
  missingLayerFile,
  missingRouteWiring,
  duplicateRoute,
  nestedFolder,
  hardcodedRoute,
  dependencyDirection,
  unusedDetailArgument,
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
  /// (e.g. `lib/modules/product/controllers/products_controller.dart`).
  final String file;

  @override
  String toString() => '$file: $message';
}
