import 'package:logging/logging.dart';
import 'dart:developer' as developer;

final log = Logger('ChatBotLogger');

/*
This is the method that is called to setup the logger from the main.dart file.
We use the logger to log the messages of the app.
*/
void setupLogger() {
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    developer.log(
      record.message,
      name: record.loggerName,
      level: record.level.value,
      time: record.time,
      error: record.error,
      stackTrace: record.stackTrace,
    );
  });
}

