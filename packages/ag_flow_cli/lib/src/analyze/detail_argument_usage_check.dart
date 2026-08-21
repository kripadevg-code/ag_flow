import 'dart:io';

import 'package:ag_flow_cli/src/analyze/analyze_issue.dart';
import 'package:ag_flow_cli/src/io/project.dart';
import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:path/path.dart' as p;

/// Flags a detail module's controller — one extending `AgDetailController`
/// — whose inherited `arguments` accessor is never referenced anywhere in
/// the class. A detail route only exists to carry navigation data to its
/// controller; a controller that never reads `arguments` at all is either
/// dead code or a developer who refactored `fetch()` and forgot to keep
/// using it (requirments/ag_framework.md §70's "Missing detail argument"
/// check, read as "the argument exists but nothing uses it").
///
/// Needs a resolved element model to confirm a given `arguments`
/// reference really resolves to `AgDetailController.arguments` (not an
/// unrelated local/parameter that happens to share the name) — a
/// syntax-only name search would be a much cruder, false-positive-prone
/// version of this same check.
Future<List<AnalyzeIssue>> checkDetailArgumentUsage(
  Project project,
  AnalysisContextCollection collection,
) async {
  if (!project.modulesDir.existsSync()) return const [];

  final issues = <AnalyzeIssue>[];
  for (final rootEntity in project.modulesDir.listSync()) {
    if (rootEntity is! Directory) continue;

    final controllersDir = Directory(p.join(rootEntity.path, 'controllers'));
    if (!controllersDir.existsSync()) continue;

    for (final entity in controllersDir.listSync()) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;

      final session = collection.contextFor(entity.path).currentSession;
      final result = await session.getResolvedUnit(entity.path);
      if (result is! ResolvedUnitResult) continue;

      for (final declaration
          in result.unit.declarations.whereType<ClassDeclaration>()) {
        if (!_extendsAgDetailController(declaration)) continue;
        if (_referencesInheritedArguments(declaration)) continue;

        issues.add(
          AnalyzeIssue(
            category: AnalyzeCategory.unusedDetailArgument,
            message:
                'Detail controller '
                '"${declaration.namePart.typeName.lexeme}" never uses its '
                'inherited "arguments" — this module\'s navigation argument '
                'is unread.',
            file: p.relative(entity.path, from: project.root.path),
          ),
        );
      }
    }
  }
  return issues;
}

bool _extendsAgDetailController(ClassDeclaration declaration) {
  final superclass = declaration.extendsClause?.superclass;
  if (superclass == null) return false;
  final type = superclass.type;
  if (type is! InterfaceType) return false;
  if (type.element.name == 'AgDetailController') return true;
  return type.element.allSupertypes.any(
    (s) => s.element.name == 'AgDetailController',
  );
}

bool _referencesInheritedArguments(ClassDeclaration declaration) {
  final visitor = _ArgumentsUsageVisitor();
  declaration.accept(visitor);
  return visitor.found;
}

class _ArgumentsUsageVisitor extends RecursiveAstVisitor<void> {
  bool found = false;

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    if (!found &&
        node.name == 'arguments' &&
        node.element?.enclosingElement?.name == 'AgDetailController') {
      found = true;
    }
    super.visitSimpleIdentifier(node);
  }
}
