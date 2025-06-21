import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

/// Centralized logging service for the Score Card app
/// Uses the official Dart logging package for structured, hierarchical logging
class AppLogger {
  static late final Logger _rootLogger;
  static bool _initialized = false;

  /// Initialize the logging system
  /// Should be called once at app startup
  static void initialize() {
    if (_initialized) return;

    // Set up hierarchical logging
    Logger.root.level = kDebugMode ? Level.ALL : Level.INFO;

    Logger.root.onRecord.listen((record) {
      // Only log in debug mode or for important messages
      if (kDebugMode || record.level >= Level.WARNING) {
        final timestamp = record.time.toIso8601String();
        final level = record.level.name;
        final logger = record.loggerName;
        final message = record.message;

        var logLine = '$timestamp [$level] $logger: $message';

        // Add error details if present
        if (record.error != null) {
          logLine += ' | Error: ${record.error}';
        }

        // Use debugPrint for console output
        debugPrint(logLine);

        // Print stack trace for errors in debug mode
        if (kDebugMode && record.stackTrace != null) {
          debugPrint('Stack trace: ${record.stackTrace}');
        }
      }
    });

    _rootLogger = Logger('ScoreCard');
    _initialized = true;
  }

  /// Get a logger for a specific component
  static Logger getLogger(String component) {
    if (!_initialized) initialize();
    return Logger('ScoreCard.$component');
  }

  // Convenience methods for the root logger
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
    final logger = component != null ? getLogger(component) : _rootLogger;
    logger.severe(message, error, stackTrace);
  }

  /// Log game events specifically
  static void gameEvent(String action, {Map<String, dynamic>? details}) {
    final logger = getLogger('GameEvents');
    final detailsStr =
        details != null
            ? ' | ${details.entries.map((e) => '${e.key}=${e.value}').join(', ')}'
            : '';
    logger.fine('$action$detailsStr');
  }

  /// Log performance metrics
  static void performance(
    String operation,
    Duration duration, {
    String? component,
  }) {
    final logger = getLogger(component ?? 'Performance');
    logger.fine('$operation took ${duration.inMilliseconds}ms');
  }
}
