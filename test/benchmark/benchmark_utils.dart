// Benchmark utilities for CI performance testing

import 'dart:convert';
import 'dart:io';

/// Result of a single benchmark measurement.
class BenchmarkResult {
  BenchmarkResult({
    required this.name,
    required this.durationMs,
    required this.thresholdMs,
    this.frameCount,
    this.metadata,
  });

  final String name;
  final int durationMs;
  final int thresholdMs;
  final int? frameCount;
  final Map<String, dynamic>? metadata;

  bool get passed => durationMs <= thresholdMs;

  Map<String, dynamic> toJson() => {
    'name': name,
    'duration_ms': durationMs,
    'threshold_ms': thresholdMs,
    'passed': passed,
    if (frameCount != null) 'frame_count': frameCount,
    if (metadata != null) ...metadata!,
  };
}

/// Collects and reports benchmark results.
class BenchmarkReporter {
  BenchmarkReporter();

  final List<BenchmarkResult> _results = [];

  List<BenchmarkResult> get results => List.unmodifiable(_results);

  /// Records a benchmark result and prints it to console.
  void record(BenchmarkResult result) {
    _results.add(result);

    final status = result.passed ? '\u2713 PASS' : '\u2717 FAIL';
    final threshold = '(threshold: ${result.thresholdMs}ms)';

    // ignore: avoid_print - intentional output for CI logs
    print(
      'BENCHMARK: ${result.name} = ${result.durationMs}ms $status $threshold',
    );
  }

  /// Prints a summary of all benchmark results.
  void printSummary() {
    final separator = '\u2550' * 60;

    // ignore: avoid_print - intentional output for CI logs
    print('\n$separator');
    // ignore: avoid_print - intentional output for CI logs
    print('BENCHMARK SUMMARY');
    // ignore: avoid_print - intentional output for CI logs
    print(separator);

    for (final result in _results) {
      final status = result.passed ? '\u2713 PASS' : '\u2717 FAIL';
      final name = result.name.padRight(35);
      final duration = '${result.durationMs}ms'.padLeft(8);
      final threshold = '(< ${result.thresholdMs}ms)';

      // ignore: avoid_print - intentional output for CI logs
      print('$name $duration  $status $threshold');
    }

    // ignore: avoid_print - intentional output for CI logs
    print(separator);

    final passed = _results.where((r) => r.passed).length;
    final total = _results.length;
    final allPassed = passed == total;

    if (allPassed) {
      // ignore: avoid_print - intentional output for CI logs
      print('All $total benchmarks passed!');
    } else {
      // ignore: avoid_print - intentional output for CI logs
      print('$passed/$total benchmarks passed.');
    }

    // ignore: avoid_print - intentional output for CI logs
    print('');
  }

  /// Writes results to a JSON file for CI artifact upload.
  Future<void> writeResults(String filename) async {
    final file = File('build/$filename');
    await file.parent.create(recursive: true);
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert({
        'timestamp': DateTime.now().toIso8601String(),
        'summary': {
          'total': _results.length,
          'passed': _results.where((r) => r.passed).length,
          'failed': _results.where((r) => !r.passed).length,
        },
        'results': _results.map((r) => r.toJson()).toList(),
      }),
    );

    // ignore: avoid_print - intentional output for CI logs
    print('Results written to: build/$filename');
  }
}

/// Default performance thresholds for benchmarks.
///
/// These thresholds are calibrated to pass on CI runners (GitHub Actions
/// Ubuntu) which are typically 1.3-1.5x slower than local dev machines.
class BenchmarkThresholds {
  BenchmarkThresholds._();

  /// Maximum time for initial list build with 50 items.
  static const int listInitialBuildMs = 750;

  /// Maximum time for 10 scroll interactions.
  static const int listScrollMs = 450;

  /// Maximum time for a single widget build.
  static const int singleWidgetBuildMs = 75;

  /// Maximum time for tab navigation transition.
  static const int tabNavigationMs = 300;

  /// Maximum time for screen transition animation.
  static const int screenTransitionMs = 450;
}

/// Helper to measure execution time of a function.
Future<int> measureAsync(Future<void> Function() action) async {
  final stopwatch = Stopwatch()..start();
  await action();
  stopwatch.stop();
  return stopwatch.elapsedMilliseconds;
}

/// Synchronous version of measure.
int measure(void Function() action) {
  final stopwatch = Stopwatch()..start();
  action();
  stopwatch.stop();
  return stopwatch.elapsedMilliseconds;
}
