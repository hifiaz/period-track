import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Service for optimizing app performance, memory usage, and implementing lazy loading
class PerformanceService {
  static final PerformanceService _instance = PerformanceService._internal();
  factory PerformanceService() => _instance;
  PerformanceService._internal();

  // Performance monitoring
  final Map<String, DateTime> _operationStartTimes = {};
  final Map<String, Duration> _operationDurations = {};
  final List<PerformanceMetric> _metrics = [];

  // Memory management
  final Map<String, dynamic> _cache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  static const Duration _cacheExpiry = Duration(minutes: 30);
  static const int _maxCacheSize = 100;

  // Lazy loading
  final Map<String, bool> _loadingStates = {};
  final Map<String, Completer<dynamic>> _loadingCompleters = {};

  /// Initialize performance monitoring
  void initialize() {
    if (kDebugMode) {
      print('Performance service initialized');
      _startMemoryMonitoring();
    }
  }

  /// Start monitoring memory usage
  void _startMemoryMonitoring() {
    Timer.periodic(const Duration(minutes: 5), (timer) {
      _recordMemoryUsage();
      _cleanupCache();
    });
  }

  /// Record memory usage metrics
  void _recordMemoryUsage() {
    if (Platform.isAndroid || Platform.isIOS) {
      // In a real implementation, you would use platform channels
      // to get actual memory usage from native code
      _recordMetric('memory_usage', 0, {'timestamp': DateTime.now()});
    }
  }

  /// Start timing an operation
  void startOperation(String operationName) {
    _operationStartTimes[operationName] = DateTime.now();

    if (kDebugMode) {
      print('Started operation: $operationName');
    }
  }

  /// End timing an operation and record the duration
  Duration endOperation(String operationName) {
    final startTime = _operationStartTimes[operationName];
    if (startTime == null) {
      if (kDebugMode) {
        print('Warning: Operation $operationName was not started');
      }
      return Duration.zero;
    }

    final duration = DateTime.now().difference(startTime);
    _operationDurations[operationName] = duration;
    _operationStartTimes.remove(operationName);

    _recordMetric('operation_duration', duration.inMilliseconds, {
      'operation': operationName,
      'timestamp': DateTime.now(),
    });

    if (kDebugMode) {
      print(
        'Completed operation: $operationName in ${duration.inMilliseconds}ms',
      );
    }

    return duration;
  }

  /// Record a performance metric
  void _recordMetric(String name, num value, Map<String, dynamic> metadata) {
    final metric = PerformanceMetric(
      name: name,
      value: value,
      timestamp: DateTime.now(),
      metadata: metadata,
    );

    _metrics.add(metric);

    // Keep only the last 1000 metrics to prevent memory bloat
    if (_metrics.length > 1000) {
      _metrics.removeRange(0, _metrics.length - 1000);
    }
  }

  /// Cache data with automatic expiry
  void cacheData(String key, dynamic data) {
    // Remove oldest entries if cache is full
    if (_cache.length >= _maxCacheSize) {
      final oldestKey = _cacheTimestamps.entries
          .reduce((a, b) => a.value.isBefore(b.value) ? a : b)
          .key;
      _cache.remove(oldestKey);
      _cacheTimestamps.remove(oldestKey);
    }

    _cache[key] = data;
    _cacheTimestamps[key] = DateTime.now();

    if (kDebugMode) {
      print('Cached data for key: $key');
    }
  }

  /// Get cached data if not expired
  T? getCachedData<T>(String key) {
    final timestamp = _cacheTimestamps[key];
    if (timestamp == null) return null;

    // Check if cache has expired
    if (DateTime.now().difference(timestamp) > _cacheExpiry) {
      _cache.remove(key);
      _cacheTimestamps.remove(key);
      return null;
    }

    final data = _cache[key];
    if (data is T) {
      if (kDebugMode) {
        print('Cache hit for key: $key');
      }
      return data;
    }

    return null;
  }

  /// Clear expired cache entries
  void _cleanupCache() {
    final now = DateTime.now();
    final expiredKeys = <String>[];

    for (final entry in _cacheTimestamps.entries) {
      if (now.difference(entry.value) > _cacheExpiry) {
        expiredKeys.add(entry.key);
      }
    }

    for (final key in expiredKeys) {
      _cache.remove(key);
      _cacheTimestamps.remove(key);
    }

    if (kDebugMode && expiredKeys.isNotEmpty) {
      print('Cleaned up ${expiredKeys.length} expired cache entries');
    }
  }

  /// Clear all cached data
  void clearCache() {
    _cache.clear();
    _cacheTimestamps.clear();

    if (kDebugMode) {
      print('Cache cleared');
    }
  }

  /// Lazy load data with deduplication
  Future<T> lazyLoad<T>(
    String key,
    Future<T> Function() loader, {
    Duration? timeout,
  }) async {
    // Check if already loading
    if (_loadingStates[key] == true) {
      final completer = _loadingCompleters[key];
      if (completer != null) {
        return await completer.future as T;
      }
    }

    // Check cache first
    final cached = getCachedData<T>(key);
    if (cached != null) {
      return cached;
    }

    // Start loading
    _loadingStates[key] = true;
    final completer = Completer<T>();
    _loadingCompleters[key] = completer;

    try {
      startOperation('lazy_load_$key');

      final Future<T> loadingFuture = loader();
      final T result = timeout != null
          ? await loadingFuture.timeout(timeout)
          : await loadingFuture;

      endOperation('lazy_load_$key');

      // Cache the result
      cacheData(key, result);

      completer.complete(result);
      return result;
    } catch (error) {
      endOperation('lazy_load_$key');
      completer.completeError(error);
      rethrow;
    } finally {
      _loadingStates.remove(key);
      _loadingCompleters.remove(key);
    }
  }

