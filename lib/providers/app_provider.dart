import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/user.dart';
import '../models/period.dart';
import '../models/cycle.dart';
import '../models/symptom.dart';
import '../services/storage_service.dart';
import '../services/prediction_service.dart';
import '../services/notification_service.dart';
import '../services/performance_service.dart';

class AppProvider with ChangeNotifier {
  User? _user;
  List<Period> _periods = [];
  List<Cycle> _cycles = [];
  List<Symptom> _symptoms = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  User? get user => _user;
  List<Period> get periods => _periods;
  List<Cycle> get cycles => _cycles;
  List<Symptom> get symptoms => _symptoms;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isFirstTime => _user?.isFirstTime ?? true;

  // Initialize app data
  Future<void> initialize() async {
    _setLoading(true);
    PerformanceService().startOperation('app_data_loading');
    
    try {
      // Load data with performance monitoring
      await _loadUserData();
      await _loadPeriodsData();
      await _loadCyclesData();
      await _loadSymptomsData();
      
      // Schedule notifications if user exists
      if (_user != null && !_user!.isFirstTime) {
        await _scheduleNotifications();
      }
      
      _error = null;
      PerformanceService().endOperation('app_data_loading');
    } catch (e) {
      _error = 'Failed to load app data: $e';
      PerformanceService().endOperation('app_data_loading');
    } finally {
      _setLoading(false);
    }
  }

