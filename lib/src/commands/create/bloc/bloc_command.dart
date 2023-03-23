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
    argParser
      ..addOption(
        'name',
        abbr: 'n',
        help: 'Assign name of bloc, example "product_list"',
        aliases: ['n'],
      )
      ..addFlag(
        'force',
        abbr: 'f',
        help: 'force overwrite file if true',
        aliases: ['f'],
      )
      ..addOption(
        'dependencies',
        help: 'Bloc dependencies, example "ProductRepository,LogService',
        aliases: ['dependencies'],
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
    var providerName = argResults?.rest.firstOrNull;
    final forceOverwrite = (argResults?['force'] as bool?) ?? false;
    final dependencies = _getDependencies(
      (argResults?['dependencies'] as String?) ?? '',
    );

    if (providerName == null) {
      _logger.info('Enter name of bloc:');
      providerName = stdin.readLineSync();
    }

    /// Lower under score convention
    final blocFileName = providerName!.toLowerUnderscore();

    /// Upper camel case convention
    final classNameSuffix = providerName.toUpperCamelCase();

    final currentDirectory = Directory.current;
    final directoryPath = currentDirectory.path;
    //await _createDirectoryIfNotExists(providerName, currentDirectory.path);
    // Create freezed state
    await _createStateFile(
      fileNameSuffix: blocFileName,
      classNameSuffix: classNameSuffix,
      directory: directoryPath,
      forceOverwrite: forceOverwrite,
    );
    await _createEventFile(
      fileNameSuffix: blocFileName,
      classNameSuffix: classNameSuffix,
      directory: directoryPath,
      forceOverwrite: forceOverwrite,
    );
    await _createNotificationFile(
      fileNameSuffix: blocFileName,
      classNameSuffix: classNameSuffix,
      directory: directoryPath,
      forceOverwrite: forceOverwrite,
    );
    await _createBlocFile(
      fileNameSuffix: blocFileName,
      classNameSuffix: classNameSuffix,
      directory: directoryPath,
      forceOverwrite: forceOverwrite,
      dependencies: dependencies,
    );

    return ExitCode.success.code;
  }

  Future<void> _createStateFile({
    required String fileNameSuffix,
    required String classNameSuffix,
    required String directory,
    required bool forceOverwrite,
  }) async {
    final fileName = '$directory/${fileNameSuffix}_state.dart';
    final className = '${classNameSuffix}State';
    final isFileExist = await _isFileExists(fileName);

    /// Nếu file chưa tồn tại hoặc yêu cầu ghi đè
    if (!isFileExist || forceOverwrite) {
      final file = await _createFile(fileName);
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
                ..redirect = Reference('_${classNameSuffix}State')
                ..optionalParameters = [
                  Parameter(
                    (p1) => p1
                      ..name = 'notification'
                      ..type = refer('${classNameSuffix}Notification?')
                      ..named = true,
                  ),
                  Parameter(
                    (p1) => p1
                      ..name = 'loadingStatus'
                      ..type = refer('LoadingStatus')
                      ..named = true
                      ..annotations = [
                        const Reference('Default(LoadingStatus.initial())'),
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
        ..writeln()
        ..writeln(content);

      await ioSink.close();
    } else {
      _logFileExist(fileName);
      return;
    }
  }

  Future<void> _createEventFile({
    required String fileNameSuffix,
    required String classNameSuffix,
    required String directory,
    required bool forceOverwrite,
  }) async {
    final fileName = '$directory/${fileNameSuffix}_event.dart';

    final isFileExist = await _isFileExists(fileName);

    if (!isFileExist || forceOverwrite) {
      final file = await _createFile(fileName);
      final ioSink = file.openWrite();

      var template = r'''
 part of '{FileSuffix}_bloc.dart';
 @Freezed()
    class {BlocName}Event with _${BlocName}Event {
      const factory {BlocName}Event.loaded() = _{BlocName}Loaded;
}

    ''';

      template = template
          .replaceAll('{BlocName}', classNameSuffix)
          .replaceAll('{FileSuffix}', fileNameSuffix);
      final content = DartFormatter().format(template);

      ioSink.writeln(content);
      await ioSink.close();
    } else {
      _logFileExist(fileName);
      return;
    }
  }

  Future<void> _createNotificationFile({
    required String fileNameSuffix,
    required String classNameSuffix,
    required String directory,
    required bool forceOverwrite,
  }) async {
    final fileName = '$directory/${fileNameSuffix}_notification.dart';
    final isFileExist = await _isFileExists(fileName);

    if (!isFileExist || forceOverwrite) {
      final file = await _createFile(fileName);
      final ioSink = file.openWrite();

      var template = r'''
   
part of '{FileSuffix}_bloc.dart';
  @Freezed(equal: false)
  class {BlocName}Notification with _${BlocName}Notification {
        
    factory {BlocName}Notification.showSuccessNotification({
    String? title,
    String? message,
  }) = _ShowSuccessNotification;
  
  factory {BlocName}Notification.showFailureNotification({
    String? title,
    String? message,
  }) = _ShowFailureNotification;
  }
   ''';

      template = template
          .replaceAll('{FileSuffix}', fileNameSuffix)
          .replaceAll('{BlocName}', classNameSuffix);
      final content = DartFormatter().format(template);

      ioSink.writeln(content);
      await ioSink.close();
    } else {
      _logFileExist(fileName);
      return;
    }
  }

  Future<void> _createBlocFile({
    required String fileNameSuffix,
    required String classNameSuffix,
    required String directory,
    required bool forceOverwrite,
    required List<String> dependencies,
  }) async {
    final fileName = '$directory/${fileNameSuffix}_bloc.dart';

    final isFileExist = await _isFileExists(fileName);

    if (!isFileExist || forceOverwrite) {
      final className = '${classNameSuffix}Bloc';
      final file = await _createFile(fileName);
      final ioSink = file.openWrite();

      final blocClass = Class(
        (p0) => p0
          ..name = className
          ..abstract = false
          ..extend = Reference(
            'Bloc<${classNameSuffix}Event, ${classNameSuffix}State>',
          )
          ..constructors = [
            Constructor(
              (p0) => p0
                ..factory = false
                ..initializers = [
                  Code('super(const ${classNameSuffix}State())'),
                ].build().toBuilder()
                ..optionalParameters = dependencies
                    .map(
                      (dependency) => Parameter(
                        (p0) => p0
                          ..name = dependency.toCamelCase()
                          ..type = Reference(dependency.toUpperCamelCase())
                          ..named = true
                          ..required = true,
                      ),
                    )
                    .toList()
                    .build()
                    .toBuilder()
                ..body = Block(
                  (p0) => p0
                    ..statements = (dependencies
                            .map(
                              (dependency) => Code(
                                '''_${dependency.toCamelCase()} = ${dependency.toCamelCase()};''',
                              ),
                            )
                            .toList()
                          ..add(
                            Code('''
              on<_${classNameSuffix}Loaded>(_onLoaded);
                  '''),
                          ))
                        .build()
                        .toBuilder(),
                ),
            ),
          ].build().toBuilder()
          ..fields = dependencies
              .map(
                (dependency) => Field(
                  (p0) => p0
                    ..name = '_${dependency.toCamelCase()}'
                    ..type = Reference(dependency.toUpperCamelCase())
                    ..modifier = FieldModifier.final$
                    ..late = true,
                ),
              )
              .toList()
              .build()
              .toBuilder()
          ..methods.add(
            Method(
              (p1) => p1
                ..name = '_onLoaded'
                ..returns = const Reference('FutureOr<void>')
                ..modifier = MethodModifier.async
                ..requiredParameters = [
                  Parameter(
                    (p0) => p0
                      ..name = 'event'
                      ..type = Reference('_${classNameSuffix}Loaded'),
                  ),
                  Parameter(
                    (p0) => p0
                      ..name = 'emit'
                      ..type = Reference('Emitter<${classNameSuffix}State>'),
                  ),
                ].build().toBuilder()
                ..body = const Code('''
              try {
      emit(
        state.copyWith(
          loadingStatus: LoadingStatus.loading(),
        ),
      );

      /// TODO: implement body
      await Future.delayed(const Duration(seconds: 3));

      emit(
        state.copyWith(
          loadingStatus: LoadingStatus.loadSuccess(),
        ),
      );
    } catch (e, s) {
      /// TODO: log exception
      emit(
        state.copyWith(
          loadingStatus: LoadingStatus.loadFailure(),
        ),
      );
    }
              '''),
            ),
          ),
      );

      final content = DartFormatter().format(
        '${blocClass.accept(DartEmitter.scoped(useNullSafetySyntax: true))}',
      );

      ioSink
        ..writeln(
          "import 'package:freezed_annotation/freezed_annotation.dart';",
        )
        ..writeln("import 'package:flutter_bloc/flutter_bloc.dart';")
        ..writeln("import 'dart:async';")
        ..writeln()
        ..writeln("part '${fileNameSuffix}_event.dart';")
        ..writeln("part '${fileNameSuffix}_state.dart';")
        ..writeln("part '${fileNameSuffix}_notification.dart';")
        ..writeln("part '${fileNameSuffix}_bloc.freezed.dart';")
        ..writeln()
        ..writeln(content);
      await ioSink.close();
    } else {
      _logFileExist(fileName);
      return;
    }
  }

  Future<File> _createFile(String fileName) async {
    final file = File(fileName);
    final isFileExists = file.existsSync();
    if (isFileExists == false) {
      // Create file
      await file.create();
      _logger.success('File $fileName created');
    } else {
      _logger.info('File $fileName overwrote');
    }

    return file;
  }

  void _logFileExist(String fileName) {
    _logger.warn(
      '''File $fileName existed, add flag --force to overwrite this file''',
    );
  }

  Future<bool> _isFileExists(String fileName) async {
    final file = File(fileName);
    final isFileExists = file.existsSync();
    return isFileExists;
  }

  List<String> _getDependencies(String text) {
    final words = text.split(',');
    final dependencies = <String>[];
    for (final w in words) {
      if (w.isNotEmpty) {
        dependencies.add(w.toLowerUnderscore());
      }
    }

    return dependencies;
  }

}
