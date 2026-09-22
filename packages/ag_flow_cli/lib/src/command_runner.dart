import 'package:ag_flow_cli/src/commands/analyze_command.dart';
import 'package:ag_flow_cli/src/commands/generate_command.dart';
import 'package:ag_flow_cli/src/commands/init_command.dart';
import 'package:ag_flow_cli/src/version.dart';
import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';

/// The `ag` CLI's top-level command runner.
class AgCommandRunner extends CommandRunner<int> {
  AgCommandRunner({Logger? logger})
    : logger = logger ?? Logger(),
      super('ag', 'AG — opinionated Flutter module generator.') {
    argParser
      ..addFlag(
        'dry-run',
        negatable: false,
        help: 'Print planned file operations without writing.',
      )
      ..addFlag(
        'version',
        abbr: 'v',
        negatable: false,
        help: "Print this CLI's version.",
      );
    addCommand(InitCommand(logger: this.logger));
    addCommand(GenerateCommand(logger: this.logger));
    addCommand(AnalyzeCommand(logger: this.logger));
  }

  final Logger logger;

  @override
  Future<int?> runCommand(ArgResults topLevelResults) async {
    // Handled here rather than as a command so `ag --version` works with
    // no sub-command, which is what every other CLI does — and what a
    // script probing for this tool's presence will try first.
    if (topLevelResults['version'] as bool) {
      logger.info('ag $agCliVersion');
      return ExitCode.success.code;
    }
    return super.runCommand(topLevelResults);
  }
}
