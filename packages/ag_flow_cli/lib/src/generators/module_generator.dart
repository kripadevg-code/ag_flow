import 'dart:convert';
import 'dart:io';

import 'package:ag_flow_cli/src/generators/aggregator_updater.dart';
import 'package:ag_flow_cli/src/generators/import_utils.dart';
import 'package:ag_flow_cli/src/generators/model_generator.dart';
import 'package:ag_flow_cli/src/io/file_op.dart';
import 'package:ag_flow_cli/src/io/project.dart';
import 'package:ag_flow_cli/src/naming/model_spec.dart';
import 'package:ag_flow_cli/src/naming/module_path.dart';
import 'package:ag_flow_cli/src/naming/module_spec.dart';
import 'package:ag_flow_cli/src/naming/pluralizer.dart';
import 'package:ag_flow_cli/src/templates/generated/collection_module_bundle.dart';
import 'package:ag_flow_cli/src/templates/generated/detail_module_bundle.dart';
import 'package:dart_style/dart_style.dart';
import 'package:mason/mason.dart';
import 'package:path/path.dart' as p;

/// Thrown when generating a child/detail module whose parent module
/// doesn't exist yet (requirments/ag_framework.md §9). The CLI must
/// report this and write nothing, rather than silently creating an
/// invalid hierarchy.
class ParentModuleNotFoundException implements Exception {
  const ParentModuleNotFoundException(this.parentPath);

  final ModulePath parentPath;

  @override
  String toString() {
    return 'ERROR: Parent module "${parentPath.asString}" does not exist.\n'
        '\n'
        'Create it first:\n'
        '\n'
        'ag g m ${parentPath.asString}';
  }
}

/// Generates a new module's fresh page/controller/repo/service/binding/
/// component files, and idempotently wires it into the shared aggregator
/// files (`app_routes.dart`, `app_pages.dart`, `route_management.dart`,
/// and — for detail modules — `arguments.dart`) via [AggregatorUpdater].
/// The aggregator files must already exist (`ag init`); see
/// [AggregatorFileNotFoundException].
/// The mutation-method stubs `ModuleGenerator` can generate across
/// Service/Repo/Controller, beyond the always-present read method
/// (`list`/`retrieve`), named after the Service action mixins they
/// implement. `create` only applies to collection modules — a detail
/// module has no "create a new one" concept, so it's silently dropped for
/// those rather than treated as an error.
const generatableMethods = {'create', 'update', 'destroy'};

class ModuleGenerator {
  ModuleGenerator({
    required this.project,
    this.pluralizer = defaultPluralizer,
    this.methods = generatableMethods,
    this.model,
    this.paginate = false,
  });

  final Project project;
  final Pluralizer pluralizer;

  /// The module's model type, when one was requested via `--model` or
  /// inferred from `--from-json`.
  ///
  /// Null means the generated stack is typed `dynamic`, exactly as it
  /// always was — the whole model feature is additive, and a module
  /// generated without one is byte-for-byte what it used to be. With a
  /// model, the real type is threaded through Service, Repo, Controller,
  /// Page and the item component, and the model class itself is
  /// generated, so a fresh module compiles against real data instead of
  /// handing the developer a list of `dynamic`s to replace.
  final ModelSpec? model;

  /// Which of [generatableMethods] to generate stubs for, in addition to
  /// the always-present read method. Defaults to all of them — the whole
  /// point of a generator is to hand over more working boilerplate than
  /// a developer would've started from by hand, not less. Every
  /// generated method is a plain, fully-owned stub with no framework
  /// lock-in: delete whatever a module doesn't need, exactly as freely as
  /// any other generated code.
  final Set<String> methods;

  /// Whether a collection module's list pages: the Service declares an
  /// `AgPagination` and the Controller mixes in `AgLoadMore`. Off by
  /// default — paging is opt-in, the same as in the framework. Ignored
  /// for detail modules.
  final bool paginate;

  static final _formatter = DartFormatter(
    languageVersion: DartFormatter.latestLanguageVersion,
  );

