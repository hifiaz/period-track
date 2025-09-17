/// Enhanced model for managing notification settings and preferences
class NotificationSettings {
  final bool periodReminder;
  final bool ovulationReminder;
  final bool fertilityWindow;
  final bool symptoms;
  final bool insights;
  final bool medicationReminder;
  final bool symptomReminder;
  final int periodReminderDays; // Days before period to remind
  final int ovulationReminderDays; // Days before ovulation to remind
  final String medicationReminderTime; // Time for medication reminder (HH:mm)
  final String symptomReminderTime; // Time for symptom reminder (HH:mm)
  final bool soundEnabled;
  final bool vibrationEnabled;
  final String notificationTone;

  const NotificationSettings({
    this.periodReminder = true,
    this.ovulationReminder = true,
    this.fertilityWindow = true,
    this.symptoms = false,
    this.insights = true,
    this.medicationReminder = false,
    this.symptomReminder = false,
    this.periodReminderDays = 2,
    this.ovulationReminderDays = 1,
    this.medicationReminderTime = '09:00',
    this.symptomReminderTime = '20:00',
    this.soundEnabled = true,
    this.vibrationEnabled = true,
    this.notificationTone = 'default',
  });

  /// Create from Map (for storage) - supports both old and new format
  factory NotificationSettings.fromMap(Map<String, dynamic> map) {
    return NotificationSettings(
      periodReminder: map['periodReminder'] ?? true,
      ovulationReminder: map['ovulationReminder'] ?? true,
      fertilityWindow: map['fertilityWindow'] ?? true,
      symptoms: map['symptoms'] ?? false,
      insights: map['insights'] ?? true,
      medicationReminder: map['medicationReminder'] ?? false,
      symptomReminder: map['symptomReminder'] ?? false,
      periodReminderDays: map['periodReminderDays'] ?? 2,
      ovulationReminderDays: map['ovulationReminderDays'] ?? 1,
      medicationReminderTime: map['medicationReminderTime'] ?? '09:00',
      symptomReminderTime: map['symptomReminderTime'] ?? '20:00',
      soundEnabled: map['soundEnabled'] ?? true,
      vibrationEnabled: map['vibrationEnabled'] ?? true,
      notificationTone: map['notificationTone'] ?? 'default',
    );
  }

  /// Convert to Map (for storage)
  Map<String, dynamic> toMap() {
    return {
      'periodReminder': periodReminder,
      'ovulationReminder': ovulationReminder,
      'fertilityWindow': fertilityWindow,
      'symptoms': symptoms,
      'insights': insights,
      'medicationReminder': medicationReminder,
      'symptomReminder': symptomReminder,
      'periodReminderDays': periodReminderDays,
      'ovulationReminderDays': ovulationReminderDays,
      'medicationReminderTime': medicationReminderTime,
      'symptomReminderTime': symptomReminderTime,
      'soundEnabled': soundEnabled,
      'vibrationEnabled': vibrationEnabled,
      'notificationTone': notificationTone,
    };
  }

  /// Create a copy with updated values
  NotificationSettings copyWith({
    bool? periodReminder,
    bool? ovulationReminder,
    bool? fertilityWindow,
    bool? symptoms,
    bool? insights,
    bool? medicationReminder,
    bool? symptomReminder,
    int? periodReminderDays,
    int? ovulationReminderDays,
    String? medicationReminderTime,
    String? symptomReminderTime,
    bool? soundEnabled,
    bool? vibrationEnabled,
    String? notificationTone,
  }) {
    return NotificationSettings(
      periodReminder: periodReminder ?? this.periodReminder,
      ovulationReminder: ovulationReminder ?? this.ovulationReminder,
      fertilityWindow: fertilityWindow ?? this.fertilityWindow,
      symptoms: symptoms ?? this.symptoms,
      insights: insights ?? this.insights,
      medicationReminder: medicationReminder ?? this.medicationReminder,
      symptomReminder: symptomReminder ?? this.symptomReminder,
      periodReminderDays: periodReminderDays ?? this.periodReminderDays,
      ovulationReminderDays: ovulationReminderDays ?? this.ovulationReminderDays,
      medicationReminderTime: medicationReminderTime ?? this.medicationReminderTime,
      symptomReminderTime: symptomReminderTime ?? this.symptomReminderTime,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      notificationTone: notificationTone ?? this.notificationTone,
    );
  }

  /// Check if any notifications are enabled
  bool get hasAnyEnabled {
    return periodReminder || 
           ovulationReminder || 
           fertilityWindow ||
           symptoms ||
           insights ||
           medicationReminder || 
           symptomReminder;
  }

  /// Get enabled notification types
  List<String> get enabledTypes {
    final types = <String>[];
    if (periodReminder) types.add('Period');
    if (ovulationReminder) types.add('Ovulation');
    if (fertilityWindow) types.add('Fertility Window');
    if (symptoms) types.add('Symptoms');
    if (insights) types.add('Insights');
    if (medicationReminder) types.add('Medication');
    if (symptomReminder) types.add('Symptom Tracking');
    return types;
  }

  /// Get medication reminder time as DateTime (today)
  DateTime get medicationReminderDateTime {
    final parts = medicationReminderTime.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, hour, minute);
  }

  /// Get symptom reminder time as DateTime (today)
  DateTime get symptomReminderDateTime {
    final parts = symptomReminderTime.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, hour, minute);
  }

  /// Get notification summary for display
  String get summary {
    if (!hasAnyEnabled) return 'All notifications disabled';
    
    final enabled = enabledTypes;
    if (enabled.length == 1) return '${enabled.first} notifications enabled';
    if (enabled.length == 2) return '${enabled.join(' and ')} notifications enabled';
    
    return '${enabled.length} notification types enabled';
  }

  @override
  String toString() {
    return 'NotificationSettings(periodReminder: $periodReminder, ovulationReminder: $ovulationReminder, medicationReminder: $medicationReminder, symptomReminder: $symptomReminder)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is NotificationSettings &&
      other.periodReminder == periodReminder &&
      other.ovulationReminder == ovulationReminder &&
      other.fertilityWindow == fertilityWindow &&
      other.symptoms == symptoms &&
      other.insights == insights &&
      other.medicationReminder == medicationReminder &&
      other.symptomReminder == symptomReminder &&
      other.periodReminderDays == periodReminderDays &&
      other.ovulationReminderDays == ovulationReminderDays &&
      other.medicationReminderTime == medicationReminderTime &&
      other.symptomReminderTime == symptomReminderTime &&
      other.soundEnabled == soundEnabled &&
      other.vibrationEnabled == vibrationEnabled &&
      other.notificationTone == notificationTone;
  }

  @override
  int get hashCode {
    return Object.hash(
      periodReminder,
      ovulationReminder,
      fertilityWindow,
      symptoms,
      insights,
      medicationReminder,
      symptomReminder,
      periodReminderDays,
      ovulationReminderDays,
      medicationReminderTime,
      symptomReminderTime,
      soundEnabled,
      vibrationEnabled,
      notificationTone,
    );
  }
}