  // User management
  Future<void> createUser({
    required String name,
    DateTime? birthDate,
    int averageCycleLength = 28,
    int averagePeriodLength = 5,
    DateTime? lastPeriodDate,
  }) async {
    final user = User(
      id: const Uuid().v4(),
      name: name,
      birthDate: birthDate,
      averageCycleLength: averageCycleLength,
      averagePeriodLength: averagePeriodLength,
      lastPeriodDate: lastPeriodDate,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await StorageService.saveUser(user);
    _user = user;
    notifyListeners();
  }

  Future<void> updateUser(User updatedUser) async {
    await StorageService.saveUser(updatedUser);
    _user = updatedUser;
    notifyListeners();
  }

  Future<void> completeOnboarding() async {
    if (_user != null) {
      final updatedUser = _user!.copyWith(
        isFirstTime: false,
        updatedAt: DateTime.now(),
      );
      await updateUser(updatedUser);
    }
  }

  // Period management
  Future<void> addPeriod({
    required DateTime startDate,
    DateTime? endDate,
    int flow = 3,
    List<String> symptoms = const [],
    String? notes,
  }) async {
    final period = Period(
      id: const Uuid().v4(),
      startDate: startDate,
      endDate: endDate,
      flow: flow,
      symptoms: symptoms,
      notes: notes,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await StorageService.addPeriod(period);
    _periods.add(period);
    _periods.sort((a, b) => b.startDate.compareTo(a.startDate));
    
    // Update user's last period date
    if (_user != null) {
      final updatedUser = _user!.copyWith(
        lastPeriodDate: startDate,
        updatedAt: DateTime.now(),
      );
      await updateUser(updatedUser);
    }
    
    notifyListeners();
  }

  Future<void> updatePeriod(Period updatedPeriod) async {
    await StorageService.updatePeriod(updatedPeriod);
    final index = _periods.indexWhere((p) => p.id == updatedPeriod.id);
    if (index != -1) {
      _periods[index] = updatedPeriod;
      notifyListeners();
    }
  }

  Future<void> deletePeriod(String periodId) async {
    await StorageService.deletePeriod(periodId);
    _periods.removeWhere((p) => p.id == periodId);
    notifyListeners();
  }

  // Symptom management
  Future<void> addOrUpdateSymptom({
    required DateTime date,
    List<String> physicalSymptoms = const [],
    List<String> emotionalSymptoms = const [],
    int? painLevel,
    String? painLocation,
    double? basalTemperature,
    String? cervicalMucus,
    String? mood,
    int? energyLevel,
    int? sleepQuality,
    int? stressLevel,
    bool? sexualActivity,
    String? notes,
  }) async {
    // Check if symptom already exists for this date
    final existingSymptom = await StorageService.getSymptomByDate(date);
    
    if (existingSymptom != null) {
      // Update existing symptom
      final updatedSymptom = existingSymptom.copyWith(
        physicalSymptoms: physicalSymptoms,
        emotionalSymptoms: emotionalSymptoms,
        painLevel: painLevel,
        painLocation: painLocation,
        basalTemperature: basalTemperature,
        cervicalMucus: cervicalMucus,
        mood: mood,
        energyLevel: energyLevel,
        sleepQuality: sleepQuality,
        stressLevel: stressLevel,
        sexualActivity: sexualActivity,
        notes: notes,
        updatedAt: DateTime.now(),
      );
      
      await StorageService.updateSymptom(updatedSymptom);
      final index = _symptoms.indexWhere((s) => s.id == updatedSymptom.id);
      if (index != -1) {
        _symptoms[index] = updatedSymptom;
      }
    } else {
      // Create new symptom
      final symptom = Symptom(
        id: const Uuid().v4(),
        date: date,
        physicalSymptoms: physicalSymptoms,
        emotionalSymptoms: emotionalSymptoms,
        painLevel: painLevel,
        painLocation: painLocation,
        basalTemperature: basalTemperature,
        cervicalMucus: cervicalMucus,
        mood: mood,
        energyLevel: energyLevel,
        sleepQuality: sleepQuality,
        stressLevel: stressLevel,
        sexualActivity: sexualActivity,
        notes: notes,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      await StorageService.addSymptom(symptom);
      _symptoms.add(symptom);
    }
    
    _symptoms.sort((a, b) => b.date.compareTo(a.date));
    notifyListeners();
  }

  Future<void> deleteSymptom(String symptomId) async {
    await StorageService.deleteSymptom(symptomId);
    _symptoms.removeWhere((s) => s.id == symptomId);
    notifyListeners();
  }

  // Prediction methods
  DateTime? get nextPeriodPrediction {
    return PredictionService.predictNextPeriod(_periods, _user!);
  }

  DateTime? get nextOvulationPrediction {
    return PredictionService.predictOvulation(_periods, _user!);
  }

  Map<String, DateTime?> get fertilityWindow {
    return PredictionService.calculateFertilityWindow(_periods, _user!);
  }

  String getCyclePhase(DateTime date) {
    return PredictionService.getCyclePhase(date, _periods, _user!);
  }

  Map<String, dynamic> get cycleRegularity {
    return PredictionService.calculateCycleRegularity(_periods);
  }

  List<String> get insights {
    if (_user == null) return [];
    return PredictionService.generateInsights(_periods, _user!);
  }

  double getPregnancyProbability(DateTime date) {
    if (_user == null) return 0.0;
    return PredictionService.calculatePregnancyProbability(date, _periods, _user!);
  }

  // Get symptom for specific date
  Symptom? getSymptomForDate(DateTime date) {
    try {
      return _symptoms.firstWhere((s) => 
        s.date.year == date.year &&
        s.date.month == date.month &&
        s.date.day == date.day
      );
    } catch (e) {
      return null;
    }
  }

  // Private methods with performance monitoring
  Future<void> _loadUserData() async {
    PerformanceService().startOperation('load_user_data');
    _user = await StorageService.getUser();
    PerformanceService().endOperation('load_user_data');
  }

  Future<void> _loadPeriodsData() async {
    PerformanceService().startOperation('load_periods_data');
    _periods = await StorageService.getPeriods();
    _periods.sort((a, b) => b.startDate.compareTo(a.startDate));
    PerformanceService().endOperation('load_periods_data');
  }

  Future<void> _loadCyclesData() async {
    PerformanceService().startOperation('load_cycles_data');
    _cycles = await StorageService.getCycles();
    _cycles.sort((a, b) => b.startDate.compareTo(a.startDate));
    PerformanceService().endOperation('load_cycles_data');
  }

  Future<void> _loadSymptomsData() async {
    PerformanceService().startOperation('load_symptoms_data');
    _symptoms = await StorageService.getSymptoms();
    _symptoms.sort((a, b) => b.date.compareTo(a.date));
    PerformanceService().endOperation('load_symptoms_data');
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Clear all data
  Future<void> clearAllData() async {
    await StorageService.clearAllData();
    _user = null;
    _periods.clear();
    _cycles.clear();
    _symptoms.clear();
    notifyListeners();
  }

  // Get insights
  List<String> getInsights() {
    if (_user == null) return [];
    return PredictionService.generateInsights(_periods, _user!);
  }

  // Schedule notifications for period and ovulation reminders
  Future<void> _scheduleNotifications() async {
    try {
      if (_user == null) return;
      
      final notificationService = NotificationService();
      
      // Schedule period and ovulation reminders
      await notificationService.schedulePeriodReminders(_user!, _periods);
      await notificationService.scheduleOvulationReminders(_user!, _periods);
    } catch (e) {
      // Silently handle notification errors to not disrupt app flow
      debugPrint('Error scheduling notifications: $e');
    }
  }

  // Batch operations for better performance
  Future<void> batchUpdateData({
    List<Period>? periods,
    List<Symptom>? symptoms,
    User? user,
  }) async {
    PerformanceService().startOperation('batch_update');
    
    try {
      final operations = <Future>[];
      
      if (periods != null) {
        for (final period in periods) {
          operations.add(StorageService.updatePeriod(period));
        }
        _periods = periods;
      }
      
      if (symptoms != null) {
        for (final symptom in symptoms) {
          operations.add(StorageService.updateSymptom(symptom));
        }
        _symptoms = symptoms;
      }
      
      if (user != null) {
        operations.add(StorageService.saveUser(user));
        _user = user;
      }
      
      await Future.wait(operations);
      
      // Reschedule notifications after data updates
      if (_user != null && !_user!.isFirstTime) {
        await _scheduleNotifications();
      }
      
      notifyListeners();
    } finally {
      PerformanceService().endOperation('batch_update');
    }
  }

  // Memory optimization - clear old data
  void optimizeMemory() {
    PerformanceService().clearCache();
    
    // Keep only recent periods (last 2 years)
    final cutoffDate = DateTime.now().subtract(const Duration(days: 730));
    _periods.removeWhere((period) => period.startDate.isBefore(cutoffDate));
    
    // Keep only recent symptoms (last 1 year)
    final symptomCutoffDate = DateTime.now().subtract(const Duration(days: 365));
    _symptoms.removeWhere((symptom) => symptom.date.isBefore(symptomCutoffDate));
    
    notifyListeners();
  }
}