import 'package:ag_flow_cli/src/generators/import_utils.dart';
import 'package:ag_flow_cli/src/generators/patch.dart';
import 'package:ag_flow_cli/src/naming/module_spec.dart';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';

/// Idempotently ensures [spec]'s navigation method exists in [source]
/// (the contents of `core/routes/route_management.dart`).
///
/// If a method with this name already exists — for any reason, including
/// a developer's hand-customized version — it is left completely
/// untouched: this check is by name only, never by comparing or
/// overwriting a body (requirments/routes.md §19).
AggregatorUpdateResult updateRouteManagement(
  String source,
  ModuleSpec spec, {
  required String appPackageName,
}) {
  final unit = parseString(content: source, throwIfDiagnostics: false).unit;

  final routeManagement = unit.declarations
      .whereType<ClassDeclaration>()
      .firstWhere(
        (c) => c.namePart.typeName.lexeme == 'RouteManagement',
        orElse: () => throw StateError(
          'route_management.dart does not declare a RouteManagement class — run "ag init" first.',
        ),
      );

  final alreadyExists = routeManagement.body.members
      .whereType<MethodDeclaration>()
      .any(
        (m) => m.name.lexeme == spec.navMethod,
      );
  if (alreadyExists) return AggregatorUpdateResult.unchanged(source);

  final patches = <Patch>[];
  if (spec.isDetail) {
    final importPatch = insertImportPatch(
      unit,
      'package:$appPackageName/core/arguments/arguments.dart',
    );
    if (importPatch != null) patches.add(importPatch);
  }

  final body = routeManagement.body;
  final insertOffset = body.members.isEmpty
      ? body.beginToken.end
      : body.members.last.end;
  // A detail route carries its argument in the URL path, not as an
  // opaque payload — that is what makes the destination reachable from a
  // deep link, a notification, or a reloaded web URL.
  final snippet = spec.isDetail
      ? '\n\n  static void ${spec.navMethod}(${spec.argumentClass} argument) {\n'
            '    AgNavigator.toNamed<dynamic>(\n'
            '      AppRoutes.${spec.routeConstant},\n'
            '      pathParameters: argument.toPathParameters(),\n'
            '    );\n'
            '  }'
      : '\n\n  static void ${spec.navMethod}() {\n'
            '    AgNavigator.toNamed<dynamic>(AppRoutes.${spec.routeConstant});\n'
            '  }';
  patches.add(Patch.insertion(insertOffset, snippet));

  return AggregatorUpdateResult.changed(
    sortImports(applyPatches(source, patches)),
  );
}
