import 'dart:io';

import 'package:ag_flow_cli/src/analyze/analyze_issue.dart';
import 'package:ag_flow_cli/src/analyze/dependency_direction_check.dart';
import 'package:ag_flow_cli/src/analyze/detail_argument_usage_check.dart';
import 'package:ag_flow_cli/src/analyze/duplicate_route_check.dart';
import 'package:ag_flow_cli/src/analyze/hardcoded_route_check.dart';
import 'package:ag_flow_cli/src/analyze/route_table.dart';
import 'package:ag_flow_cli/src/analyze/route_wiring_check.dart';
import 'package:ag_flow_cli/src/analyze/structure_check.dart';
import 'package:ag_flow_cli/src/io/project.dart';
import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:package_config/package_config.dart';
import 'package:path/path.dart' as p;

/// Thrown when `lib/core/routes/app_routes.dart` doesn't exist — the
/// project hasn't run `ag init` yet, so there's nothing to analyze.
class ProjectNotInitializedException implements Exception {
  const ProjectNotInitializedException();

  @override
  String toString() =>
      'ERROR: lib/core/routes/app_routes.dart does not exist.\n\n'
      'Run "ag init" first.';
}

/// `ag analyze`'s validator: checks a project generated (or hand-
/// maintained) against AG's structural rules — see `AnalyzeCategory` for
/// exactly which checks exist. The first five categories are syntax-only
/// (`parseString`, no dependency resolution needed at all); the last two
/// ([AnalyzeCategory.dependencyDirection],
/// [AnalyzeCategory.unusedDetailArgument]) need a resolved element model
/// and only run when [dependenciesResolved] is true — callers should
/// surface that as a non-fatal notice, not an error, since every other
/// check still runs and is still meaningful without it.
class ProjectAnalyzer {
  const ProjectAnalyzer({required this.project});

  final Project project;

  /// Whether `dart pub get` (or `flutter pub get`) has been run — the two
  /// resolved-model checks need a resolved `package_config.json` so
  /// `ag_flow`'s own types (e.g. `AgBaseRepo`) resolve. Walks up from
  /// [Project.root] via [findPackageConfig] rather than checking
  /// `<root>/.dart_tool/package_config.json` directly — a project that's a
  /// native pub workspace *member* (this repo's own `ag_flow/example`
  /// included) has its dependencies fully resolved, but the resolved
  /// config only ever lives at the workspace root's `.dart_tool/`, never
  /// duplicated into each member.
  Future<bool> get dependenciesResolved async =>
      await findPackageConfig(project.root) != null;

  Future<List<AnalyzeIssue>> analyze() async {
    final appRoutesFile = File(
      p.join(project.libDir.path, 'core', 'routes', 'app_routes.dart'),
    );
    if (!appRoutesFile.existsSync()) {
      throw const ProjectNotInitializedException();
    }

    final routes = parseRouteTable(appRoutesFile.readAsStringSync());

    final issues = <AnalyzeIssue>[
      ...checkRouteWiring(project, routes),
      ...checkDuplicateRoutes(routes),
      ...checkStructure(project),
      ...checkHardcodedRoutes(project),
    ];

    if (await dependenciesResolved) {
      final collection = AnalysisContextCollection(
        includedPaths: [project.root.path],
      );
      issues
        ..addAll(await checkDependencyDirection(project, collection))
        ..addAll(await checkDetailArgumentUsage(project, collection));
    }

    return issues;
  }
}
