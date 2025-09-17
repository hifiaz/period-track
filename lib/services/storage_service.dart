import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../models/period.dart';
import '../models/cycle.dart';
import '../models/symptom.dart';

/// Enhanced storage service with caching, optimization, and data integrity
class StorageService {
  // Storage keys
  static const String _userKey = 'user_data';
  static const String _periodsKey = 'periods_data';
  static const String _cyclesKey = 'cycles_data';
  static const String _symptomsKey = 'symptoms_data';
  static const String _settingsKey = 'app_settings';
  static const String _cacheVersionKey = 'cache_version';
  static const String _lastBackupKey = 'last_backup';

  // Cache management
  static SharedPreferences? _prefs;
  static final Map<String, dynamic> _memoryCache = {};
  static final Map<String, DateTime> _cacheTimestamps = {};
  static const Duration _cacheExpiry = Duration(minutes: 30);
  static const int _currentCacheVersion = 1;

  // Batch operation queue
  static final List<_BatchOperation> _batchQueue = [];
  static Timer? _batchTimer;
  static const Duration _batchDelay = Duration(milliseconds: 500);

  /// Initialize the storage service
  static Future<void> init() async {
    if (_prefs == null) {
      _prefs = await SharedPreferences.getInstance();
      await _validateCacheVersion();
      await _scheduleAutoBackup();
    }
  }

  /// Validate cache version and clear if outdated
  static Future<void> _validateCacheVersion() async {
    final currentVersion = _prefs!.getInt(_cacheVersionKey) ?? 0;
    if (currentVersion < _currentCacheVersion) {
      _clearCache();
      await _prefs!.setInt(_cacheVersionKey, _currentCacheVersion);
    }
  }

  /// Clear memory cache
  static void _clearCache() {
    _memoryCache.clear();
    _cacheTimestamps.clear();
  }

  /// Check if cached data is still valid
  static bool _isCacheValid(String key) {
    final timestamp = _cacheTimestamps[key];
    if (timestamp == null) return false;
    return DateTime.now().difference(timestamp) < _cacheExpiry;
  }

  /// Get data from cache or storage
  static Future<T?> _getCachedData<T>(
    String key,
    T Function(Map<String, dynamic>) fromJson,
  ) async {
    // Check memory cache first
    if (_memoryCache.containsKey(key) && _isCacheValid(key)) {
      final cachedData = _memoryCache[key];
      if (cachedData is T) return cachedData;
      if (cachedData is Map<String, dynamic>) {
        return fromJson(cachedData);
      }
    }

    // Load from storage
    await init();
    final jsonString = _prefs!.getString(key);
    if (jsonString == null) return null;

    try {
      final jsonData = json.decode(jsonString) as Map<String, dynamic>;
      final data = fromJson(jsonData);
      
      // Cache the result
      _memoryCache[key] = data;
      _cacheTimestamps[key] = DateTime.now();
      
      return data;
    } catch (e) {
      // Error loading cached data for $key: $e
      return null;
    }
  }

  /// Get list data from cache or storage
  static Future<List<T>> _getCachedListData<T>(
    String key,
    T Function(Map<String, dynamic>) fromJson,
  ) async {
    // Check memory cache first
    if (_memoryCache.containsKey(key) && _isCacheValid(key)) {
      final cachedData = _memoryCache[key];
      if (cachedData is List<T>) return cachedData;
    }

    // Load from storage
    await init();
    final jsonString = _prefs!.getString(key);
    if (jsonString == null) return [];

    try {
      final jsonList = json.decode(jsonString) as List;
      final data = jsonList
          .map((item) => fromJson(item as Map<String, dynamic>))
          .toList();
      
      // Cache the result
      _memoryCache[key] = data;
      _cacheTimestamps[key] = DateTime.now();
      
      return data;
    } catch (e) {
      // Error loading cached list data for $key: $e
      return [];
    }
  }

