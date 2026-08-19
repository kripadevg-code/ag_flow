import 'dart:io';

import 'package:ag_flow_cli/src/command_runner.dart';
import 'package:args/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';

Future<void> main(List<String> args) async {
  final logger = Logger();
  final runner = AgCommandRunner(logger: logger);
  try {
    final exitCode = await runner.run(args);
    exit(exitCode ?? ExitCode.success.code);
  } on UsageException catch (e) {
    logger
      ..err(e.message)
      ..info(e.usage);
    exit(ExitCode.usage.code);
  }
}
