import 'dart:io';

import 'package:ag_flow_cli/src/mcp/ag_mcp_server.dart';
import 'package:args/command_runner.dart';
import 'package:dart_mcp/stdio.dart';
import 'package:mason_logger/mason_logger.dart';

/// `ag mcp` — serves AG's generator and analyzer to a coding agent as an
/// MCP server over stdio. Local only: nothing is sent over the network.
class McpCommand extends Command<int> {
  @override
  final name = 'mcp';

  @override
  final description =
      'Run the AG MCP server over stdio, so a coding agent can read the '
      'architecture rules, generate modules and run ag analyze as tools.';

  @override
  Future<int> run() async {
    // stdout is the protocol channel from here on — nothing else may print.
    final server = AgMcpServer(stdioChannel(input: stdin, output: stdout));
    await server.done;
    return ExitCode.success.code;
  }
}
