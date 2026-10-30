import 'dart:io';

import 'package:ag_flow_cli/src/analyze/analyze_issue.dart';
import 'package:ag_flow_cli/src/io/project.dart';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:path/path.dart' as p;

/// go_router's navigation methods. Whatever the receiver — `context`,
/// `GoRouter.of(context)`, `AppPages.router` — a literal path passed to
/// one of these outside `route_management.dart` is a hard-coded route.
/// Route names are the paths themselves (`name: AppRoutes.x`), so the
/// `*Named` variants take the same `/...` literal.
const _navigationMethods = {
  'go',
  'goNamed',
  'push',
  'pushNamed',
  'pushReplacement',
  'pushReplacementNamed',
  'replace',
  'replaceNamed',
};

/// Flags `context.push('/some/literal/path')`-style navigation anywhere in
/// the project's `lib/` tree — routes must always be referenced via their
/// `AppRoutes.*` constant so `route_management.dart` stays the single
/// source of truth for navigation (requirments/routes.md §1).
/// Deliberately only matches a raw string-literal first argument:
/// `AppPages.router.pushNamed(AppRoutes.product)` is exactly what
/// generated code does and is never flagged.
///
/// `route_management.dart` itself is exempt — it's the one place a literal
/// route string is ever appropriate.
List<AnalyzeIssue> checkHardcodedRoutes(Project project) {
  final issues = <AnalyzeIssue>[];
  if (!project.libDir.existsSync()) return issues;

  final exemptPath = p.join(
    project.libDir.path,
    'core',
    'routes',
    'route_management.dart',
  );

  for (final entity in project.libDir.listSync(recursive: true)) {
    if (entity is! File || !entity.path.endsWith('.dart')) continue;
    if (p.equals(entity.path, exemptPath)) continue;

    final unit = parseString(
      content: entity.readAsStringSync(),
      throwIfDiagnostics: false,
    ).unit;
    final visitor = _HardcodedRouteVisitor();
    unit.accept(visitor);

    for (final literal in visitor.found) {
      issues.add(
        AnalyzeIssue(
          category: AnalyzeCategory.hardcodedRoute,
          message:
              'Hard-coded route string "$literal" — call a '
              'RouteManagement.goToXPage(...) method instead of navigating '
              'with a literal path.',
          file: p.relative(entity.path, from: project.root.path),
        ),
      );
    }
  }

  return issues;
}

class _HardcodedRouteVisitor extends RecursiveAstVisitor<void> {
  final List<String> found = [];

  @override
  void visitMethodInvocation(MethodInvocation node) {
    final arguments = node.argumentList.arguments;
    final firstArg = arguments.isEmpty ? null : arguments.first;
    // Only a literal that *looks like a route* — `/...` — so an unrelated
    // `replace('a', 'b')` on a String or a list is never flagged.
    if (_navigationMethods.contains(node.methodName.name) &&
        node.target != null &&
        firstArg is SimpleStringLiteral &&
        firstArg.value.startsWith('/')) {
      found.add(firstArg.value);
    }
    super.visitMethodInvocation(node);
  }
}
