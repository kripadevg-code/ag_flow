import 'dart:io';

import 'package:ag_flow_cli/src/command_runner.dart';
import 'package:ag_flow_cli/src/version.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  group('AgCommandRunner', () {
    test('--version exits successfully with no sub-command', () async {
      // A script probing for this tool runs `--version` first (the
      // generated pre-commit hook does exactly that), so it has to work
      // with no sub-command and exit 0.
      final code = await AgCommandRunner(
        logger: Logger(level: Level.quiet),
      ).run(['--version']);

      expect(code, ExitCode.success.code);
    });

    test('-v is accepted as the short form', () async {
      final code = await AgCommandRunner(
        logger: Logger(level: Level.quiet),
      ).run(['-v']);

      expect(code, ExitCode.success.code);
    });

    test('the declared version matches the pubspec', () {
      expect(
        agCliVersion,
        _readPubspecVersion(),
        reason:
            'version.dart is hard-coded and must be kept in sync with '
            'pubspec.yaml — a stale `ag --version` is worse than none',
      );
    });
  });
}

String _readPubspecVersion() {
  // Find the ag_flow_cli package root regardless of where the test is
  // invoked from (package root via `dart test`, workspace root via
  // `melos run test:cli`, or workspace root via `dart test packages/...`).
  final pubspec = _findPubspec('ag_flow_cli');
  final lines = pubspec.readAsLinesSync();
  final line = lines.firstWhere((l) => l.startsWith('version:'));
  return line.split(':').last.trim();
}

/// Walks from [Directory.current] upward until it finds a pubspec.yaml
/// whose `name:` field matches [packageName].
File _findPubspec(String packageName) {
  var dir = Directory.current;
  while (true) {
    final candidate = File(p.join(dir.path, 'pubspec.yaml'));
    if (candidate.existsSync() &&
        candidate.readAsStringSync().contains('name: $packageName')) {
      return candidate;
    }
    // Search up to 2 levels of subdirectories (covers both package-root
    // and workspace-root invocations where packages live at packages/foo/).
    for (final entry1 in dir.listSync().whereType<Directory>()) {
      final sub1 = File(p.join(entry1.path, 'pubspec.yaml'));
      if (sub1.existsSync() &&
          sub1.readAsStringSync().contains('name: $packageName')) {
        return sub1;
      }
      for (final entry2 in entry1.listSync().whereType<Directory>()) {
        final sub2 = File(p.join(entry2.path, 'pubspec.yaml'));
        if (sub2.existsSync() &&
            sub2.readAsStringSync().contains('name: $packageName')) {
          return sub2;
        }
      }
    }
    final parent = dir.parent;
    if (parent.path == dir.path) break;
    dir = parent;
  }
  throw StateError('Could not find pubspec.yaml for package $packageName');
}
