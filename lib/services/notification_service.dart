import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import '../models/user.dart';
import '../models/period.dart';
import '../models/notification_settings.dart';
import '../services/prediction_service.dart';
import 'storage_service.dart';

/// Enhanced notification service with real local notifications
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  static final FlutterLocalNotificationsPlugin _notifications = 
      FlutterLocalNotificationsPlugin();
  
  bool _isInitialized = false;
  final List<ScheduledNotification> _scheduledNotifications = [];
  
  // Notification IDs
  static const int _periodReminderBaseId = 1000;
  static const int _ovulationReminderBaseId = 2000;
  static const int _medicationReminderBaseId = 3000;
  static const int _symptomReminderBaseId = 4000;

  /// Initialize the notification service
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      // Initialize timezone data
      tz.initializeTimeZones();
      
      // Android initialization settings
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      
      // iOS initialization settings
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
        onDidReceiveLocalNotification: _onDidReceiveLocalNotification,
      );
      
      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      final result = await _notifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationResponse,
      );

      if (result == true) {
        _isInitialized = true;
        await _setupNotificationChannels();
        
        if (kDebugMode) {
          print('Notification service initialized successfully');
        }
        return true;
      }
      
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing notifications: $e');
      }
      return false;
    }
  }

  /// Setup notification channels for Android
  Future<void> _setupNotificationChannels() async {
    if (!Platform.isAndroid) return;

    const channels = [
      AndroidNotificationChannel(
        'period_reminders',
        'Period Reminders',
        description: 'Notifications for period tracking and reminders',
        importance: Importance.high,
        playSound: true,
      ),
      AndroidNotificationChannel(
        'ovulation_reminders',
        'Ovulation Reminders',
        description: 'Notifications for ovulation tracking',
        importance: Importance.high,
        playSound: true,
      ),
      AndroidNotificationChannel(
        'medication_reminders',
        'Medication Reminders',
        description: 'Daily medication reminder notifications',
        importance: Importance.max,
        playSound: true,
      ),
      AndroidNotificationChannel(
        'symptom_reminders',
        'Symptom Reminders',
        description: 'Daily symptom tracking reminders',
        importance: Importance.defaultImportance,
        playSound: true,
      ),
    ];

    for (final channel in channels) {
      await _notifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    }
  }

  /// Request notification permissions
  Future<bool> requestPermissions() async {
    if (!_isInitialized) await initialize();
    
    if (Platform.isIOS) {
      final result = await _notifications
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
      
      if (kDebugMode) {
        print('iOS notification permissions: ${result ?? false}');
      }
      return result ?? false;
    } else if (Platform.isAndroid) {
      final result = await _notifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
      
      if (kDebugMode) {
        print('Android notification permissions: ${result ?? false}');
      }
      return result ?? false;
    }
    
    return true;
  }

  /// Schedule period reminder notifications
  Future<void> schedulePeriodReminders(User user, List<Period> periods) async {
    if (!_isInitialized) await initialize();

    // Cancel existing period reminders
    await cancelNotificationsByType('period');

    final notificationSettings = NotificationSettings.fromMap(user.notificationSettings);
    if (!notificationSettings.periodReminder) return;

    final nextPeriod = PredictionService.predictNextPeriod(periods, user);

    if (nextPeriod != null) {
      // Schedule notification 2 days before predicted period
      final reminderDate2 = nextPeriod.subtract(const Duration(days: 2));
      await _scheduleRealNotification(
        id: _periodReminderBaseId + 1,
        title: '🩸 Period Reminder',
        body: 'Your period is expected in 2 days. Time to prepare!',
        scheduledDate: reminderDate2,
        channelId: 'period_reminders',
        payload: 'period_reminder_2',
      );

      // Schedule notification 1 day before predicted period
      final reminderDate1 = nextPeriod.subtract(const Duration(days: 1));
      await _scheduleRealNotification(
        id: _periodReminderBaseId + 2,
        title: '🩸 Period Reminder',
        body: 'Your period is expected tomorrow. Be prepared!',
        scheduledDate: reminderDate1,
        channelId: 'period_reminders',
        payload: 'period_reminder_1',
      );

      // Schedule notification on the predicted period day
      await _scheduleRealNotification(
        id: _periodReminderBaseId + 3,
        title: '🩸 Period Day',
        body: 'Your period is expected to start today. Don\'t forget to log it!',
        scheduledDate: nextPeriod,
        channelId: 'period_reminders',
        payload: 'period_day',
      );

      // Add to internal tracking
      _scheduledNotifications.addAll([
        ScheduledNotification(
          id: _periodReminderBaseId + 1,
          title: 'Period Reminder (2 days)',
          body: 'Your period is expected in 2 days',
          scheduledDate: reminderDate2,
          type: 'period_reminder',
          isRepeating: false,
        ),
        ScheduledNotification(
          id: _periodReminderBaseId + 2,
          title: 'Period Reminder (1 day)',
          body: 'Your period is expected tomorrow',
          scheduledDate: reminderDate1,
          type: 'period_reminder',
          isRepeating: false,
        ),
        ScheduledNotification(
          id: _periodReminderBaseId + 3,
          title: 'Period Day',
          body: 'Your period is expected today',
          scheduledDate: nextPeriod,
          type: 'period_day',
          isRepeating: false,
        ),
      ]);
    }
  }

  /// Schedule ovulation reminder notifications
  Future<void> scheduleOvulationReminders(User user, List<Period> periods) async {
    if (!_isInitialized) await initialize();

    // Cancel existing ovulation reminders
    await cancelNotificationsByType('ovulation');

    final notificationSettings = NotificationSettings.fromMap(user.notificationSettings);
    if (!notificationSettings.ovulationReminder) return;

    final nextOvulation = PredictionService.predictOvulation(periods, user);

    if (nextOvulation != null) {
      // Schedule notification 3 days before ovulation (fertile window start)
      final fertileStart = nextOvulation.subtract(const Duration(days: 3));
      await _scheduleRealNotification(
        id: _ovulationReminderBaseId + 1,
        title: '🌸 Fertile Window Starting',
        body: 'Your fertile window is starting soon!',
        scheduledDate: fertileStart,
        channelId: 'ovulation_reminders',
        payload: 'fertility_start',
      );

      // Schedule notification 1 day before ovulation
      final reminderDate = nextOvulation.subtract(const Duration(days: 1));
      await _scheduleRealNotification(
        id: _ovulationReminderBaseId + 2,
        title: '🥚 Ovulation Tomorrow',
        body: 'Ovulation is expected tomorrow!',
        scheduledDate: reminderDate,
        channelId: 'ovulation_reminders',
        payload: 'ovulation_tomorrow',
      );

      // Schedule notification on ovulation day
      await _scheduleRealNotification(
        id: _ovulationReminderBaseId + 3,
        title: '🥚 Ovulation Day',
        body: 'Today is your predicted ovulation day!',
        scheduledDate: nextOvulation,
        channelId: 'ovulation_reminders',
        payload: 'ovulation_day',
      );

      // Add to internal tracking
      _scheduledNotifications.addAll([
        ScheduledNotification(
          id: _ovulationReminderBaseId + 1,
          title: 'Fertile Window Starting',
          body: 'Your fertile window is starting',
          scheduledDate: fertileStart,
          type: 'fertility_reminder',
          isRepeating: false,
        ),
        ScheduledNotification(
          id: _ovulationReminderBaseId + 2,
          title: 'Ovulation Tomorrow',
          body: 'Ovulation expected tomorrow',
          scheduledDate: reminderDate,
          type: 'ovulation_reminder',
          isRepeating: false,
        ),
        ScheduledNotification(
          id: _ovulationReminderBaseId + 3,
          title: 'Ovulation Day',
          body: 'Today is ovulation day',
          scheduledDate: nextOvulation,
          type: 'ovulation_day',
          isRepeating: false,
        ),
      ]);
    }
  }

  /// Schedule medication reminders
  Future<void> scheduleMedicationReminders(User user) async {
    if (!_isInitialized) await initialize();

    // Cancel existing medication reminders
    await cancelNotificationsByType('medication');

    final notificationSettings = NotificationSettings.fromMap(user.notificationSettings);
    if (!notificationSettings.medicationReminder) return;

    // Schedule daily medication reminder at 9 AM for the next 30 days
    for (int day = 0; day < 30; day++) {
      final scheduledDate = DateTime.now().add(Duration(days: day));
      final reminderTime = DateTime(
        scheduledDate.year,
        scheduledDate.month,
        scheduledDate.day,
        9, // 9 AM
        0,
      );

      if (reminderTime.isAfter(DateTime.now())) {
        await _scheduleRealNotification(
          id: _medicationReminderBaseId + day,
          title: '💊 Medication Reminder',
          body: 'Time to take your medication!',
          scheduledDate: reminderTime,
          channelId: 'medication_reminders',
          payload: 'medication_reminder_$day',
        );

        _scheduledNotifications.add(ScheduledNotification(
          id: _medicationReminderBaseId + day,
          title: 'Medication Reminder',
          body: 'Time to take your medication',
          scheduledDate: reminderTime,
          type: 'medication_reminder',
          isRepeating: true,
        ));
      }
    }
  }

  /// Schedule symptom tracking reminders
  Future<void> scheduleSymptomReminders(User user) async {
    if (!_isInitialized) await initialize();

    // Cancel existing symptom reminders
    await cancelNotificationsByType('symptom');

    final notificationSettings = NotificationSettings.fromMap(user.notificationSettings);
    if (!notificationSettings.symptomReminder) return;

    // Schedule daily symptom reminder at 8 PM for the next 7 days
    for (int day = 0; day < 7; day++) {
      final scheduledDate = DateTime.now().add(Duration(days: day));
      final reminderTime = DateTime(
        scheduledDate.year,
        scheduledDate.month,
        scheduledDate.day,
        20, // 8 PM
        0,
      );

      if (reminderTime.isAfter(DateTime.now())) {
        await _scheduleRealNotification(
          id: _symptomReminderBaseId + day,
          title: '📝 Daily Check-in',
          body: 'How are you feeling today? Log your symptoms!',
          scheduledDate: reminderTime,
          channelId: 'symptom_reminders',
          payload: 'symptom_reminder_$day',
        );

        _scheduledNotifications.add(ScheduledNotification(
          id: _symptomReminderBaseId + day,
          title: 'Symptom Tracking',
          body: 'Log your daily symptoms',
          scheduledDate: reminderTime,
          type: 'symptom_reminder',
          isRepeating: true,
        ));
      }
    }
  }

  /// Schedule a real notification using flutter_local_notifications
  Future<void> _scheduleRealNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    required String channelId,
    String? payload,
  }) async {
    if (scheduledDate.isBefore(DateTime.now())) return;

    try {
      final androidDetails = AndroidNotificationDetails(
        channelId,
        channelId.replaceAll('_', ' ').toUpperCase(),
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        styleInformation: const BigTextStyleInformation(''),
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      final notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notifications.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.from(scheduledDate, tz.local),
        notificationDetails,
        payload: payload,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );

      if (kDebugMode) {
        print('Scheduled real notification: $title for ${scheduledDate.toString()}');
      }

    } catch (e) {
      if (kDebugMode) {
        print('Error scheduling real notification $id: $e');
      }
    }
  }

  /// Show immediate notification
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? type,
    String? payload,
  }) async {
    if (!_isInitialized) await initialize();

    try {
      const androidDetails = AndroidNotificationDetails(
        'period_reminders',
        'Period Reminders',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notifications.show(
        id,
        title,
        body,
        notificationDetails,
        payload: payload,
      );

      if (kDebugMode) {
        print('Showing immediate notification: $title - $body');
      }

    } catch (e) {
      if (kDebugMode) {
        print('Error showing notification: $e');
      }
    }
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
    _scheduledNotifications.clear();
    
    if (kDebugMode) {
      print('All notifications cancelled');
    }
  }

  /// Cancel notifications by type
  Future<void> cancelNotificationsByType(String type) async {
    // Cancel from system
    final toCancel = _scheduledNotifications
        .where((notification) => notification.type.contains(type))
        .toList();
    
    for (final notification in toCancel) {
      await _notifications.cancel(notification.id);
    }
    
    // Remove from internal tracking
    _scheduledNotifications.removeWhere((notification) => 
        notification.type.contains(type));
    
    if (kDebugMode) {
      print('Cancelled notifications of type: $type');
    }
  }

  /// Cancel specific notification
  Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
    _scheduledNotifications.removeWhere((notification) => 
        notification.id == id);
    
    if (kDebugMode) {
      print('Cancelled notification with id: $id');
    }
  }

  /// Get pending notifications
  Future<List<ScheduledNotification>> getPendingNotifications() async {
    final now = DateTime.now();
    return _scheduledNotifications.where((notification) => 
        notification.scheduledDate.isAfter(now)).toList();
  }

  /// Get system pending notifications
  Future<List<PendingNotificationRequest>> getSystemPendingNotifications() async {
    return await _notifications.pendingNotificationRequests();
  }

  /// Update all notifications based on user settings
  Future<void> updateNotifications(User user, List<Period> periods) async {
    // Cancel all existing notifications
    await cancelAllNotifications();

    // Schedule new notifications based on user preferences
    await schedulePeriodReminders(user, periods);
    await scheduleOvulationReminders(user, periods);
    await scheduleMedicationReminders(user);
    await scheduleSymptomReminders(user);
  }

  /// Check if notifications are enabled
  Future<bool> areNotificationsEnabled() async {
    if (!_isInitialized) await initialize();
    
    if (Platform.isAndroid) {
      final result = await _notifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.areNotificationsEnabled();
      return result ?? false;
    }
    
    return true; // iOS handles this at the system level
  }

  /// Get notification statistics
  Map<String, int> getNotificationStats() {
    final stats = <String, int>{};
    
    for (final notification in _scheduledNotifications) {
      final type = notification.type.split('_').first;
      stats[type] = (stats[type] ?? 0) + 1;
    }
    
    return stats;
  }

  /// Handle notification response
  static void _onNotificationResponse(NotificationResponse response) {
    final payload = response.payload;
    if (payload != null) {
      _handleNotificationPayload(payload);
    }
  }

  /// Handle iOS foreground notifications
  static void _onDidReceiveLocalNotification(
    int id,
    String? title,
    String? body,
    String? payload,
  ) {
    if (payload != null) {
      _handleNotificationPayload(payload);
    }
  }

  /// Handle notification payload
  static void _handleNotificationPayload(String payload) {
    if (kDebugMode) {
      print('Notification payload received: $payload');
    }
    
    // Handle different notification types
    if (payload.startsWith('period_reminder') || payload == 'period_day') {
      // Navigate to period logging screen
      // This would typically use a navigation service or callback
    } else if (payload.startsWith('ovulation') || payload.startsWith('fertility')) {
      // Navigate to fertility tracking screen
    } else if (payload.startsWith('medication_reminder')) {
      // Show medication taken confirmation
    } else if (payload.startsWith('symptom_reminder')) {
      // Navigate to symptom logging screen
    }
  }

  /// Test notification (for debugging)
  Future<void> testNotification() async {
    await showNotification(
      id: 9999,
      title: '🧪 Test Notification',
      body: 'This is a test notification from Period Tracker!',
      type: 'test',
      payload: 'test_notification',
    );
  }
}

/// Model for scheduled notifications
class ScheduledNotification {
  final int id;
  final String title;
  final String body;
  final DateTime scheduledDate;
  final String type;
  final bool isRepeating;

  ScheduledNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.scheduledDate,
    required this.type,
    required this.isRepeating,
  });

  @override
  String toString() {
    return 'ScheduledNotification(id: $id, title: $title, scheduledDate: $scheduledDate, type: $type)';
  }
}