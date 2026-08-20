import 'dart:convert';
import 'dart:io';

import 'package:ag_flow_cli/src/templates/generated/collection_module_bundle.dart';
import 'package:ag_flow_cli/src/templates/generated/detail_module_bundle.dart';
import 'package:mason/mason.dart';
import 'package:path/path.dart' as p;

/// CI guard: fails if `bricks/*/__brick__/**` has been edited without
/// re-bundling into `lib/src/templates/generated/*.dart`.
///
/// `ag_flow_cli` loads only the committed bundle at runtime
/// (`MasonGenerator.fromBundle`, see CLAUDE.md) — an edited-but-not-
/// rebundled brick source has no other signal that it's stale, since the
/// bundle is plain committed Dart source, not derived at build time.
/// Compares every bundled file's decoded bytes against the corresponding
/// file on disk under `bricks/<name>/__brick__/`, plus the file set
/// itself (added/removed template files count as stale too).
final Map<String, MasonBundle> _bricks = {
  'collection_module': collectionModuleBundle,
  'detail_module': detailModuleBundle,
};

void main() {
  final packageRoot = _packageRoot();
  var stale = false;

  for (final entry in _bricks.entries) {
    final brickDir = Directory(
      p.join(packageRoot.path, 'bricks', entry.key, '__brick__'),
    );
    final onDisk = _filesOnDisk(brickDir);
    final inBundle = <String, List<int>>{
      for (final MasonBundledFile file in entry.value.files)
        file.path: base64.decode(file.data),
    };

    final onlyOnDisk = onDisk.keys.toSet().difference(inBundle.keys.toSet());
    final onlyInBundle = inBundle.keys.toSet().difference(onDisk.keys.toSet());
    if (onlyOnDisk.isNotEmpty || onlyInBundle.isNotEmpty) {
      stale = true;
      stderr.writeln('STALE: ${entry.key} — file set differs.');
      for (final path in onlyOnDisk) {
        stderr.writeln('  only on disk (not in the bundle): $path');
      }
      for (final path in onlyInBundle) {
        stderr.writeln('  only in the bundle (not on disk): $path');
      }
      continue;
    }

    for (final path in onDisk.keys) {
      if (!_bytesEqual(onDisk[path]!, inBundle[path]!)) {
        stale = true;
        stderr.writeln(
          'STALE: ${entry.key} — $path differs from the committed bundle.',
        );
      }
    }
  }

  if (stale) {
    stderr.writeln(
      '\nRe-bundle before committing:\n'
      '  cd packages/ag_flow_cli\n'
      '  mason bundle bricks/<brick_name> -t dart -o lib/src/templates/generated/',
    );
    exitCode = 1;
    return;
  }

  stdout.writeln('All brick bundles are fresh.');
}

/// Every file under [brickDir], keyed by its path relative to it, using
/// forward slashes — matching the path format Mason bundles files under
/// (`bricks/<name>/__brick__/bindings/{{module_file_base}}_binding.dart`
/// is bundled as `bindings/{{module_file_base}}_binding.dart`).
Map<String, List<int>> _filesOnDisk(Directory brickDir) {
  final files = <String, List<int>>{};
  for (final entity in brickDir.listSync(recursive: true)) {
    if (entity is! File) continue;
    final relativePath = p
        .relative(entity.path, from: brickDir.path)
        .split(p.separator)
        .join('/');
    files[relativePath] = entity.readAsBytesSync();
  }
  return files;
}

bool _bytesEqual(List<int> a, List<int> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

/// The `ag_flow_cli` package root — this script's own directory's parent,
/// so it works regardless of the working directory it's invoked from.
Directory _packageRoot() {
  final scriptPath = Platform.script.toFilePath();
  return Directory(p.dirname(p.dirname(scriptPath)));
}
