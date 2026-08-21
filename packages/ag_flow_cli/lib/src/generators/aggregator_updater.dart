import 'dart:io';

import 'package:ag_flow_cli/src/generators/app_pages_updater.dart';
import 'package:ag_flow_cli/src/generators/app_routes_updater.dart';
import 'package:ag_flow_cli/src/generators/arguments_updater.dart';
import 'package:ag_flow_cli/src/generators/patch.dart';
import 'package:ag_flow_cli/src/generators/route_management_updater.dart';
import 'package:ag_flow_cli/src/io/file_op.dart';
import 'package:ag_flow_cli/src/io/project.dart';
import 'package:ag_flow_cli/src/naming/module_spec.dart';
import 'package:dart_style/dart_style.dart';
import 'package:path/path.dart' as p;

/// Thrown when an aggregator file (`arguments.dart`, `app_routes.dart`,
/// `app_pages.dart`, `route_management.dart`) doesn't exist yet — the
/// project hasn't run `ag init`.
class AggregatorFileNotFoundException implements Exception {
  const AggregatorFileNotFoundException(this.path);

  final String path;

  @override
  String toString() => 'ERROR: $path does not exist.\n\nRun "ag init" first.';
}

/// Plans idempotent updates to the shared aggregator files for [spec].
///
/// Requires the project to have already run `ag init` — these files are
/// expected to already exist with the standard skeleton (see
/// requirments/routes.md §2). `endpoints.dart` is deliberately not
/// touched here: it's `ag init`-scaffolded only, never auto-mutated
/// per-module (requirments/ag_endpoint_rules.md §2, §26).
class AggregatorUpdater {
  const AggregatorUpdater({required this.project});

  final Project project;

  static final _formatter = DartFormatter(
    languageVersion: DartFormatter.latestLanguageVersion,
  );

  List<FileOp> plan(ModuleSpec spec) {
    final appPackageName = project.packageName;
    final moduleImportPath = 'modules/${spec.modulePath.rootSegment}';

    final ops = <FileOp>[
      if (spec.isDetail)
        _planOne(
          relativePath: p.join('core', 'arguments', 'arguments.dart'),
          update: (source) => updateArguments(source, spec),
        ),
      _planOne(
        relativePath: p.join('core', 'routes', 'app_routes.dart'),
        update: (source) => updateAppRoutes(source, spec),
      ),
      _planOne(
        relativePath: p.join('core', 'routes', 'app_pages.dart'),
        update: (source) => updateAppPages(
          source,
          spec,
          appPackageName: appPackageName,
          moduleImportPath: moduleImportPath,
        ),
      ),
      _planOne(
        relativePath: p.join('core', 'routes', 'route_management.dart'),
        update: (source) =>
            updateRouteManagement(source, spec, appPackageName: appPackageName),
      ),
    ];

    return ops;
  }

  FileOp _planOne({
    required String relativePath,
    required AggregatorUpdateResult Function(String source) update,
  }) {
    final path = p.join(project.libDir.path, relativePath);
    final file = File(path);
    if (!file.existsSync()) {
      throw AggregatorFileNotFoundException(p.join('lib', relativePath));
    }

    final result = update(file.readAsStringSync());
    if (!result.changed) return FileOp.skipExisting(path: path);
    return FileOp.update(path: path, content: _formatter.format(result.source));
  }
}
