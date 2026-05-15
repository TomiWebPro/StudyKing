import 'package:flutter/foundation.dart';

enum LogLevel { debug, info, warn, error }

class Logger {
  final String tag;

  const Logger(this.tag);

  void d(String message) => _log(LogLevel.debug, message);
  void i(String message) => _log(LogLevel.info, message);
  void w(String message, [Object? error, StackTrace? stack]) => _log(LogLevel.warn, message, error, stack);
  void e(String message, [Object? error, StackTrace? stack]) => _log(LogLevel.error, message, error, stack);

  void _log(LogLevel level, String message, [Object? error, StackTrace? stack]) {
    if (!shouldLog(level)) return;
    final prefix = _prefix(level);
    final ts = DateTime.now().toIso8601String();
    final output = '[$ts][$prefix][$tag] $message';
    if (error != null) {
      final errorOutput = '$output\nError: $error';
      if (stack != null) {
        debugPrint('$errorOutput\nStack: $stack');
      } else {
        debugPrint(errorOutput);
      }
    } else {
      debugPrint(output);
    }
  }

  String _prefix(LogLevel level) {
    switch (level) {
      case LogLevel.debug: return 'D';
      case LogLevel.info:  return 'I';
      case LogLevel.warn:  return 'W';
      case LogLevel.error: return 'E';
    }
  }

  static bool _verbose = false;

  static void setVerbose(bool v) => _verbose = v;

  static bool shouldLog(LogLevel level) {
    if (level == LogLevel.error) return true;
    if (level == LogLevel.warn) return true;
    return _verbose;
  }
}
