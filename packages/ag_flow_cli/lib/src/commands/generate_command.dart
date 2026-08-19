import 'package:ag_flow_cli/src/commands/module_command.dart';
import 'package:args/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';

/// `ag generate ...` (aliased `ag g ...`).
class GenerateCommand extends Command<int> {
  GenerateCommand({required Logger logger}) {
    addSubcommand(ModuleCommand(logger: logger));
  }

  @override
  final name = 'generate';

  @override
  final aliases = ['g'];

  @override
  final description = 'Generate framework artifacts.';
}
