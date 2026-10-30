import 'package:ag_flow_cli/src/generators/import_utils.dart';
import 'package:ag_flow_cli/src/generators/patch.dart';
import 'package:ag_flow_cli/src/naming/module_spec.dart';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

/// Whether [unit] (the contents of `core/routes/app_pages.dart`) already
/// declares a `GoRoute` whose `path:` is `AppRoutes.<routeConstant>`.
///
/// Searches the *whole* file, not just the top level of `AppPages.pages`:
/// the app owns this router, and a developer is expected to move a
/// generated `GoRoute` into a `ShellRoute`'s `routes:` or under a parent
/// route. A top-level-only check would miss it there and re-add a
/// duplicate on the next `ag g m`. Shared with `ag analyze`'s route-wiring
/// check, so the generator and the validator can never disagree.
bool hasGoRouteFor(CompilationUnit unit, String routeConstant) {
  final finder = _GoRouteFinder('AppRoutes.$routeConstant');
  unit.accept(finder);
  return finder.found;
}

class _GoRouteFinder extends RecursiveAstVisitor<void> {
  _GoRouteFinder(this.pathExpression);

  final String pathExpression;
  bool found = false;

  // A bare `GoRoute(...)` call — no `const`/`new` — parses syntactically
  // as a MethodInvocation, not an InstanceCreationExpression: `parseString`
  // only parses syntax, and telling "constructor call" from "function call"
  // for an unprefixed `Identifier(...)` needs semantic resolution, which
  // offset-splice editing deliberately never does. A `const GoRoute(...)`
  // does parse as an InstanceCreationExpression, so both are checked.
  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.target == null && node.methodName.name == 'GoRoute') {
      _check(node.argumentList);
    }
    super.visitMethodInvocation(node);
  }

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    if (node.constructorName.type.name.lexeme == 'GoRoute') {
      _check(node.argumentList);
    }
    super.visitInstanceCreationExpression(node);
  }

  void _check(ArgumentList arguments) {
    if (arguments.arguments.whereType<NamedArgument>().any(
      (arg) =>
          arg.name.lexeme == 'path' &&
          arg.argumentExpression.toSource() == pathExpression,
    )) {
      found = true;
    }
  }
}

/// Idempotently ensures [spec]'s `GoRoute` entry (and the imports it
/// needs) exist in [source] (the contents of `core/routes/app_pages
/// .dart`).
///
/// The router is plain go_router, owned by the app: the entry is written
/// the way a developer would write it by hand, with `AgRoutePage` as the
/// only AG piece in it — that page is what registers the module's binding
/// on entry and releases it once the route is gone.
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

  if (hasGoRouteFor(unit, spec.routeConstant)) {
    return AggregatorUpdateResult.unchanged(source);
  }

  final route = 'AppRoutes.${spec.routeConstant}';
  final patches = <Patch>[
    ...[
      insertImportPatch(unit, 'package:go_router/go_router.dart'),
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
      '\n    GoRoute(\n'
      '      path: $route,\n'
      '      name: $route,\n'
      '      pageBuilder: (context, state) => AgRoutePage<void>(\n'
      '        key: state.pageKey,\n'
      '        pathParameters: state.pathParameters,\n'
      '        extra: state.extra,\n'
      '        binding: ${spec.bindingClass}(),\n'
      '        transition: AppPages.defaultTransition,\n'
      '        child: const ${spec.pageClass}(),\n'
      '      ),\n'
      '    ),',
    ),
  ];

  return AggregatorUpdateResult.changed(
    sortImports(applyPatches(source, patches)),
  );
}
