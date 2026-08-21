import 'dart:io';

import 'package:ag_flow_cli/src/analyze/analyze_issue.dart';
import 'package:ag_flow_cli/src/io/project.dart';
import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:path/path.dart' as p;

/// What each architectural layer must not directly reference, by class
/// name — checked against both the referenced type itself and its full
/// supertype chain, so a concrete `ProductsRepo extends AgBaseRepo` is
/// caught the same way a raw `AgBaseRepo` reference would be
/// (requirments/ag_framework.md §12/§24/§27/§70).
const _pageForbidden = {'AgBaseRepo', 'AgBaseService', 'ApiProvider', 'Dio'};
const _controllerForbidden = {'AgBaseService', 'ApiProvider', 'Dio'};
const _repoForbidden = {'ApiProvider', 'Dio'};

/// Flags a Page, Controller, or Repo file that directly references a type
/// from a layer it must skip over — e.g. a Page referencing a Repo or
/// Service, a Controller referencing a Service or `ApiProvider`/`Dio`, or
/// a Repo referencing `ApiProvider`/`Dio` (requirments/ag_framework.md
/// §70's closed violation list).
///
/// Needs a *resolved* element model — checking whether some referenced
/// type's inheritance chain includes `AgBaseRepo`/`AgBaseService` can't be
/// done from syntax alone, unlike every v1 check. [collection] must be
/// rooted at the project so `ag_flow`'s own types resolve; callers are
/// responsible for confirming the project's dependencies are resolved
/// first (see `ProjectAnalyzer.dependenciesResolved`) — this function
/// assumes resolution succeeds and simply finds nothing if it doesn't.
///
/// Verified against `dart run` and a real `dart pub global activate`ed
/// `ag` — both resolve the Dart SDK correctly since they run through the
/// real `dart` executable. A standalone `dart compile exe` build of `ag`
/// does *not* work here: `AnalysisContextCollection`'s default SDK
/// detection derives the SDK root from `Platform.resolvedExecutable`,
/// which for a compiled native binary is the binary itself, not a path
/// inside a real SDK tree, and the analyzer throws trying to read SDK
/// library metadata from a nonsense derived path. Not fixed, since
/// `dart compile exe` isn't a documented distribution method for this
/// CLI (see ag_flow_cli/README.md) — noted here for whoever
/// tries it next.
Future<List<AnalyzeIssue>> checkDependencyDirection(
  Project project,
  AnalysisContextCollection collection,
) async {
  if (!project.modulesDir.existsSync()) return const [];

  final issues = <AnalyzeIssue>[];
  for (final rootEntity in project.modulesDir.listSync()) {
    if (rootEntity is! Directory) continue;

    issues
      ..addAll(
        await _checkLayer(
          collection,
          project,
          rootEntity,
          'pages',
          _pageForbidden,
        ),
      )
      ..addAll(
        await _checkLayer(
          collection,
          project,
          rootEntity,
          'controllers',
          _controllerForbidden,
        ),
      )
      ..addAll(
        await _checkLayer(
          collection,
          project,
          rootEntity,
          'repos',
          _repoForbidden,
        ),
      );
  }
  return issues;
}

Future<List<AnalyzeIssue>> _checkLayer(
  AnalysisContextCollection collection,
  Project project,
  Directory moduleRoot,
  String layerDir,
  Set<String> forbidden,
) async {
  final dir = Directory(p.join(moduleRoot.path, layerDir));
  if (!dir.existsSync()) return const [];

  final issues = <AnalyzeIssue>[];
  for (final entity in dir.listSync()) {
    if (entity is! File || !entity.path.endsWith('.dart')) continue;

    final session = collection.contextFor(entity.path).currentSession;
    final result = await session.getResolvedUnit(entity.path);
    if (result is! ResolvedUnitResult) continue;

    final visitor = _ForbiddenTypeVisitor(forbidden);
    result.unit.accept(visitor);

    final relativePath = p.relative(entity.path, from: project.root.path);
    for (final typeName in visitor.found) {
      issues.add(
        AnalyzeIssue(
          category: AnalyzeCategory.dependencyDirection,
          message:
              'Invalid dependency direction: this file directly '
              'references "$typeName", skipping a layer '
              '(requirments/ag_framework.md §11).',
          file: relativePath,
        ),
      );
    }
  }
  return issues;
}

class _ForbiddenTypeVisitor extends RecursiveAstVisitor<void> {
  _ForbiddenTypeVisitor(this.forbidden);

  final Set<String> forbidden;

  /// Distinct forbidden type names found so far — a `Set` so a type
  /// referenced many times in one file (e.g. imported and used repeatedly)
  /// produces one issue, not one per occurrence.
  final Set<String> found = {};

  @override
  void visitNamedType(NamedType node) {
    final type = node.type;
    if (type is InterfaceType) {
      if (forbidden.contains(type.element.name)) {
        found.add(type.element.name!);
      } else {
        for (final supertype in type.element.allSupertypes) {
          if (forbidden.contains(supertype.element.name)) {
            found.add(supertype.element.name!);
          }
        }
      }
    }
    super.visitNamedType(node);
  }
}
