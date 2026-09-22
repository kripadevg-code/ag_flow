import 'package:ag_flow_cli/src/generators/patch.dart';
import 'package:ag_flow_cli/src/naming/module_spec.dart';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';

/// Idempotently ensures [spec]'s navigation-argument class exists in
/// [source] (the contents of `core/arguments/arguments.dart`).
///
/// Only meaningful for detail modules — callers should not invoke this
/// for a root module, which takes no navigation argument.
AggregatorUpdateResult updateArguments(String source, ModuleSpec spec) {
  final unit = parseString(content: source, throwIfDiagnostics: false).unit;

  final alreadyExists = unit.declarations.whereType<ClassDeclaration>().any(
    (c) => c.namePart.typeName.lexeme == spec.argumentClass,
  );
  if (alreadyExists) return AggregatorUpdateResult.unchanged(source);

  // The argument is built from — and converted back to — the route's
  // path parameters, so the page it addresses is reachable from a deep
  // link and not only from an in-app push. Path parameters are always
  // strings; convert in the Controller if the module needs another type.
  const parameter = ModuleSpec.pathParameterName;
  final patch = Patch.insertion(
    unit.end,
    '\n\nclass ${spec.argumentClass} {\n'
    '  const ${spec.argumentClass}({required this.$parameter});\n'
    '\n'
    "  /// Rebuilds this argument from the route's path parameters — what\n"
    '  /// makes ${spec.pageClass} work from a deep link, not just an\n'
    '  /// in-app push.\n'
    '  factory ${spec.argumentClass}.fromPathParameters(\n'
    '    Map<String, String> pathParameters,\n'
    '  ) {\n'
    "    final $parameter = pathParameters['$parameter'];\n"
    '    if ($parameter == null) {\n'
    '      throw ArgumentError(\n'
    "        'Route was opened without an \"$parameter\" path parameter. '\n"
    "        'Navigate via RouteManagement.${spec.navMethod}().',\n"
    '      );\n'
    '    }\n'
    '    return ${spec.argumentClass}($parameter: $parameter);\n'
    '  }\n'
    '\n'
    '  final String $parameter;\n'
    '\n'
    '  Map<String, String> toPathParameters() => {\n'
    "    '$parameter': $parameter,\n"
    '  };\n'
    '}\n',
  );
  return AggregatorUpdateResult.changed(applyPatches(source, [patch]));
}
