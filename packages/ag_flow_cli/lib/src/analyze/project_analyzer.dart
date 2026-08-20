import 'dart:io';

import 'package:ag_flow_cli/src/analyze/analyze_issue.dart';
import 'package:ag_flow_cli/src/analyze/duplicate_route_check.dart';
import 'package:ag_flow_cli/src/analyze/hardcoded_route_check.dart';
import 'package:ag_flow_cli/src/analyze/route_table.dart';
import 'package:ag_flow_cli/src/analyze/route_wiring_check.dart';
import 'package:ag_flow_cli/src/analyze/structure_check.dart';
import 'package:ag_flow_cli/src/io/project.dart';
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

/// `ag analyze`'s v1 (mechanical/structural) validator: checks a project
/// generated (or hand-maintained) against AG's structural rules without
/// needing a resolved element model — see `AnalyzeCategory` for exactly
/// which checks this covers, and ag_flow_cli/README.md for what's
/// deliberately deferred to v2+.
class ProjectAnalyzer {
  const ProjectAnalyzer({required this.project});

  final Project project;

  List<AnalyzeIssue> analyze() {
    final appRoutesFile = File(
      p.join(project.libDir.path, 'core', 'routes', 'app_routes.dart'),
    );
    if (!appRoutesFile.existsSync()) {
      throw const ProjectNotInitializedException();
    }

    final routes = parseRouteTable(appRoutesFile.readAsStringSync());

    return [
      ...checkRouteWiring(project, routes),
      ...checkDuplicateRoutes(routes),
      ...checkStructure(project),
      ...checkHardcodedRoutes(project),
    ];
  }
}
