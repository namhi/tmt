import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';

import 'commands/riverpod_create_command.dart';

/// {@template sample_command}
///
/// `tmt sample`
/// A [Command] to exemplify a sub command
/// {@endtemplate}
class RiverPodCommand extends Command<int> {
  /// {@macro sample_command}
  RiverPodCommand({
    required Logger logger,
  }) : _logger = logger {
    addSubcommand(RiverpodCreateCommand(logger: logger));
    argParser
      ..addFlag(
        'create',
        abbr: 'c',
        help: 'Create riverpod file',
        negatable: false,
      )
      ..addFlag(
        'name',
        abbr: 'n',
        help: 'Name of page',
        negatable: false,
      );
  }

  @override
  String get description => 'Create RiverPod file for state managament';

  @override
  String get name => 'riverpod';

  final Logger _logger;

  @override
  Future<int> run() async {
    // var output = 'Which unicorn has a cold? The Achoo-nicorn!';
    // if (argResults?['cyan'] == true) {
    //   output = lightCyan.wrap(output)!;
    // }
    // _logger.info(output);

    // if (argResults?['create'] == true) {
    // Create file in current directory
    //final directoryName = argResults?[''];

    print(argResults?.arguments);

    return ExitCode.success.code;
  }
}