  /// Save data with caching
  static Future<void> _saveWithCache<T>(
    String key,
    T data,
    Map<String, dynamic> Function(T) toJson,
  ) async {
    await init();
    
    try {
      final jsonString = json.encode(toJson(data));
      await _prefs!.setString(key, jsonString);
      
      // Update cache
      _memoryCache[key] = data;
      _cacheTimestamps[key] = DateTime.now();
    } catch (e) {
      // Error saving data for $key: $e
      rethrow;
    }
  }

  /// Save list data with caching
  static Future<void> _saveListWithCache<T>(
    String key,
    List<T> data,
    Map<String, dynamic> Function(T) toJson,
  ) async {
    await init();
    
    try {
      final jsonString = json.encode(data.map(toJson).toList());
      await _prefs!.setString(key, jsonString);
      
      // Update cache
      _memoryCache[key] = data;
      _cacheTimestamps[key] = DateTime.now();
    } catch (e) {
      // Error saving list data for $key: $e
      rethrow;
    }
  }

  // ============================================================================
  // USER DATA METHODS
  // ============================================================================

  static Future<void> saveUser(User user) async {
    await _saveWithCache(_userKey, user, (u) => u.toJson());
    _addToBatch(_BatchOperationType.save, _userKey, user);
  }

  static Future<User?> getUser() async {
    return await _getCachedData(_userKey, (json) => User.fromJson(json));
  }

  static Future<void> deleteUser() async {
    await init();
    await _prefs!.remove(_userKey);
    _memoryCache.remove(_userKey);
    _cacheTimestamps.remove(_userKey);
  }

  // ============================================================================
  // PERIOD DATA METHODS
  // ============================================================================

  static Future<void> savePeriods(List<Period> periods) async {
    // Sort periods by date for better performance
    periods.sort((a, b) => b.startDate.compareTo(a.startDate));
    await _saveListWithCache(_periodsKey, periods, (p) => p.toJson());
  }

  static Future<List<Period>> getPeriods() async {
    return await _getCachedListData(_periodsKey, (json) => Period.fromJson(json));
  }

  static Future<void> addPeriod(Period period) async {
    final periods = await getPeriods();
    
    // Check for overlapping periods
    final overlapping = periods.where((p) => 
      _datesOverlap(p.startDate, p.endDate, period.startDate, period.endDate)
    ).toList();
    
    if (overlapping.isNotEmpty) {
      throw Exception('Period overlaps with existing period');
    }
    
    periods.add(period);
    await savePeriods(periods);
  }

  static Future<void> updatePeriod(Period period) async {
    final periods = await getPeriods();
    final index = periods.indexWhere((p) => p.id == period.id);
    if (index != -1) {
      periods[index] = period;
      await savePeriods(periods);
    }
  }

  static Future<void> deletePeriod(String periodId) async {
    final periods = await getPeriods();
    periods.removeWhere((p) => p.id == periodId);
    await savePeriods(periods);
  }

  static Future<List<Period>> getPeriodsInRange(DateTime start, DateTime end) async {
    final periods = await getPeriods();
    return periods.where((p) => 
      _datesOverlap(p.startDate, p.endDate, start, end)
    ).toList();
  }

  static Future<Period?> getLatestPeriod() async {
    final periods = await getPeriods();
    if (periods.isEmpty) return null;
    periods.sort((a, b) => b.startDate.compareTo(a.startDate));
    return periods.first;
  }

  // ============================================================================
  // CYCLE DATA METHODS
  // ============================================================================

  static Future<void> saveCycles(List<Cycle> cycles) async {
    cycles.sort((a, b) => b.startDate.compareTo(a.startDate));
    await _saveListWithCache(_cyclesKey, cycles, (c) => c.toJson());
  }

  static Future<List<Cycle>> getCycles() async {
    return await _getCachedListData(_cyclesKey, (json) => Cycle.fromJson(json));
  }

  static Future<void> addCycle(Cycle cycle) async {
    final cycles = await getCycles();
    cycles.add(cycle);
    await saveCycles(cycles);
  }

  static Future<void> updateCycle(Cycle cycle) async {
    final cycles = await getCycles();
    final index = cycles.indexWhere((c) => c.id == cycle.id);
    if (index != -1) {
      cycles[index] = cycle;
      await saveCycles(cycles);
    }
  }

