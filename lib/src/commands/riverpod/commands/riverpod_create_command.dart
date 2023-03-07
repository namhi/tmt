import 'dart:async';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:built_collection/built_collection.dart';
import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:tmt_dart_utils/tmt_dart_extensions.dart';

class RiverpodCreateCommand extends Command<int> {
  /// {@macro sample_command}
  RiverpodCreateCommand({
    required Logger logger,
  }) : _logger = logger {
    argParser.addFlag(
      'name',
      abbr: 'n',
      help: 'Name of page',
      negatable: false,
    );
  }

  final Logger _logger;

  @override
  String get description => 'create riverpod file';

  @override
  String get name => 'create';

  @override
  FutureOr<int>? run() async {
    final providerName = argResults!.arguments.last.toLowerCase();
    final classSuffix =
        providerName.split('_').map((e) => e.capitalize()).join();
    final currentDirectory = Directory.current;
    final directoryPath = '${currentDirectory.path}/$providerName';
    await _createDirectoryIfNotExists(providerName, currentDirectory.path);
    // Create freezed state
    await _createStateFile(providerName, classSuffix, directoryPath);
    await _createEventFile(providerName, classSuffix, directoryPath);
    await _createNotificationFile(providerName, classSuffix, directoryPath);
    await _createNotifierFile(providerName, classSuffix, directoryPath);

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
                    ..name = 'screenState'
                    ..type = refer('ScreenState')
                    ..named = true
                    ..annotations = [
                      const Reference('Default(ScreenState.initial)'),
                    ].build().toBuilder(),
                )
              ].build().toBuilder(),
          ),
        ].build().toBuilder(),
    );

    final emitter = DartEmitter.scoped();
    final content = DartFormatter().format('${stateClass.accept(emitter)}');
    final ioSink = file.openWrite()
      ..writeln("import 'package:freezed_annotation/freezed_annotation.dart';")
      ..writeln("import '${fileNameSuffix}_notification.dart';")
      ..writeln("part '${fileNameSuffix}_state.freezed.dart';")
      ..writeln(content);

    await ioSink.close();
  }

  Future<void> _createEventFile(
      String fileSuffix, String classNameSuffix, String directory) async {
    final className = '${classNameSuffix}Event';
    final fileName = '$directory/${fileSuffix}_event.dart';
    final file = await _createFileIfNotExists(fileName);
    final ioSink = file.openWrite();

    final eventClass = Class(
      (p0) => p0
        ..name = className
        ..abstract = true
        ..methods.add(
          Method((p0) => p0
            ..name = 'onLoaded'
            ..returns = Reference('void')),
        ),
    );

    final content =
        DartFormatter().format('${eventClass.accept(DartEmitter.scoped())}');

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

    final eventClass = Class(
      (p0) => p0
        ..name = className
        ..abstract = true
        ..methods.add(
          Method((p0) => p0
            ..name = 'onLoaded'
            ..returns = Reference('void')),
        ),
    );

    final content =
        DartFormatter().format('${eventClass.accept(DartEmitter.scoped())}');

    ioSink.writeln(content);
    await ioSink.close();
  }

  Future<void> _createNotifierFile(
    String fileSuffix,
    String classNameSuffix,
    String directory,
  ) async {
    final className = '${classNameSuffix}Notifier';
    final fileName = '$directory/${fileSuffix}_notifier.dart';
    final file = await _createFileIfNotExists(fileName);
    final ioSink = file.openWrite();

    final eventClass = Class(
      (p0) => p0
        ..name = className
        ..abstract = false
        ..extend = Reference(
            'StateZ<${classNameSuffix}State, ${classNameSuffix}Notification>')
        ..implements = [
          Reference('${classNameSuffix}Event'),
        ].build().toBuilder()
        ..constructors = [
          Constructor(
            (p0) => p0
              ..factory = false
              ..initializers = [
                Code('super(const ${classNameSuffix}State())'),
              ].build().toBuilder(),
          ),
        ].build().toBuilder(),
    );

    final content =
        DartFormatter().format('${eventClass.accept(DartEmitter.scoped())}');

    ioSink
      ..writeln("import 'package:nmoney/application/core/statez.dart';")
      ..writeln("import '${fileSuffix}_state.dart';")
      ..writeln("import '${fileSuffix}_notification.dart';")
      ..writeln("import '${fileSuffix}_event.dart';")
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
