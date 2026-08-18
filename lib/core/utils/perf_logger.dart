import 'package:flutter/foundation.dart';

/// Lightweight development-only performance tracer for measuring Firestore and async operations.
/// Does not add overhead in release mode.
class PerfLogger {
  PerfLogger._();

  static T traceSync<T>(String operationName, T Function() block) {
    if (!kDebugMode) return block();
    final sw = Stopwatch()..start();
    debugPrint('[PERF] $operationName START');
    try {
      final result = block();
      sw.stop();
      debugPrint('[PERF] $operationName END = ${sw.elapsedMilliseconds}ms');
      return result;
    } catch (e) {
      sw.stop();
      debugPrint('[PERF] $operationName ERROR (${sw.elapsedMilliseconds}ms): $e');
      rethrow;
    }
  }

  static Future<T> traceAsync<T>(String operationName, Future<T> Function() block) async {
    if (!kDebugMode) return await block();
    final sw = Stopwatch()..start();
    debugPrint('[PERF] $operationName START');
    try {
      final result = await block();
      sw.stop();
      debugPrint('[PERF] $operationName END = ${sw.elapsedMilliseconds}ms');
      return result;
    } catch (e) {
      sw.stop();
      debugPrint('[PERF] $operationName ERROR (${sw.elapsedMilliseconds}ms): $e');
      rethrow;
    }
  }
}