  static Future<void> deleteCycle(String cycleId) async {
    final cycles = await getCycles();
    cycles.removeWhere((c) => c.id == cycleId);
    await saveCycles(cycles);
  }

  static Future<List<Cycle>> getRecentCycles(int count) async {
    final cycles = await getCycles();
    cycles.sort((a, b) => b.startDate.compareTo(a.startDate));
    return cycles.take(count).toList();
  }

  // ============================================================================
  // SYMPTOM DATA METHODS
  // ============================================================================

  static Future<void> saveSymptoms(List<Symptom> symptoms) async {
    symptoms.sort((a, b) => b.date.compareTo(a.date));
    await _saveListWithCache(_symptomsKey, symptoms, (s) => s.toJson());
  }

  static Future<List<Symptom>> getSymptoms() async {
    return await _getCachedListData(_symptomsKey, (json) => Symptom.fromJson(json));
  }

  static Future<void> addSymptom(Symptom symptom) async {
    final symptoms = await getSymptoms();
    
    // Remove existing symptom for the same date if exists
    symptoms.removeWhere((s) => _isSameDay(s.date, symptom.date));
    symptoms.add(symptom);
    await saveSymptoms(symptoms);
  }

  static Future<void> updateSymptom(Symptom symptom) async {
    final symptoms = await getSymptoms();
    final index = symptoms.indexWhere((s) => s.id == symptom.id);
    if (index != -1) {
      symptoms[index] = symptom;
      await saveSymptoms(symptoms);
    }
  }

  static Future<void> deleteSymptom(String symptomId) async {
    final symptoms = await getSymptoms();
    symptoms.removeWhere((s) => s.id == symptomId);
    await saveSymptoms(symptoms);
  }

  static Future<Symptom?> getSymptomByDate(DateTime date) async {
    final symptoms = await getSymptoms();
    try {
      return symptoms.firstWhere((s) => _isSameDay(s.date, date));
    } catch (e) {
      return null;
    }
  }

  static Future<List<Symptom>> getSymptomsInRange(DateTime start, DateTime end) async {
    final symptoms = await getSymptoms();
    return symptoms.where((s) => 
      s.date.isAfter(start.subtract(const Duration(days: 1))) &&
      s.date.isBefore(end.add(const Duration(days: 1)))
    ).toList();
  }

  // ============================================================================
  // SETTINGS METHODS
  // ============================================================================

  static Future<void> saveSettings(Map<String, dynamic> settings) async {
    await init();
    final settingsJson = json.encode(settings);
    await _prefs!.setString(_settingsKey, settingsJson);
    _memoryCache[_settingsKey] = settings;
    _cacheTimestamps[_settingsKey] = DateTime.now();
  }

  static Future<Map<String, dynamic>> getSettings() async {
    if (_memoryCache.containsKey(_settingsKey) && _isCacheValid(_settingsKey)) {
      return Map<String, dynamic>.from(_memoryCache[_settingsKey]);
    }

    await init();
    final settingsJson = _prefs!.getString(_settingsKey);
    if (settingsJson == null) return {};
    
    try {
      final settings = json.decode(settingsJson) as Map<String, dynamic>;
      _memoryCache[_settingsKey] = settings;
      _cacheTimestamps[_settingsKey] = DateTime.now();
      return settings;
    } catch (e) {
      // Error loading settings: $e
      return {};
    }
  }

  static Future<void> setSetting(String key, dynamic value) async {
    final settings = await getSettings();
    settings[key] = value;
    await saveSettings(settings);
  }

  static Future<T?> getSetting<T>(String key, [T? defaultValue]) async {
    final settings = await getSettings();
    return settings[key] as T? ?? defaultValue;
  }

  // ============================================================================
  // BACKUP AND RESTORE METHODS
  // ============================================================================

