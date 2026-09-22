import 'dart:io';

import 'package:ag_flow_cli/src/command_runner.dart';
import 'package:ag_flow_cli/src/version.dart';
import 'package:mason_logger/mason_logger.dart';
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
  final lines = File('pubspec.yaml').readAsLinesSync();
  final line = lines.firstWhere((l) => l.startsWith('version:'));
  return line.split(':').last.trim();
}
