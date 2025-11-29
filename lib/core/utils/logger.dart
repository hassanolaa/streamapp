import 'dart:developer' as developer;

class Logger {
  static void log(String message, {String tag = 'APP'}) {
    developer.log('$tag: $message');
  }
}
