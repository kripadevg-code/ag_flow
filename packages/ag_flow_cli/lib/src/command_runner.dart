import 'package:ag_flow_cli/src/commands/analyze_command.dart';
import 'package:ag_flow_cli/src/commands/generate_command.dart';
import 'package:ag_flow_cli/src/commands/init_command.dart';
import 'package:args/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';

/// The `ag` CLI's top-level command runner.
class AgCommandRunner extends CommandRunner<int> {
  AgCommandRunner({Logger? logger})
    : logger = logger ?? Logger(),
      super('ag', 'AG — opinionated Flutter/GetX module generator.') {
    argParser.addFlag(
      'dry-run',
      negatable: false,
      help: 'Print planned file operations without writing.',
    );
    addCommand(InitCommand(logger: this.logger));
    addCommand(GenerateCommand(logger: this.logger));
    addCommand(AnalyzeCommand(logger: this.logger));
  }

  final Logger logger;
}
