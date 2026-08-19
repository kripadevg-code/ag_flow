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

  final patch = Patch.insertion(
    unit.end,
    '\n\nclass ${spec.argumentClass} {\n'
    '  const ${spec.argumentClass}();\n'
    '}\n',
  );
  return AggregatorUpdateResult.changed(applyPatches(source, [patch]));
}
