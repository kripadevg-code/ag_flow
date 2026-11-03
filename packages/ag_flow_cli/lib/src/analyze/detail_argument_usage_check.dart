import 'dart:io';

import 'package:ag_flow_cli/src/analyze/analyze_issue.dart';
import 'package:ag_flow_cli/src/io/project.dart';
import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:path/path.dart' as p;

/// Flags a detail module's controller — any `AgBaseController` subclass
/// holding a field typed by one of the app's navigation argument classes
/// (declared in `core/arguments/arguments.dart`) — when that field is
/// never read anywhere in the class. A detail route only exists to carry
/// navigation data to its controller; a controller that stores its
/// argument and never reads it is either dead code or a developer who
/// refactored `retrieve()` and forgot to keep using it
/// (requirments/ag_framework.md §70's "Missing detail argument" check,
/// read as "the argument exists but nothing uses it").
///
/// Needs a resolved element model to confirm a given reference really
/// resolves to that field (not an unrelated local or parameter that
/// happens to share its name) — a syntax-only name search would be a much
/// cruder, false-positive-prone version of this same check.
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

      for (final declaration in result.unit.declarations.whereType<ClassDeclaration>()) {
        if (!_extendsAgBaseController(declaration)) continue;

        for (final field in _argumentFields(declaration)) {
          if (_readsField(declaration, field)) continue;

          issues.add(
            AnalyzeIssue(
              category: AnalyzeCategory.unusedDetailArgument,
              message:
                  'Detail controller '
                  '"${declaration.namePart.typeName.lexeme}" never reads its '
                  '"$field" argument — this module\'s navigation argument '
                  'is unread.',
              file: p.relative(entity.path, from: project.root.path),
            ),
          );
        }
      }
    }
  }
  return issues;
}

bool _extendsAgBaseController(ClassDeclaration declaration) {
  final superclass = declaration.extendsClause?.superclass;
  if (superclass == null) return false;
  final type = superclass.type;
  if (type is! InterfaceType) return false;
  if (type.element.name == 'AgBaseController') return true;
  return type.element.allSupertypes.any(
    (s) => s.element.name == 'AgBaseController',
  );
}

/// The names of [declaration]'s fields whose type is a navigation
/// argument class — one declared in the app's `core/arguments/arguments.dart`.
Iterable<String> _argumentFields(ClassDeclaration declaration) sync* {
  for (final member in declaration.body.members) {
    if (member is! FieldDeclaration || member.isStatic) continue;
    final type = member.fields.type?.type;
    if (type is! InterfaceType) continue;
    final source = type.element.library.firstFragment.source.fullName;
    if (!p.posix.joinAll(p.split(source)).endsWith('core/arguments/arguments.dart')) {
      continue;
    }
    for (final variable in member.fields.variables) {
      yield variable.name.lexeme;
    }
  }
}

bool _readsField(ClassDeclaration declaration, String field) {
  final owner = declaration.declaredFragment?.element;
  if (owner == null) return true;
  final visitor = _FieldReadVisitor(owner, field);
  declaration.accept(visitor);
  return visitor.found;
}

class _FieldReadVisitor extends RecursiveAstVisitor<void> {
  _FieldReadVisitor(this.owner, this.field);

  final InterfaceElement owner;
  final String field;
  bool found = false;

  @override
  void visitConstructorFieldInitializer(ConstructorFieldInitializer node) {
    // `argument = ...` assigns the field rather than reading it; only the
    // right-hand side can contain a read.
    node.expression.accept(this);
  }

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    final element = node.element;
    if (!found &&
        node.name == field &&
        element is PropertyAccessorElement &&
        element.enclosingElement == owner) {
      found = true;
    }
    super.visitSimpleIdentifier(node);
  }
}
