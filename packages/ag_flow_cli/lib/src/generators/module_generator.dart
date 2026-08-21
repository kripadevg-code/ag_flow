import 'dart:convert';
import 'dart:io';

import 'package:ag_flow_cli/src/generators/aggregator_updater.dart';
import 'package:ag_flow_cli/src/generators/import_utils.dart';
import 'package:ag_flow_cli/src/io/file_op.dart';
import 'package:ag_flow_cli/src/io/project.dart';
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
/// (`getPage`/`getByArgument`). `add` only applies to collection modules —
/// a detail module has no "create a new one" concept, so it's silently
/// dropped for those rather than treated as an error.
const generatableMethods = {'add', 'update', 'delete'};

class ModuleGenerator {
  ModuleGenerator({
    required this.project,
    this.pluralizer = defaultPluralizer,
    this.methods = generatableMethods,
  });

  final Project project;
  final Pluralizer pluralizer;

  /// Which of [generatableMethods] to generate stubs for, in addition to
  /// the always-present read method. Defaults to all of them — the whole
  /// point of a generator is to hand over more working boilerplate than
  /// a developer would've started from by hand, not less. Every
  /// generated method is a plain, fully-owned stub with no framework
  /// lock-in: delete whatever a module doesn't need, exactly as freely as
  /// any other generated code.
  final Set<String> methods;

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

    final vars = <String, dynamic>{
      'app_package_name': project.packageName,
      'module_import_path': 'modules/${modulePath.rootSegment}',
      'module_class_prefix': spec.classPrefix,
      'module_file_base': spec.layerFileBase,
      'component_class_prefix': spec.componentClassPrefix,
      'component_file_base': spec.fileBase,
      'component_namespace': spec.componentNamespace,
      'generate_add': methods.contains('add'),
      'generate_update': methods.contains('update'),
      'generate_delete': methods.contains('delete'),
    };

    final target = _RecordingGeneratorTarget();
    await generator.generate(target, vars: vars);

    final moduleRoot = project.moduleRootDir(modulePath.rootSegment);
    final ops = <FileOp>[];
    for (final entry in target.files.entries) {
      final outputPath = p.join(moduleRoot, entry.key);
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

    ops.addAll(AggregatorUpdater(project: project).plan(spec));
    return ops;
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
