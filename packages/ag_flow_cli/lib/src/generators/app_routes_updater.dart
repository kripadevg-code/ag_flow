import 'package:ag_flow_cli/src/generators/patch.dart';
import 'package:ag_flow_cli/src/naming/module_spec.dart';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';

/// Thrown when a route constant already exists but points at a different
/// path than this module would derive — a genuine naming conflict,
/// distinct from the safe idempotent case of re-running the exact same
/// module (requirments/routes.md §21).
class RouteConflictException implements Exception {
  const RouteConflictException({
    required this.routeConstant,
    required this.existingPath,
    required this.newPath,
  });

  final String routeConstant;
  final String existingPath;
  final String newPath;

  @override
  String toString() =>
      'Route already exists: AppRoutes.$routeConstant is already registered '
      'for "$existingPath", which conflicts with "$newPath".';
}

/// Idempotently ensures [spec]'s route constant exists in both `AppRoutes`
/// and `_Routes` in [source] (the contents of `core/routes/app_routes
/// .dart`). Throws [RouteConflictException] if the constant already
/// exists pointing at a different path.
AggregatorUpdateResult updateAppRoutes(String source, ModuleSpec spec) {
  final unit = parseString(content: source, throwIfDiagnostics: false).unit;
  final classes = unit.declarations.whereType<ClassDeclaration>();

  final appRoutes = classes.firstWhere(
    (c) => c.namePart.typeName.lexeme == 'AppRoutes',
    orElse: () => throw StateError(
      'app_routes.dart does not declare an AppRoutes class — run "ag init" first.',
    ),
  );
  final routesImpl = classes.firstWhere(
    (c) => c.namePart.typeName.lexeme == '_Routes',
    orElse: () => throw StateError(
      'app_routes.dart does not declare a _Routes class — run "ag init" first.',
    ),
  );

  // The *registered* path is what the constant holds: a detail module's
  // route declares a path parameter (`/product/details/:id`) so the page
  // is reachable from a deep link, not only from an in-app push.
  final registeredPath = spec.registeredRoutePath;
  final existingPath = _existingPathFor(routesImpl, spec.routeConstant);
  if (existingPath != null && existingPath != registeredPath) {
    throw RouteConflictException(
      routeConstant: spec.routeConstant,
      existingPath: existingPath,
      newPath: registeredPath,
    );
  }

  final patches = <Patch>[
    if (!_hasConstant(appRoutes, spec.routeConstant))
      _insertMember(
        appRoutes,
        '\n  static const String ${spec.routeConstant} = _Routes.${spec.routeConstant};',
      ),
    if (existingPath == null)
      _insertMember(
        routesImpl,
        "\n  static const String ${spec.routeConstant} = '$registeredPath';",
      ),
  ];

  if (patches.isEmpty) return AggregatorUpdateResult.unchanged(source);
  return AggregatorUpdateResult.changed(applyPatches(source, patches));
}

bool _hasConstant(ClassDeclaration classDecl, String constantName) {
  return classDecl.body.members
      .whereType<FieldDeclaration>()
      .expand((f) => f.fields.variables)
      .any((v) => v.name.lexeme == constantName);
}

String? _existingPathFor(ClassDeclaration routesImpl, String constantName) {
  for (final member in routesImpl.body.members) {
    if (member is! FieldDeclaration) continue;
    for (final variable in member.fields.variables) {
      if (variable.name.lexeme != constantName) continue;
      final initializer = variable.initializer;
      return initializer is SimpleStringLiteral
          ? initializer.value
          : initializer?.toSource();
    }
  }
  return null;
}

Patch _insertMember(ClassDeclaration classDecl, String text) {
  final body = classDecl.body;
  final offset = body.members.isEmpty
      ? body.beginToken.end
      : body.members.last.end;
  return Patch.insertion(offset, text);
}
