import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:meta/meta.dart';

/// A single `static const String <name> = '<path>';` entry read back out of
/// `_Routes` in `core/routes/app_routes.dart`.
@immutable
class RouteEntry {
  const RouteEntry({required this.name, required this.path});

  final String name;
  final String path;
}

/// Parses every route constant declared in `_Routes` (the contents of
/// `core/routes/app_routes.dart`).
///
/// Returns an empty list if the file doesn't declare a `_Routes` class at
/// all (callers should treat that as its own "run ag init first" issue,
/// not silently report zero routes).
List<RouteEntry> parseRouteTable(String appRoutesSource) {
  final unit = parseString(
    content: appRoutesSource,
    throwIfDiagnostics: false,
  ).unit;

  ClassDeclaration? routesImpl;
  for (final declaration in unit.declarations) {
    if (declaration is ClassDeclaration &&
        declaration.namePart.typeName.lexeme == '_Routes') {
      routesImpl = declaration;
      break;
    }
  }
  if (routesImpl == null) return const [];

  final entries = <RouteEntry>[];
  for (final member in routesImpl.body.members) {
    if (member is! FieldDeclaration) continue;
    for (final variable in member.fields.variables) {
      final initializer = variable.initializer;
      if (initializer is SimpleStringLiteral) {
        entries.add(
          RouteEntry(name: variable.name.lexeme, path: initializer.value),
        );
      }
    }
  }
  return entries;
}
