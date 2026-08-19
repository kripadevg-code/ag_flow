import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

/// The target Flutter/Dart project `ag` is generating into.
class Project {
  Project(this.root);

  /// The project's root directory (containing its `pubspec.yaml`).
  final Directory root;

  /// The project's own package name, read from its `pubspec.yaml`
  /// `name:` field — used to build `package:<name>/...` imports in
  /// generated code.
  String get packageName {
    final pubspecFile = File(p.join(root.path, 'pubspec.yaml'));
    if (!pubspecFile.existsSync()) {
      throw StateError(
        'No pubspec.yaml found at ${pubspecFile.path} — is this a Dart/Flutter project?',
      );
    }
    final doc = loadYaml(pubspecFile.readAsStringSync());
    final name = doc is YamlMap ? doc['name'] : null;
    if (name is! String || name.isEmpty) {
      throw StateError('${pubspecFile.path} has no top-level "name:" field.');
    }
    return name;
  }

  /// The project's `lib/` directory.
  Directory get libDir => Directory(p.join(root.path, 'lib'));

  /// The absolute path to a root module segment's directory, e.g.
  /// `<root>/lib/product`. Every module sharing this root segment — no
  /// matter how deeply nested — places its files here, flat by layer (see
  /// requirments/ag_framework.md §6/§72).
  String moduleRootDir(String rootSegment) => p.join(libDir.path, rootSegment);
}