  /// Plans the file operations for generating [modulePath], without
  /// writing anything. Throws [ParentModuleNotFoundException] if this is
  /// a non-root module whose parent hasn't been generated yet.
  Future<List<FileOp>> plan(ModulePath modulePath) async {
    final parent = modulePath.parent;
    if (parent != null) {
      final parentSpec = ModuleSpec.from(parent, pluralizer: pluralizer);
      final parentControllerPath = p.join(
        project.moduleRootDir(parent.rootSegment),
        'controllers',
        parentSpec.controllerFile,
      );
      if (!File(parentControllerPath).existsSync()) {
        throw ParentModuleNotFoundException(parent);
      }
    }

    final spec = ModuleSpec.from(modulePath, pluralizer: pluralizer);
    final bundle = spec.isDetail ? detailModuleBundle : collectionModuleBundle;
    final generator = await MasonGenerator.fromBundle(bundle);

    final model = this.model;
    final vars = <String, dynamic>{
      'app_package_name': project.packageName,
      'module_import_path': 'modules/${modulePath.rootSegment}',
      'has_model': model != null,
      'model_class': model?.className ?? 'dynamic',
      'model_file_base': model?.fileBase ?? 'model',
      'id_type': model?.idType ?? 'Object',
      'lookup_id_expression': _lookupIdExpression(model, spec.controllerClass),
      'module_class_prefix': spec.classPrefix,
      'module_file_base': spec.layerFileBase,
      'component_class_prefix': spec.componentClassPrefix,
      'component_file_base': spec.fileBase,
      'component_namespace': spec.componentNamespace,
      'generate_create': methods.contains('create'),
      'generate_update': methods.contains('update'),
      'generate_destroy': methods.contains('destroy'),
      'paginate': paginate,
      // Mustache has no `||`, and each action mixin the Service lists
      // declares only what it uses — so these decide whether the Service
      // declares `resourceEndpoint`/`toJson` at all. Declaring one that no
      // generated method uses would hand the developer dead code.
      'needs_resource_endpoint':
          spec.isDetail || methods.contains('update') || methods.contains('destroy'),
      'needs_to_json': methods.contains('update') || (!spec.isDetail && methods.contains('create')),
    };

    final target = _RecordingGeneratorTarget();
    await generator.generate(target, vars: vars);

    final moduleRoot = project.moduleRootDir(modulePath.rootSegment);
    final testRoot = project.moduleTestDir(modulePath.rootSegment);
    final ops = <FileOp>[];
    for (final entry in target.files.entries) {
      // A brick's `test/` files are the module's starter tests; they go
      // under the app's own test/ directory, not inside lib/.
      final outputPath = p.isWithin('test', entry.key)
          ? p.join(testRoot, p.relative(entry.key, from: 'test'))
          : p.join(moduleRoot, entry.key);
      if (File(outputPath).existsSync()) {
        ops.add(FileOp.skipExisting(path: outputPath));
        continue;
      }
      ops.add(
        FileOp.create(
          path: outputPath,
          content: _formatter.format(sortImports(entry.value)),
        ),
      );
    }

    if (model != null) {
      final modelPath = p.join(moduleRoot, 'models', '${model.fileBase}.dart');
      // Skipped when it already exists, like every other generated file:
      // a detail module generated after its parent shares the parent's
      // model rather than overwriting an edited one.
      ops.add(
        File(modelPath).existsSync()
            ? FileOp.skipExisting(path: modelPath)
            : FileOp.create(
                path: modelPath,
                content: _formatter.format(renderModel(model)),
              ),
      );
    }

    ops.addAll(AggregatorUpdater(project: project).plan(spec));
    return ops;
  }

  /// How a detail Controller turns its page argument into the lookup —
  /// DRF's `lookup_field`.
  ///
  /// Path parameters are always strings, so a model whose id is an `int`
  /// needs the parse written for it — that conversion is the one piece a
  /// developer would otherwise have to remember on every detail module.
  /// Untyped, the id type is `Object`, which the string itself already is.
  static String _lookupIdExpression(ModelSpec? model, String controllerClass) {
    switch (model?.idType) {
      case null || 'String' || 'Object':
        return 'argument.id';
      case 'int':
        return 'int.parse(argument.id)';
      default:
        return "throw UnimplementedError('$controllerClass.lookupId — "
            "convert argument.id to ${model!.idType}.')";
    }
  }
}

/// Records rendered files in memory instead of writing them to disk — lets
/// [ModuleGenerator] decide (formatting, existence checks, `--dry-run`)
/// what actually reaches the filesystem, and keeps the generator itself
/// unit-testable without one.
class _RecordingGeneratorTarget implements GeneratorTarget {
  final Map<String, String> files = {};
  @override
  Future<GeneratedFile> createFile(
    String path,
    List<int> contents, {
    Logger? logger,
    OverwriteRule? overwriteRule,
  }) async {
    files[path] = utf8.decode(contents);
    return GeneratedFile.created(path: path);
  }
}
