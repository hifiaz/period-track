import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/notification_settings.dart';
import '../providers/app_provider.dart';
import '../services/notification_service.dart';
import '../services/storage_service.dart';
import '../services/performance_service.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  NotificationSettings _settings = NotificationSettings();
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadSettings();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _animationController.forward();
  }

  Future<void> _loadSettings() async {
    PerformanceService().startOperation('load_notification_settings');
    
    try {
      final settings = await StorageService.getSettings();
      if (settings.containsKey('notifications')) {
        setState(() {
          _settings = NotificationSettings.fromMap(
            Map<String, dynamic>.from(settings['notifications']),
          );
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    } finally {
      PerformanceService().endOperation('load_notification_settings');
    }
  }

  Future<void> _saveSettings() async {
    if (_isSaving) return;
    
    setState(() {
      _isSaving = true;
    });

    PerformanceService().startOperation('save_notification_settings');

    try {
      // Save to storage
      await StorageService.setSetting('notifications', _settings.toMap());
      
      // Update notification service
      final notificationService = NotificationService();
      
      // Reschedule notifications with new settings
      final appProvider = Provider.of<AppProvider>(context, listen: false);
      if (appProvider.user != null) {
        await notificationService.schedulePeriodReminders(
          appProvider.user!,
          appProvider.periods,
        );
        await notificationService.scheduleOvulationReminders(
          appProvider.user!,
          appProvider.periods,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Notification settings saved'),
            backgroundColor: Theme.of(context).colorScheme.primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving settings: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } finally {
      PerformanceService().endOperation('save_notification_settings');
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Settings'),
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            TextButton(
              onPressed: _saveSettings,
              child: const Text('Save'),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _buildSectionHeader('Period Reminders'),
                    _buildNotificationCard(
                      title: 'Period Reminders',
                      subtitle: 'Get notified before your period starts',
                      value: _settings.periodReminder,
                      onChanged: (value) {
                        setState(() {
                          _settings = _settings.copyWith(periodReminder: value);
                        });
                      },
                      children: _settings.periodReminder
                          ? [
                              _buildSlider(
                                'Days before period',
                                _settings.periodReminderDays.toDouble(),
                                1,
                                7,
                                (value) {
                                  setState(() {
                                    _settings = _settings.copyWith(
                                      periodReminderDays: value.round(),
                                    );
                                  });
                                },
                              ),
                            ]
                          : null,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    _buildNotificationCard(
                      title: 'Ovulation Reminders',
                      subtitle: 'Get notified about your fertile window',
                      value: _settings.ovulationReminder,
                      onChanged: (value) {
                        setState(() {
                          _settings = _settings.copyWith(ovulationReminder: value);
                        });
                      },
                      children: _settings.ovulationReminder
                          ? [
                              _buildSlider(
                                'Days before ovulation',
                                _settings.ovulationReminderDays.toDouble(),
                                1,
                                5,
                                (value) {
                                  setState(() {
                                    _settings = _settings.copyWith(
                                      ovulationReminderDays: value.round(),
                                    );
                                  });
                                },
                              ),
                            ]
                          : null,
                    ),

                    const SizedBox(height: 24),
                    _buildSectionHeader('Other Reminders'),
                    
                    _buildSimpleToggle(
                      'Medication Reminders',
                      'Daily medication and supplement reminders',
                      _settings.medicationReminder,
                      (value) {
                        setState(() {
                          _settings = _settings.copyWith(medicationReminder: value);
                        });
                      },
                    ),
                    
                    _buildSimpleToggle(
                      'Symptom Tracking',
                      'Daily reminders to log symptoms',
                      _settings.symptomReminder,
                      (value) {
                        setState(() {
                          _settings = _settings.copyWith(symptomReminder: value);
                        });
                      },
                    ),

                    const SizedBox(height: 24),
                    _buildSectionHeader('Notification Preferences'),
                    
                    _buildSimpleToggle(
                      'Sound',
                      'Play notification sound',
                      _settings.soundEnabled,
                      (value) {
                        setState(() {
                          _settings = _settings.copyWith(soundEnabled: value);
                        });
                      },
                    ),
                    
                    _buildSimpleToggle(
                      'Vibration',
                      'Vibrate on notifications',
                      _settings.vibrationEnabled,
                      (value) {
                        setState(() {
                          _settings = _settings.copyWith(vibrationEnabled: value);
                        });
                      },
                    ),

                    const SizedBox(height: 32),
                    _buildSummaryCard(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildNotificationCard({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    List<Widget>? children,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SwitchListTile(
              title: Text(title),
              subtitle: Text(subtitle),
              value: value,
              onChanged: onChanged,
              contentPadding: EdgeInsets.zero,
            ),
            if (children != null && value) ...[
              const Divider(),
              ...children,
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSimpleToggle(
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Card(
      child: SwitchListTile(
        title: Text(title),
        subtitle: Text(subtitle),
        value: value,
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildSlider(
    String label,
    double value,
    double min,
    double max,
    ValueChanged<double> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ${value.round()} day${value.round() == 1 ? '' : 's'}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          Slider(
            value: value,
            min: min,
            max: max,
            divisions: (max - min).round(),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildTimeSelector(
    String label,
    TimeOfDay time,
    ValueChanged<TimeOfDay> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          TextButton(
            onPressed: () async {
              final selectedTime = await showTimePicker(
                context: context,
                initialTime: time,
              );
              if (selectedTime != null) {
                onChanged(selectedTime);
              }
            },
            child: Text(time.format(context)),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    final enabledCount = _settings.enabledTypes.length;
    final summary = _settings.summary;
    
    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.notifications_active,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Notification Summary',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '$enabledCount notification type${enabledCount == 1 ? '' : 's'} enabled',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            if (summary.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                summary,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onPrimaryContainer.withOpacity(0.8),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}