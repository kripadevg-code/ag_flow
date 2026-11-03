import 'dart:convert';
import 'dart:io';

import 'package:ag_flow_cli/src/generators/module_generator.dart';
import 'package:ag_flow_cli/src/io/project.dart';
import 'package:ag_flow_cli/src/naming/case_convert.dart';
import 'package:ag_flow_cli/src/naming/model_spec.dart';
import 'package:ag_flow_cli/src/naming/module_path.dart';
import 'package:path/path.dart' as p;

/// Parses a `--methods` value: null means all of [generatableMethods],
/// `none` means none of them, otherwise a comma-separated subset.
///
/// Shared by `ag g m` and the MCP server so both read the option the same
/// way. Throws a [FormatException] naming any unrecognized value.
Set<String> parseMethods(String? option) {
  if (option == null) return generatableMethods;
  if (option == 'none') return const {};
  final methods = option.split(',').map((m) => m.trim()).toSet();
  final unknown = methods.difference(generatableMethods);
  if (unknown.isNotEmpty) {
    throw FormatException(
      'Unrecognized methods value(s): ${unknown.join(', ')}. '
      'Expected a comma-separated subset of '
      '${generatableMethods.join(', ')}, or "none".',
    );
  }
  return methods;
}

/// Builds the module's [ModelSpec] from a model name and/or a JSON sample
/// ([jsonText], described as [jsonLabel] in errors). With neither, a child
/// module reuses its root's model when the root has exactly one; otherwise
/// this is null and the stack is typed `dynamic`.
///
/// Throws a [FormatException] when [jsonText] is not valid JSON.
ModelSpec? resolveModel(
  ModulePath modulePath,
  Project project, {
  String? model,
  String? jsonText,
  String jsonLabel = 'JSON sample',
  void Function(String message)? onInfo,
}) {
  if (model == null && jsonText == null) {
    if (modulePath.isRoot) return null;
    final existing = existingModel(modulePath.rootSegment, project);
    if (existing != null) {
      onInfo?.call(
        "Using the root module's model ${existing.className} (pass --model to choose another).",
      );
    }
    return existing;
  }

  // Default the class name to the module's *root* segment, not its last
  // one: `product/details` addresses the same resource as `product`, so
  // it must reuse `Product` rather than inventing a second `Details`
  // model alongside it. Layer files live in flat per-root folders for
  // the same reason.
  final className = model == null ? pascalCase(modulePath.rootSegment) : pascalCase(model);

  if (jsonText == null) {
    // A model name alone: no payload to infer fields from, so the model
    // is an empty shell the developer fills in. The win is still the type
    // threading across five files.
    return ModelSpec(className: className, fields: const []);
  }

  final Object? decoded;
  try {
    decoded = jsonDecode(jsonText);
  } on FormatException catch (e) {
    throw FormatException('$jsonLabel is not valid JSON (${e.message})');
  }
  return ModelSpec.fromJsonSample(className, decoded);
}

/// The model already in `<rootSegment>/models/`, when there is exactly one —
/// `product/details` addresses the same resource as `product`. Only its
/// class name and `id` type are read; the file itself is never rewritten.
ModelSpec? existingModel(String rootSegment, Project project) {
  final dir = Directory(p.join(project.moduleRootDir(rootSegment), 'models'));
  if (!dir.existsSync()) return null;
  final files = dir.listSync().whereType<File>().where((f) => f.path.endsWith('.dart')).toList();
  if (files.length != 1) return null;
  final source = files.single.readAsStringSync();
  final className = RegExp(r'^class (\w+)', multiLine: true).firstMatch(source)?.group(1);
  // Only a file named the way the generator names it: anything else would
  // make the generator write a second model file beside it.
  if (className == null || p.basename(files.single.path) != '${snakeCase(className)}.dart') {
    return null;
  }
  final idType = RegExp(r'final (\w+\??) id;').firstMatch(source)?.group(1);
  return ModelSpec(
    className: className,
    fields: [
      if (idType != null)
        AgModelField(
          jsonKey: 'id',
          dartName: 'id',
          dartType: idType,
          fromJsonExpression: '',
          toJsonExpression: '',
        ),
    ],
  );
}
