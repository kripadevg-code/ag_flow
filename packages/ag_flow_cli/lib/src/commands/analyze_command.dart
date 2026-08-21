import 'dart:io';

import 'package:ag_flow_cli/src/analyze/analyze_issue.dart';
import 'package:ag_flow_cli/src/analyze/project_analyzer.dart';
import 'package:ag_flow_cli/src/io/project.dart';
import 'package:args/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:path/path.dart' as p;

/// `ag analyze` — validates a project against AG's structural rules.
class AnalyzeCommand extends Command<int> {
  AnalyzeCommand({required this.logger});

  final Logger logger;

  @override
  final name = 'analyze';

  @override
  final description =
      "Check this project against AG's structural rules (missing module "
      'files, missing route wiring, duplicate routes, nested architectural '
      'folders, hard-coded route strings, dependency-direction violations, '
      'unused detail arguments).';

  @override
  Future<int> run() async {
    final projectRoot = Directory.current;
    if (!File(p.join(projectRoot.path, 'pubspec.yaml')).existsSync()) {
      logger.err(
        'No pubspec.yaml found in ${projectRoot.path} — is this a Dart/Flutter project?',
      );
      return ExitCode.usage.code;
    }

    final analyzer = ProjectAnalyzer(project: Project(projectRoot));
    final List<AnalyzeIssue> issues;
    try {
      issues = await analyzer.analyze();
    } on ProjectNotInitializedException catch (e) {
      logger.err('$e');
      return ExitCode.config.code;
    }

    if (issues.isEmpty) {
      logger.success('No issues found.');
    } else {
      for (final issue in issues) {
        logger.err('$issue');
      }
      logger.info('\n${issues.length} issue(s) found.');
    }

    if (!await analyzer.dependenciesResolved) {
      logger.info(
        '\nNote: dependency-direction and unused-detail-argument checks '
        'were skipped — run "dart pub get" (or "flutter pub get") first '
        'to enable them.',
      );
    }

    return issues.isEmpty ? ExitCode.success.code : ExitCode.software.code;
  }
}
