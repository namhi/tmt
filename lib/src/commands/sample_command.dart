import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:process_run/shell.dart';

/// {@template sample_command}
///
/// `tmt sample`
/// A [Command] to exemplify a sub command
/// {@endtemplate}
class CommonCommand extends Command<int> {
  /// {@macro sample_command}
  CommonCommand({
    required Logger logger,
  }) : _logger = logger {
    argParser.addFlag(
      'build',
      abbr: 'b',
      help: 'Prints the same joke, but in cyan',
      negatable: false,
    );
  }

  @override
  String get description =>
      'Run fvm flutter pub get && fvm flutter pub build_runner build';

  @override
  String get name => 'build';

  final Logger _logger;

  @override
  Future<int> run() async {
    await Shell().run('fvm flutter pub get');
    await Shell().run('fvm flutter pub run build_runner build -d');
    _logger.info('output');
    return ExitCode.success.code;
  }
}