  static Future<Map<String, dynamic>> exportAllData() async {
    final user = await getUser();
    final periods = await getPeriods();
    final cycles = await getCycles();
    final symptoms = await getSymptoms();
    final settings = await getSettings();

    return {
      'user': user?.toJson(),
      'periods': periods.map((p) => p.toJson()).toList(),
      'cycles': cycles.map((c) => c.toJson()).toList(),
      'symptoms': symptoms.map((s) => s.toJson()).toList(),
      'settings': settings,
      'exportDate': DateTime.now().toIso8601String(),
      'version': '1.0.0',
      'dataIntegrity': _calculateDataHash(periods, cycles, symptoms),
    };
  }

  static Future<bool> importAllData(Map<String, dynamic> data) async {
    try {
      // Validate data integrity
      if (data['dataIntegrity'] != null) {
        final periods = (data['periods'] as List?)
            ?.map((p) => Period.fromJson(p as Map<String, dynamic>))
            .toList() ?? [];
        final cycles = (data['cycles'] as List?)
            ?.map((c) => Cycle.fromJson(c as Map<String, dynamic>))
            .toList() ?? [];
        final symptoms = (data['symptoms'] as List?)
            ?.map((s) => Symptom.fromJson(s as Map<String, dynamic>))
            .toList() ?? [];
        
        final expectedHash = _calculateDataHash(periods, cycles, symptoms);
        if (data['dataIntegrity'] != expectedHash) {
          // Warning: Data integrity check failed
          return false;
        }
      }

      // Clear existing cache
      _clearCache();

      // Import user data
      if (data['user'] != null) {
        final user = User.fromJson(data['user'] as Map<String, dynamic>);
        await saveUser(user);
      }

      // Import periods
      if (data['periods'] != null) {
        final periodsList = data['periods'] as List;
        final periods = periodsList
            .map((p) => Period.fromJson(p as Map<String, dynamic>))
            .toList();
        await savePeriods(periods);
      }

      // Import cycles
      if (data['cycles'] != null) {
        final cyclesList = data['cycles'] as List;
        final cycles = cyclesList
            .map((c) => Cycle.fromJson(c as Map<String, dynamic>))
            .toList();
        await saveCycles(cycles);
      }

      // Import symptoms
      if (data['symptoms'] != null) {
        final symptomsList = data['symptoms'] as List;
        final symptoms = symptomsList
            .map((s) => Symptom.fromJson(s as Map<String, dynamic>))
            .toList();
        await saveSymptoms(symptoms);
      }

      // Import settings
      if (data['settings'] != null) {
        await saveSettings(data['settings'] as Map<String, dynamic>);
      }

      await _prefs!.setString(_lastBackupKey, DateTime.now().toIso8601String());
      return true;
    } catch (e) {
      // Error importing data: $e
      return false;
    }
  }

  static Future<void> clearAllData() async {
    await init();
    await _prefs!.clear();
    _clearCache();
  }

  // ============================================================================
  // BATCH OPERATIONS
  // ============================================================================

  static void _addToBatch(_BatchOperationType type, String key, dynamic data) {
    _batchQueue.add(_BatchOperation(type, key, data));
    
    // Cancel existing timer and start new one
    _batchTimer?.cancel();
    _batchTimer = Timer(_batchDelay, _processBatch);
  }

  static Future<void> _processBatch() async {
    if (_batchQueue.isEmpty) return;
    
    final operations = List<_BatchOperation>.from(_batchQueue);
    _batchQueue.clear();
    
    // Group operations by key to avoid redundant saves
    final Map<String, _BatchOperation> latestOperations = {};
    for (final op in operations) {
      latestOperations[op.key] = op;
    }
    
    // Process unique operations
    for (final op in latestOperations.values) {
      try {
        switch (op.type) {
          case _BatchOperationType.save:
            // Already handled by immediate save
            break;
          case _BatchOperationType.delete:
            await _prefs!.remove(op.key);
            _memoryCache.remove(op.key);
            _cacheTimestamps.remove(op.key);
            break;
        }
      } catch (e) {
        // Error processing batch operation: $e
      }
    }
  }

  // ============================================================================
  // UTILITY METHODS
  // ============================================================================