  /// Check if data is currently being loaded
  bool isLoading(String key) {
    return _loadingStates[key] == true;
  }

  /// Preload data in the background
  void preloadData<T>(String key, Future<T> Function() loader) {
    // Don't preload if already cached or loading
    if (getCachedData<T>(key) != null || isLoading(key)) {
      return;
    }

    // Preload in background without blocking
    lazyLoad(key, loader).catchError((error) {
      if (kDebugMode) {
        print('Preload failed for $key: $error');
      }
      return loader(); // Return the result of calling loader again as fallback
    });
  }

  /// Optimize widget rebuilds by debouncing
  Timer? _debounceTimer;
  void debounce(
    VoidCallback callback, {
    Duration delay = const Duration(milliseconds: 300),
  }) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(delay, callback);
  }

  /// Batch multiple operations to reduce overhead
  Future<List<T>> batchOperations<T>(
    List<Future<T> Function()> operations,
  ) async {
    startOperation('batch_operations');

    try {
      final results = await Future.wait(
        operations.map((op) => op()),
        eagerError: false,
      );

      endOperation('batch_operations');
      return results;
    } catch (error) {
      endOperation('batch_operations');
      rethrow;
    }
  }

  /// Optimize image loading and caching
  void optimizeImageLoading() {
    // Set image cache size for better memory management
    PaintingBinding.instance.imageCache.maximumSize = 100;
    PaintingBinding.instance.imageCache.maximumSizeBytes =
        50 * 1024 * 1024; // 50MB
  }

  /// Reduce app startup time
  void optimizeStartup() {
    // Defer heavy operations until after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _performDeferredInitialization();
    });
  }

  /// Perform initialization that can be deferred
  void _performDeferredInitialization() {
    // Initialize non-critical services
    optimizeImageLoading();

    if (kDebugMode) {
      print('Deferred initialization completed');
    }
  }

  /// Get performance statistics
  PerformanceStats getPerformanceStats() {
    final now = DateTime.now();
    final recentMetrics = _metrics
        .where(
          (metric) =>
              now.difference(metric.timestamp) < const Duration(hours: 1),
        )
        .toList();

    final operationMetrics = recentMetrics
        .where((m) => m.name == 'operation_duration')
        .toList();

    double avgOperationTime = 0;
    if (operationMetrics.isNotEmpty) {
      avgOperationTime =
          operationMetrics.map((m) => m.value).reduce((a, b) => a + b) /
          operationMetrics.length;
    }

    return PerformanceStats(
      totalOperations: _operationDurations.length,
      averageOperationTime: avgOperationTime,
      cacheSize: _cache.length,
      cacheHitRate: _calculateCacheHitRate(),
      activeLoadingOperations: _loadingStates.length,
      totalMetrics: _metrics.length,
    );
  }

  /// Calculate cache hit rate
  double _calculateCacheHitRate() {
    final cacheMetrics = _metrics
        .where((m) => m.metadata['cache_hit'] != null)
        .toList();

    if (cacheMetrics.isEmpty) return 0.0;

    final hits = cacheMetrics
        .where((m) => m.metadata['cache_hit'] == true)
        .length;

    return hits / cacheMetrics.length;
  }

  /// Force garbage collection (use sparingly)
  void forceGarbageCollection() {
    if (kDebugMode) {
      print('Forcing garbage collection');
    }

    // Clear caches
    clearCache();

    // Clear image cache
    PaintingBinding.instance.imageCache.clear();

    // System GC hint
    SystemChannels.platform.invokeMethod('SystemNavigator.pop');
  }

  /// Get memory usage summary
  Map<String, dynamic> getMemoryUsage() {
    return {
      'cache_entries': _cache.length,
      'cache_size_estimate': _estimateCacheSize(),
      'loading_operations': _loadingStates.length,
      'metrics_count': _metrics.length,
      'operation_timers': _operationStartTimes.length,
    };
  }

  /// Estimate cache size in bytes (rough approximation)
  int _estimateCacheSize() {
    int size = 0;
    for (final value in _cache.values) {
      if (value is String) {
        size += value.length * 2; // UTF-16 encoding
      } else if (value is List) {
        size += value.length * 8; // Rough estimate
      } else {
        size += 64; // Default object overhead
      }
    }
    return size;
  }

  /// Dispose resources
  void dispose() {
    _debounceTimer?.cancel();
    clearCache();
    _metrics.clear();
    _operationStartTimes.clear();
    _operationDurations.clear();
    _loadingStates.clear();
    _loadingCompleters.clear();

    if (kDebugMode) {
      print('Performance service disposed');
    }
  }
}

/// Performance metric data class
class PerformanceMetric {
  final String name;
  final num value;
  final DateTime timestamp;
  final Map<String, dynamic> metadata;

  PerformanceMetric({
    required this.name,
    required this.value,
    required this.timestamp,
    required this.metadata,
  });

  @override
  String toString() {
    return 'PerformanceMetric(name: $name, value: $value, timestamp: $timestamp)';
  }
}

/// Performance statistics summary
class PerformanceStats {
  final int totalOperations;
  final double averageOperationTime;
  final int cacheSize;
  final double cacheHitRate;
  final int activeLoadingOperations;
  final int totalMetrics;

  PerformanceStats({
    required this.totalOperations,
    required this.averageOperationTime,
    required this.cacheSize,
    required this.cacheHitRate,
    required this.activeLoadingOperations,
    required this.totalMetrics,
  });

  @override
  String toString() {
    return 'PerformanceStats(operations: $totalOperations, avgTime: ${averageOperationTime.toStringAsFixed(2)}ms, cache: $cacheSize, hitRate: ${(cacheHitRate * 100).toStringAsFixed(1)}%)';
  }
}
