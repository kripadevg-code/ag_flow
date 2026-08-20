import 'package:ag_flow_cli/src/analyze/analyze_issue.dart';
import 'package:ag_flow_cli/src/analyze/route_table.dart';
import 'package:path/path.dart' as p;

/// Flags two different route constants that resolve to the identical
/// route path — a real bug the generator's own conflict check can't catch,
/// since that only guards against the *same* constant pointing at two
/// different paths (requirments/routes.md §21), never the reverse.
List<AnalyzeIssue> checkDuplicateRoutes(List<RouteEntry> routes) {
  final byPath = <String, List<String>>{};
  for (final route in routes) {
    if (route.name == 'initial') continue;
    byPath.putIfAbsent(route.path, () => []).add(route.name);
  }

  final issues = <AnalyzeIssue>[];
  for (final entry in byPath.entries) {
    if (entry.value.length < 2) continue;
    issues.add(
      AnalyzeIssue(
        category: AnalyzeCategory.duplicateRoute,
        message:
            'Route path "${entry.key}" is registered under multiple names: '
            '${entry.value.join(', ')}.',
        file: p.join('lib', 'core', 'routes', 'app_routes.dart'),
      ),
    );
  }
  return issues;
}
