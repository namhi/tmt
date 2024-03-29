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
      'delete-conflicting-outputs',
      abbr: 'd',
      help: 'call --delete-conflicting-outputs in build',
      aliases: ['d'],
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
    final deleteConflictingOutput =
        (argResults?['delete-conflicting-outputs'] as bool?) ?? false;
    await Shell().run('fvm flutter pub get');
    final buildFlag = deleteConflictingOutput ? '-d' : '';
    await Shell().run('fvm flutter pub run build_runner build $buildFlag');
    _logger.info('output');
    return ExitCode.success.code;
  }
}
