import 'dart:io';

import 'package:ag_flow_cli/src/io/file_op.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:path/path.dart' as p;

/// Applies (or, under [dryRun], only reports) a list of [FileOp]s.
class Executor {
  const Executor({required this.dryRun, required this.logger});

  final bool dryRun;
  final Logger logger;

  /// Applies [ops] in order. Returns the number of files actually written
  /// (always 0 when [dryRun] is true).
  Future<int> execute(List<FileOp> ops) async {
    var written = 0;
    for (final op in ops) {
      switch (op.kind) {
        case FileOpKind.create:
          if (dryRun) {
            logger.info(
              '${lightGreen.wrap('would create')}  ${_relative(op.path)}',
            );
          } else {
            final file = File(op.path);
            await file.create(recursive: true);
            await file.writeAsString(op.content);
            if (op.executable) await _makeExecutable(file);
            logger.info('${lightGreen.wrap('create')}  ${_relative(op.path)}');
            written++;
          }
        case FileOpKind.update:
          if (dryRun) {
            logger.info(
              '${lightCyan.wrap('would update')}  ${_relative(op.path)}',
            );
          } else {
            await File(op.path).writeAsString(op.content);
            logger.info('${lightCyan.wrap('update')}  ${_relative(op.path)}');
            written++;
          }
        case FileOpKind.skipExisting:
          logger.detail(
            '${lightYellow.wrap('skip (exists)')}  ${_relative(op.path)}',
          );
      }
    }
    return written;
  }

  /// Git silently ignores a hook that isn't executable, so the bit has to
  /// be set at write time. No-op on Windows, which has no POSIX mode.
  Future<void> _makeExecutable(File file) async {
    if (Platform.isWindows) return;
    final result = await Process.run('chmod', ['+x', file.path]);
    if (result.exitCode != 0) {
      logger.detail('Could not mark ${file.path} executable: ${result.stderr}');
    }
  }

  String _relative(String path) =>
      p.relative(path, from: Directory.current.path);
}
