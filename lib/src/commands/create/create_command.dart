import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:tmt/src/commands/create/bloc_command.dart';

/// {@template sample_command}
///
/// `tmt sample`
/// A [Command] to exemplify a sub command
/// {@endtemplate}
class CreateCommand extends Command<int> {
  /// {@macro sample_command}
  CreateCommand({
    required Logger logger,
  }) : _logger = logger {
    addSubcommand(BlocCommand(logger: logger));
  }

  @override
  String get description => 'Create RiverPod file for state managament';

  @override
  String get name => 'create';

  final Logger _logger;

  @override
  Future<int> run() async {
    print(argResults?.arguments);
    return ExitCode.success.code;
  }
}
