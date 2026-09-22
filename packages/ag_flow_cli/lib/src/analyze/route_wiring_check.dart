import 'dart:io';

import 'package:ag_flow_cli/src/analyze/analyze_issue.dart';
import 'package:ag_flow_cli/src/analyze/route_table.dart';
import 'package:ag_flow_cli/src/io/project.dart';
import 'package:ag_flow_cli/src/naming/module_path.dart';
import 'package:ag_flow_cli/src/naming/module_spec.dart';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:path/path.dart' as p;

/// For every route in [routes] (as parsed from `app_routes.dart`, minus
/// `initial`), checks that the module it names has all five architectural
/// layer files (Rule: missing layer file), an `AgRoute` entry in
/// `app_pages.dart`, a navigation method in `route_management.dart`, and —
/// for detail modules — an argument class in `arguments.dart` (Rule:
/// missing route wiring).
///
/// Re-derives each module's expected file/class names from its route path
/// via [ModuleSpec.from] using the *default* pluralizer — a module
/// originally generated with a custom `--plural=` override may produce
/// false "missing layer file" positives here, since that override isn't
/// recorded anywhere `ag analyze` can read it back from. This is a known
/// v1 limitation, not a bug.
List<AnalyzeIssue> checkRouteWiring(Project project, List<RouteEntry> routes) {
  final issues = <AnalyzeIssue>[];

  final appPagesFile = File(
    p.join(project.libDir.path, 'core', 'routes', 'app_pages.dart'),
  );
  final routeManagementFile = File(
    p.join(project.libDir.path, 'core', 'routes', 'route_management.dart'),
  );
  final argumentsFile = File(
    p.join(project.libDir.path, 'core', 'arguments', 'arguments.dart'),
  );

  final appPagesUnit = appPagesFile.existsSync()
      ? parseString(
          content: appPagesFile.readAsStringSync(),
          throwIfDiagnostics: false,
        ).unit
      : null;
  final routeManagementUnit = routeManagementFile.existsSync()
      ? parseString(
          content: routeManagementFile.readAsStringSync(),
          throwIfDiagnostics: false,
        ).unit
      : null;
  final argumentsUnit = argumentsFile.existsSync()
      ? parseString(
          content: argumentsFile.readAsStringSync(),
          throwIfDiagnostics: false,
        ).unit
      : null;

  for (final route in routes) {
    if (route.name == 'initial') continue;

    // A registered path may declare parameters (`/product/details/:id`).
    // Those are addressing, not module structure — strip them before
    // re-deriving the spec, so the path still round-trips through
    // ModulePath.parse exactly as ModuleSpec.routePath produced it.
    final structuralPath = route.path
        .split('/')
        .where((segment) => segment.isNotEmpty && !segment.startsWith(':'))
        .join('/');

    final ModulePath modulePath;
    try {
      modulePath = ModulePath.parse(structuralPath);
    } on FormatException {
      issues.add(
        AnalyzeIssue(
          category: AnalyzeCategory.missingRouteWiring,
          message:
              'Route "AppRoutes.${route.name}" has an invalid path '
              '"${route.path}" — cannot check its wiring.',
          file: p.join('lib', 'core', 'routes', 'app_routes.dart'),
        ),
      );
      continue;
    }

    final spec = ModuleSpec.from(modulePath);
    final moduleRoot = project.moduleRootDir(modulePath.rootSegment);

    _checkLayerFile(
      issues,
      project,
      moduleRoot,
      'controllers',
      spec.controllerFile,
    );
    _checkLayerFile(issues, project, moduleRoot, 'pages', spec.pageFile);
    _checkLayerFile(issues, project, moduleRoot, 'repos', spec.repoFile);
    _checkLayerFile(
      issues,
      project,
      moduleRoot,
      'services',
      spec.serviceFile,
    );
    _checkLayerFile(
      issues,
      project,
      moduleRoot,
      'bindings',
      spec.bindingFile,
    );

    if (appPagesUnit != null && !_hasAgRouteEntry(appPagesUnit, route.name)) {
      issues.add(
        AnalyzeIssue(
          category: AnalyzeCategory.missingRouteWiring,
          message:
              'Route "AppRoutes.${route.name}" has no AgRoute entry in '
              'app_pages.dart.',
          file: p.join('lib', 'core', 'routes', 'app_pages.dart'),
        ),
      );
    }

    if (routeManagementUnit != null &&
        !_hasNavMethod(routeManagementUnit, spec.navMethod)) {
      issues.add(
        AnalyzeIssue(
          category: AnalyzeCategory.missingRouteWiring,
          message:
              'Route "AppRoutes.${route.name}" has no navigation method '
              '"${spec.navMethod}" in route_management.dart.',
          file: p.join('lib', 'core', 'routes', 'route_management.dart'),
        ),
      );
    }

    if (spec.isDetail &&
        argumentsUnit != null &&
        !_hasArgumentClass(argumentsUnit, spec.argumentClass)) {
      issues.add(
        AnalyzeIssue(
          category: AnalyzeCategory.missingRouteWiring,
          message:
              'Detail route "AppRoutes.${route.name}" is missing its '
              'argument class "${spec.argumentClass}" in arguments.dart.',
          file: p.join('lib', 'core', 'arguments', 'arguments.dart'),
        ),
      );
    }
  }

  return issues;
}

void _checkLayerFile(
  List<AnalyzeIssue> issues,
  Project project,
  String moduleRoot,
  String layerDir,
  String fileName,
) {
  final path = p.join(moduleRoot, layerDir, fileName);
  if (File(path).existsSync()) return;
  issues.add(
    AnalyzeIssue(
      category: AnalyzeCategory.missingLayerFile,
      message: 'Expected $layerDir file is missing: $fileName.',
      file: p.relative(path, from: project.root.path),
    ),
  );
}

bool _hasAgRouteEntry(CompilationUnit appPagesUnit, String routeConstant) {
  ClassDeclaration? appPages;
  for (final declaration in appPagesUnit.declarations) {
    if (declaration is ClassDeclaration &&
        declaration.namePart.typeName.lexeme == 'AppPages') {
      appPages = declaration;
      break;
    }
  }
  if (appPages == null) return false;

  ListLiteral? pagesList;
  for (final member in appPages.body.members) {
    if (member is! FieldDeclaration) continue;
    for (final variable in member.fields.variables) {
      final initializer = variable.initializer;
      if (variable.name.lexeme == 'pages' && initializer is ListLiteral) {
        pagesList = initializer;
      }
    }
  }
  if (pagesList == null) return false;

  final routeConstantExpr = 'AppRoutes.$routeConstant';
  return pagesList.elements.whereType<MethodInvocation>().any(
    (invocation) =>
        invocation.methodName.name == 'AgRoute' &&
        invocation.argumentList.arguments.whereType<NamedExpression>().any(
          (arg) =>
              arg.name.label.name == 'path' &&
              arg.expression.toSource() == routeConstantExpr,
        ),
  );
}

bool _hasNavMethod(CompilationUnit routeManagementUnit, String navMethod) {
  for (final declaration in routeManagementUnit.declarations) {
    if (declaration is! ClassDeclaration ||
        declaration.namePart.typeName.lexeme != 'RouteManagement') {
      continue;
    }
    return declaration.body.members.whereType<MethodDeclaration>().any(
      (m) => m.name.lexeme == navMethod,
    );
  }
  return false;
}

bool _hasArgumentClass(CompilationUnit argumentsUnit, String argumentClass) {
  return argumentsUnit.declarations.whereType<ClassDeclaration>().any(
    (c) => c.namePart.typeName.lexeme == argumentClass,
  );
}
