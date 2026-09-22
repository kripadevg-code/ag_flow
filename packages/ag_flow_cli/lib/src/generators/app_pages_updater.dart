import 'package:ag_flow_cli/src/generators/import_utils.dart';
import 'package:ag_flow_cli/src/generators/patch.dart';
import 'package:ag_flow_cli/src/naming/module_spec.dart';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';

/// Idempotently ensures [spec]'s `AgRoute` entry (and the imports it
/// needs) exist in [source] (the contents of `core/routes/app_pages
/// .dart`).
AggregatorUpdateResult updateAppPages(
  String source,
  ModuleSpec spec, {
  required String appPackageName,
  required String moduleImportPath,
}) {
  final unit = parseString(content: source, throwIfDiagnostics: false).unit;

  final appPages = unit.declarations.whereType<ClassDeclaration>().firstWhere(
    (c) => c.namePart.typeName.lexeme == 'AppPages',
    orElse: () => throw StateError(
      'app_pages.dart does not declare an AppPages class — run "ag init" first.',
    ),
  );

  final pagesVariable = appPages.body.members
      .whereType<FieldDeclaration>()
      .expand((f) => f.fields.variables)
      .firstWhere(
        (v) => v.name.lexeme == 'pages',
        orElse: () => throw StateError(
          'AppPages does not declare a "pages" field — run "ag init" first.',
        ),
      );
  final pagesList = pagesVariable.initializer;
  if (pagesList is! ListLiteral) {
    throw StateError(
      'AppPages.pages is not a list literal — cannot update it automatically.',
    );
  }

  // A bare `AgRoute(...)` call — no `const`/`new` — parses syntactically
  // as a MethodInvocation, not an InstanceCreationExpression:
  // `parseString` only parses syntax, and disambiguating "constructor
  // call" from "function call" for an unprefixed `Identifier(...)`
  // requires semantic resolution, which this deliberately avoids needing
  // (offset-splice editing only needs syntax, never a resolved element
  // model).
  final routeConstantExpr = 'AppRoutes.${spec.routeConstant}';
  final alreadyRegistered = pagesList.elements
      .whereType<MethodInvocation>()
      .any(
        (invocation) =>
            invocation.methodName.name == 'AgRoute' &&
            invocation.argumentList.arguments.whereType<NamedExpression>().any(
              (arg) =>
                  arg.name.label.name == 'path' &&
                  arg.expression.toSource() == routeConstantExpr,
            ),
      );
  if (alreadyRegistered) return AggregatorUpdateResult.unchanged(source);

  final patches = <Patch>[
    ...[
      insertImportPatch(
        unit,
        'package:$appPackageName/$moduleImportPath/pages/${spec.pageFile}',
      ),
      insertImportPatch(
        unit,
        'package:$appPackageName/$moduleImportPath/bindings/${spec.bindingFile}',
      ),
    ].whereType<Patch>(),
    Patch.insertion(
      pagesList.rightBracket.offset,
      '\n    AgRoute(\n'
      '      path: AppRoutes.${spec.routeConstant},\n'
      '      page: ${spec.pageClass}.new,\n'
      '      binding: ${spec.bindingClass}(),\n'
      '      transition: AppPages.defaultTransition,\n'
      '    ),',
    ),
  ];

  return AggregatorUpdateResult.changed(
    sortImports(applyPatches(source, patches)),
  );
}
