import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:built_collection/built_collection.dart';
import 'package:code_builder/code_builder.dart';
import 'package:collection/collection.dart';
import 'package:dart_style/dart_style.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:tmt_dart_utils/tmt_dart_extensions.dart';

/// {@template sample_command}
///
/// `tmt sample`
/// A [Command] to exemplify a sub command
/// {@endtemplate}
class BlocCommand extends Command<int> {
  /// {@macro sample_command}
  BlocCommand({
    required Logger logger,
  }) : _logger = logger {
    argParser.addOption(
      'name',
      abbr: 'n',
      help: 'bloc name example "product_list"',
      aliases: ['n'],
    );
  }

  @override
  String get description =>
      'Create basic bloc class state,event,bloc, notification';

  @override
  String get name => 'bloc';

  final Logger _logger;

  @override
  Future<int> run() async {
    var providerName = argResults?.rest.firstOrNull?.toLowerCase();

    if (providerName == null) {
      _logger.info('Enter name of bloc:');
      providerName = stdin.readLineSync();
    }
    final classSuffix =
        providerName!.split('_').map((e) => e.capitalize()).join();
    final currentDirectory = Directory.current;
    final directoryPath = currentDirectory.path;
    //await _createDirectoryIfNotExists(providerName, currentDirectory.path);
    // Create freezed state
    await _createStateFile(providerName, classSuffix, directoryPath);
    await _createEventFile(providerName, classSuffix, directoryPath);
    await _createNotificationFile(providerName, classSuffix, directoryPath);
    await _createBlocFile(providerName, classSuffix, directoryPath);

    return ExitCode.success.code;

    _logger.info('output');
    return ExitCode.success.code;
  }

  Future<void> _createStateFile(
      String fileNameSuffix, String classSuffix, String directory) async {
    final fileName = '$directory/${fileNameSuffix}_state.dart';
    final className = '${classSuffix}State';
    final file = await _createFileIfNotExists(fileName);

    // Create content

    final stateClass = Class(
      (p) => p
        ..name = className
        ..mixins = (ListBuilder<Reference>()
          ..add(
            Reference('_\$$className'),
          ))
        ..annotations =
            (ListBuilder<Expression>()..add(const Reference('Freezed()')))
        ..constructors = [
          Constructor(
            (p0) => p0
              ..constant = true
              ..factory = true
              ..redirect = Reference('_${classSuffix}State')
              ..optionalParameters = [
                Parameter(
                  (p1) => p1
                    ..name = 'notification'
                    ..type = refer('${classSuffix}Notification?')
                    ..named = true,
                ),
                Parameter(
                  (p1) => p1
                    ..name = 'uiStatus'
                    ..type = refer('UIStatus')
                    ..named = true
                    ..annotations = [
                      const Reference('Default(UIStatus.initial)'),
                    ].build().toBuilder(),
                )
              ].build().toBuilder(),
          ),
        ].build().toBuilder(),
    );

    final emitter = DartEmitter.scoped();
    final content = DartFormatter().format('${stateClass.accept(emitter)}');
    final ioSink = file.openWrite()
      ..writeln("part of '${fileNameSuffix}_bloc.dart';")
      ..writeln(content);

    await ioSink.close();
  }

  Future<void> _createEventFile(
      String fileSuffix, String classNameSuffix, String directory) async {
    final className = '${classNameSuffix}Event';
    final fileName = '$directory/${fileSuffix}_event.dart';
    final file = await _createFileIfNotExists(fileName);
    final ioSink = file.openWrite();

    var template = r'''
 part of '{FileSuffix}_bloc.dart';
 @freezed
    class {BlocName}Event with _${BlocName}Event {
      const factory {BlocName}Event.loaded() = _{BlocName}Loaded;
}

    ''';

    template = template
        .replaceAll('{BlocName}', classNameSuffix)
        .replaceAll('{FileSuffix}', fileSuffix);
    final content = DartFormatter().format(template);

    ioSink.writeln(content);
    await ioSink.close();
  }

  Future<void> _createNotificationFile(
    String fileSuffix,
    String classNameSuffix,
    String directory,
  ) async {
    final className = '${classNameSuffix}Notification';
    final fileName = '$directory/${fileSuffix}_notification.dart';
    final file = await _createFileIfNotExists(fileName);
    final ioSink = file.openWrite();

    var template = r'''
   
part of '{FileSuffix}_bloc.dart';
  @Freezed()
  class {BlocName}Notification with _${BlocName}Notification {
    factory {BlocName}Notification.showNotification(String title, String message) =
        _ShowNotification;
  }
   ''';

    template = template
        .replaceAll('{FileSuffix}', fileSuffix)
        .replaceAll('{BlocName}', classNameSuffix);
    final content = DartFormatter().format(template);

    ioSink.writeln(content);
    await ioSink.close();
  }

  Future<void> _createBlocFile(
    String fileSuffix,
    String classNameSuffix,
    String directory,
  ) async {
    final className = '${classNameSuffix}Bloc';
    final fileName = '$directory/${fileSuffix}_bloc.dart';
    final file = await _createFileIfNotExists(fileName);
    final ioSink = file.openWrite();

    final eventClass = Class(
      (p0) => p0
        ..name = className
        ..abstract = false
        ..extend =
            Reference('Bloc<${classNameSuffix}Event, ${classNameSuffix}State>')
        ..constructors = [
          Constructor(
            (p0) => p0
              ..factory = false
              ..initializers = [
                Code('super(const ${classNameSuffix}State())'),
              ].build().toBuilder()
              ..body = Code('''
              on<_${classNameSuffix}Loaded>(_onLoaded);
                  '''),
          ),
        ].build().toBuilder()
        ..methods.add(
          Method(
            (p1) => p1
              ..name = '_onLoaded'
              ..returns = const Reference('FutureOr<void>')
              ..requiredParameters = [
                Parameter((p0) => p0
                  ..name = 'event'
                  ..type = Reference('_${classNameSuffix}Loaded')),
                Parameter((p0) => p0
                  ..name = 'emit'
                  ..type = Reference('Emitter<${classNameSuffix}State>')),
              ].build().toBuilder()
              ..body = const Code(' '),
          ),
        ),
    );

    final content =
        DartFormatter().format('${eventClass.accept(DartEmitter.scoped())}');

    ioSink
      ..writeln("import 'package:freezed_annotation/freezed_annotation.dart';")
      ..writeln("import 'package:bloc/bloc.dart';")
      ..writeln("import 'dart:async';")
      ..writeln("part '${fileSuffix}_event.dart';")
      ..writeln("part '${fileSuffix}_state.dart';")
      ..writeln("part '${fileSuffix}_notification.dart';")
      ..writeln("part '${fileSuffix}_bloc.freezed.dart';")
      ..writeln(content);
    await ioSink.close();
  }

  Future<File> _createFileIfNotExists(String fileName) async {
    final file = File(fileName);
    final isFileExists = file.existsSync();
    if (isFileExists == false) {
      // Create file
      await file.create();
      _logger.info('File $fileName created');
    } else {
      _logger.info('File $fileName existed');
    }

    return file;
  }

  Future<void> _createDirectoryIfNotExists(
      String path, String parentPath) async {
    final directory = Directory('$parentPath/$path');
    if (!directory.existsSync()) {
      await directory.create();
      _logger.info('Create directory : $path');
    } else {
      _logger.info('Directory $path is already exists');
    }
  }
}