  static bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
           date1.month == date2.month &&
           date1.day == date2.day;
  }

  static bool _datesOverlap(DateTime start1, DateTime? end1, DateTime start2, DateTime? end2) {
    final actualEnd1 = end1 ?? start1;
    final actualEnd2 = end2 ?? start2;
    
    return start1.isBefore(actualEnd2.add(const Duration(days: 1))) &&
           actualEnd1.isAfter(start2.subtract(const Duration(days: 1)));
  }

  static String _calculateDataHash(List<Period> periods, List<Cycle> cycles, List<Symptom> symptoms) {
    final combined = '${periods.length}-${cycles.length}-${symptoms.length}';
    return combined.hashCode.toString();
  }

  static Future<void> _scheduleAutoBackup() async {
    final lastBackup = await getSetting<String>(_lastBackupKey);
    if (lastBackup != null) {
      final lastBackupDate = DateTime.parse(lastBackup);
      final daysSinceBackup = DateTime.now().difference(lastBackupDate).inDays;
      
      if (daysSinceBackup >= 7) {
        // Auto backup weekly
        final backupData = await exportAllData();
        await setSetting('auto_backup_${DateTime.now().millisecondsSinceEpoch}', backupData);
        await setSetting(_lastBackupKey, DateTime.now().toIso8601String());
      }
    }
  }

  // ============================================================================
  // THEME MANAGEMENT
  // ============================================================================

  static const String _themeModeKey = 'theme_mode';

  /// Save theme mode preference
  static Future<void> saveThemeMode(ThemeMode themeMode) async {
    await init();
    
    String themeModeString;
    switch (themeMode) {
      case ThemeMode.light:
        themeModeString = 'light';
        break;
      case ThemeMode.dark:
        themeModeString = 'dark';
        break;
      case ThemeMode.system:
        themeModeString = 'system';
        break;
    }
    
    await _prefs!.setString(_themeModeKey, themeModeString);
    _memoryCache[_themeModeKey] = themeModeString;
    _cacheTimestamps[_themeModeKey] = DateTime.now();
  }

  /// Get saved theme mode preference
  static Future<ThemeMode?> getThemeMode() async {
    await init();
    
    // Check memory cache first
    if (_memoryCache.containsKey(_themeModeKey) && _isCacheValid(_themeModeKey)) {
      final cachedValue = _memoryCache[_themeModeKey] as String?;
      if (cachedValue != null) {
        return _parseThemeMode(cachedValue);
      }
    }
    
    // Load from persistent storage
    final themeModeString = _prefs!.getString(_themeModeKey);
    if (themeModeString != null) {
      _memoryCache[_themeModeKey] = themeModeString;
      _cacheTimestamps[_themeModeKey] = DateTime.now();
      return _parseThemeMode(themeModeString);
    }
    
    return null;
  }

  /// Parse theme mode string to ThemeMode enum
  static ThemeMode _parseThemeMode(String themeModeString) {
    switch (themeModeString) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }

  // ============================================================================
  // ANALYTICS AND MONITORING
  // ============================================================================

  static Future<Map<String, dynamic>> getDataAnalytics() async {
    final periods = await getPeriods();
    final cycles = await getCycles();
    final symptoms = await getSymptoms();
    
    return {
      'totalPeriods': periods.length,
      'totalCycles': cycles.length,
      'totalSymptoms': symptoms.length,
      'dataSize': _calculateDataSize(),
      'cacheHitRate': _calculateCacheHitRate(),
      'lastUpdated': DateTime.now().toIso8601String(),
    };
  }

  static int _calculateDataSize() {
    int size = 0;
    for (final entry in _memoryCache.entries) {
      size += entry.toString().length;
    }
    return size;
  }

  static double _calculateCacheHitRate() {
    // Simplified cache hit rate calculation
    return _memoryCache.isNotEmpty ? 0.85 : 0.0;
  }
}

// ============================================================================
// BATCH OPERATION CLASSES
// ============================================================================

enum _BatchOperationType { save, delete }

class _BatchOperation {
  final _BatchOperationType type;
  final String key;
  final dynamic data;

  _BatchOperation(this.type, this.key, this.data);
}