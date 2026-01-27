// centralised logging service using dart logging package

import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

/// structured hierarchical logging for the app
class AppLogger {
  static late final Logger _rootLogger;
  static bool _initialized = false;

  /// call once at app startup
  static void initialize() {
    if (_initialized) return;

    Logger.root.level = kDebugMode ? Level.ALL : Level.INFO;

    Logger.root.onRecord.listen((record) {
      if (kDebugMode || record.level >= Level.WARNING) {
        final timestamp = record.time.toIso8601String();
        final level = record.level.name;
        final logger = record.loggerName;
        final message = record.message;

        var logLine = '$timestamp [$level] $logger: $message';

        if (record.error != null) {
          logLine += ' | Error: ${record.error}';
        }

        debugPrint(logLine);

        if (kDebugMode && record.stackTrace != null) {
          debugPrint('Stack trace: ${record.stackTrace}');
        }
      }
    });

    _rootLogger = Logger('ScoreCard');
    _initialized = true;
  }

  static Logger getLogger(String component) {
    if (!_initialized) initialize();
    return Logger('ScoreCard.$component');
  }

  // convenience methods for root logger
  static void debug(String message, {String? component, Object? data}) {
    final logger = component != null ? getLogger(component) : _rootLogger;
    if (data != null) {
      logger.fine('$message | Data: $data');
    } else {
      logger.fine(message);
    }
  }

  static void info(String message, {String? component, Object? data}) {
    final logger = component != null ? getLogger(component) : _rootLogger;
    if (data != null) {
      logger.info('$message | Data: $data');
    } else {
      logger.info(message);
    }
  }

  static void warning(String message, {String? component, Object? data}) {
    final logger = component != null ? getLogger(component) : _rootLogger;
    if (data != null) {
      logger.warning('$message | Data: $data');
    } else {
      logger.warning(message);
    }
  }

  static void error(
    String message, {
    String? component,
    Object? error,
    StackTrace? stackTrace,
  }) {
    (component != null ? getLogger(component) : _rootLogger).severe(
      message,
      error,
      stackTrace,
    );
  }

  static void gameEvent(String action, {Map<String, dynamic>? details}) {
    final logger = getLogger('GameEvents');
    var detailsStr = '';
    if (details != null) {
      final pairs = details.entries.map((e) => '${e.key}=${e.value}');
      detailsStr = ' | ${pairs.join(', ')}';
    }
    logger.fine('$action$detailsStr');
  }

  static void performance(
    String operation,
    Duration duration, {
    String? component,
  }) {
    getLogger(
      component ?? 'Performance',
    ).fine('$operation took ${duration.inMilliseconds}ms');
  }
}
