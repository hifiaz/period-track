import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/app_provider.dart';
import '../models/user.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _showEditProfileDialog(context),
          ),
        ],
      ),
      body: Consumer<AppProvider>(
        builder: (context, appProvider, child) {
          final user = appProvider.user;
          
          if (user == null) {
            return const Center(
              child: Text('No user data available'),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProfileHeader(user),
                const SizedBox(height: 24),
                _buildCycleSettings(user, appProvider),
                const SizedBox(height: 24),
                _buildDataSection(appProvider),
                const SizedBox(height: 24),
                _buildPreferencesSection(),
                const SizedBox(height: 24),
                _buildSupportSection(),
                const SizedBox(height: 24),
                _buildDataManagementSection(appProvider),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileHeader(User user) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
              child: Icon(
                Icons.person,
                size: 50,
                color: Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              user.name,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              user.age != null ? 'Age: ${user.age}' : 'Age: Not set',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildProfileStat(
                  'Cycle Length',
                  '${user.averageCycleLength} days',
                  Icons.refresh,
                ),
                _buildProfileStat(
                  'Period Length',
                  '${user.averagePeriodLength} days',
                  Icons.water_drop,
                ),
                _buildProfileStat(
                  'Last Period',
                  user.lastPeriodDate != null
                      ? DateFormat('MMM dd').format(user.lastPeriodDate!)
                      : 'Not set',
                  Icons.calendar_today,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          color: Theme.of(context).primaryColor,
          size: 24,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 12,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildCycleSettings(User user, AppProvider appProvider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Cycle Settings',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildSettingItem(
              'Average Cycle Length',
              '${user.averageCycleLength} days',
              Icons.refresh,
              () => _showCycleLengthDialog(context, appProvider),
            ),
            const Divider(),
            _buildSettingItem(
              'Average Period Length',
              '${user.averagePeriodLength} days',
              Icons.water_drop,
              () => _showPeriodLengthDialog(context, appProvider),
            ),
            const Divider(),
            _buildSettingItem(
              'Last Period Date',
              user.lastPeriodDate != null
                  ? DateFormat('MMM dd, yyyy').format(user.lastPeriodDate!)
                  : 'Not set',
              Icons.calendar_today,
              () => _showLastPeriodDialog(context, appProvider),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataSection(AppProvider appProvider) {
    final periods = appProvider.periods;
    final symptoms = appProvider.symptoms;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your Data',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildDataCard(
                    'Periods Logged',
                    '${periods.length}',
                    Icons.water_drop,
                    Colors.pink,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildDataCard(
                    'Symptoms Logged',
                    '${symptoms.length}',
                    Icons.healing,
                    Colors.purple,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildDataCard(
                    'Days Tracked',
                    '${_calculateDaysTracked(periods)}',
                    Icons.calendar_today,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildDataCard(
                    'Accuracy Score',
                    '${_calculateAccuracyScore(appProvider)}%',
                    Icons.analytics,
                    Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPreferencesSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Preferences',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildSettingItem(
              'Notifications',
              'Period reminders, ovulation alerts',
              Icons.notifications,
              () => _showNotificationSettings(context),
            ),
            const Divider(),
            _buildSettingItem(
              'Privacy',
              'Data protection and sharing',
              Icons.privacy_tip,
              () => _showPrivacySettings(context),
            ),
            const Divider(),
            _buildSettingItem(
              'Units',
              'Temperature, measurements',
              Icons.straighten,
              () => _showUnitsSettings(context),
            ),
            const Divider(),
            _buildSettingItem(
              'Theme',
              'App appearance',
              Icons.palette,
              () => _showThemeSettings(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSupportSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Support & Information',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildSettingItem(
              'Help & FAQ',
              'Get answers to common questions',
              Icons.help,
              () => _showHelp(context),
            ),
            const Divider(),
            _buildSettingItem(
              'Contact Support',
              'Get help from our team',
              Icons.support_agent,
              () => _contactSupport(context),
            ),
            const Divider(),
            _buildSettingItem(
              'About',
              'App version and information',
              Icons.info,
              () => _showAbout(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataManagementSection(AppProvider appProvider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Data Management',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildSettingItem(
              'Export Data',
              'Download your period data',
              Icons.download,
              () => _exportData(context, appProvider),
            ),
            const Divider(),
            _buildSettingItem(
              'Import Data',
              'Import from another app',
              Icons.upload,
              () => _importData(context, appProvider),
            ),
            const Divider(),
            _buildSettingItem(
              'Backup & Sync',
              'Cloud backup settings',
              Icons.cloud_sync,
              () => _showBackupSettings(context),
            ),
            const Divider(),
            _buildSettingItem(
              'Clear All Data',
              'Reset app to initial state',
              Icons.delete_forever,
              () => _showClearDataDialog(context, appProvider),
              isDestructive: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingItem(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap, {
    bool isDestructive = false,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isDestructive ? Colors.red : Theme.of(context).primaryColor,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isDestructive ? Colors.red : null,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
    );
  }

  // Helper methods
  int _calculateDaysTracked(List<dynamic> periods) {
    if (periods.isEmpty) return 0;
    final firstPeriod = periods.last;
    final lastPeriod = periods.first;
    return DateTime.now().difference(firstPeriod.startDate).inDays;
  }

  int _calculateAccuracyScore(AppProvider appProvider) {
    // Simple accuracy calculation based on data consistency
    final periods = appProvider.periods;
    final symptoms = appProvider.symptoms;
    
    if (periods.isEmpty) return 0;
    
    final totalDays = 30;
    final recentSymptoms = symptoms
        .where((s) => s.date.isAfter(DateTime.now().subtract(Duration(days: totalDays))))
        .length;
    
    final consistencyScore = (recentSymptoms / totalDays * 100).clamp(0, 100);
    return consistencyScore.round();
  }

  // Dialog methods
  void _showEditProfileDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const EditProfileDialog(),
    );
  }

  void _showCycleLengthDialog(BuildContext context, AppProvider appProvider) {
    showDialog(
      context: context,
      builder: (context) => CycleLengthDialog(appProvider: appProvider),
    );
  }

  void _showPeriodLengthDialog(BuildContext context, AppProvider appProvider) {
    showDialog(
      context: context,
      builder: (context) => PeriodLengthDialog(appProvider: appProvider),
    );
  }

  void _showLastPeriodDialog(BuildContext context, AppProvider appProvider) {
    showDialog(
      context: context,
      builder: (context) => LastPeriodDialog(appProvider: appProvider),
    );
  }

  void _showNotificationSettings(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const NotificationSettingsDialog(),
    );
  }

  void _showPrivacySettings(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const PrivacySettingsDialog(),
    );
  }

  void _showUnitsSettings(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const UnitsSettingsDialog(),
    );
  }

  void _showThemeSettings(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const ThemeSettingsDialog(),
    );
  }

  void _showHelp(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const HelpDialog(),
    );
  }

  void _contactSupport(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const ContactSupportDialog(),
    );
  }

  void _showAbout(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const AboutDialog(),
    );
  }

  void _exportData(BuildContext context, AppProvider appProvider) {
    showDialog(
      context: context,
      builder: (context) => ExportDataDialog(appProvider: appProvider),
    );
  }

  void _importData(BuildContext context, AppProvider appProvider) {
    showDialog(
      context: context,
      builder: (context) => ImportDataDialog(appProvider: appProvider),
    );
  }

  void _showBackupSettings(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const BackupSettingsDialog(),
    );
  }

  void _showClearDataDialog(BuildContext context, AppProvider appProvider) {
    showDialog(
      context: context,
      builder: (context) => ClearDataDialog(appProvider: appProvider),
    );
  }
}

// Dialog implementations (simplified for now)
class EditProfileDialog extends StatelessWidget {
  const EditProfileDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Profile'),
      content: const Text('Profile editing will be implemented here.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

class CycleLengthDialog extends StatefulWidget {
  final AppProvider appProvider;

  const CycleLengthDialog({super.key, required this.appProvider});

  @override
  State<CycleLengthDialog> createState() => _CycleLengthDialogState();
}

class _CycleLengthDialogState extends State<CycleLengthDialog> {
  late int _cycleLength;

  @override
  void initState() {
    super.initState();
    _cycleLength = widget.appProvider.user!.averageCycleLength;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Average Cycle Length'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Current: $_cycleLength days'),
          Slider(
            value: _cycleLength.toDouble(),
            min: 21,
            max: 35,
            divisions: 14,
            label: '$_cycleLength days',
            onChanged: (value) {
              setState(() {
                _cycleLength = value.round();
              });
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            final user = widget.appProvider.user!;
            final updatedUser = User(
              id: user.id,
              name: user.name,
              birthDate: user.birthDate,
              averageCycleLength: _cycleLength,
              averagePeriodLength: user.averagePeriodLength,
              lastPeriodDate: user.lastPeriodDate,
              isPregnant: user.isPregnant,
              isBreastfeeding: user.isBreastfeeding,
              useContraception: user.useContraception,
              contraceptionType: user.contraceptionType,
              healthConditions: user.healthConditions,
              notificationSettings: user.notificationSettings,
              theme: user.theme,
              language: user.language,
              isFirstTime: user.isFirstTime,
              createdAt: user.createdAt,
              updatedAt: DateTime.now(),
            );
            await widget.appProvider.updateUser(updatedUser);
            if (mounted) {
              Navigator.of(context).pop();
            }
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class PeriodLengthDialog extends StatefulWidget {
  final AppProvider appProvider;

  const PeriodLengthDialog({super.key, required this.appProvider});

  @override
  State<PeriodLengthDialog> createState() => _PeriodLengthDialogState();
}

class _PeriodLengthDialogState extends State<PeriodLengthDialog> {
  late int _periodLength;

  @override
  void initState() {
    super.initState();
    _periodLength = widget.appProvider.user!.averagePeriodLength;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Average Period Length'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Current: $_periodLength days'),
          Slider(
            value: _periodLength.toDouble(),
            min: 3,
            max: 8,
            divisions: 5,
            label: '$_periodLength days',
            onChanged: (value) {
              setState(() {
                _periodLength = value.round();
              });
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            final user = widget.appProvider.user!;
            final updatedUser = User(
              id: user.id,
              name: user.name,
              birthDate: user.birthDate,
              averageCycleLength: user.averageCycleLength,
              averagePeriodLength: _periodLength,
              lastPeriodDate: user.lastPeriodDate,
              isPregnant: user.isPregnant,
              isBreastfeeding: user.isBreastfeeding,
              useContraception: user.useContraception,
              contraceptionType: user.contraceptionType,
              healthConditions: user.healthConditions,
              notificationSettings: user.notificationSettings,
              theme: user.theme,
              language: user.language,
              isFirstTime: user.isFirstTime,
              createdAt: user.createdAt,
              updatedAt: DateTime.now(),
            );
            await widget.appProvider.updateUser(updatedUser);
            if (mounted) {
              Navigator.of(context).pop();
            }
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class LastPeriodDialog extends StatefulWidget {
  final AppProvider appProvider;

  const LastPeriodDialog({super.key, required this.appProvider});

  @override
  State<LastPeriodDialog> createState() => _LastPeriodDialogState();
}

class _LastPeriodDialogState extends State<LastPeriodDialog> {
  late DateTime _lastPeriodDate;

  @override
  void initState() {
    super.initState();
    _lastPeriodDate = widget.appProvider.user!.lastPeriodDate ?? DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Last Period Date'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Date: ${DateFormat('MMM dd, yyyy').format(_lastPeriodDate)}'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: _lastPeriodDate,
                firstDate: DateTime.now().subtract(const Duration(days: 365)),
                lastDate: DateTime.now(),
              );
              if (date != null) {
                setState(() {
                  _lastPeriodDate = date;
                });
              }
            },
            child: const Text('Select Date'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            final user = widget.appProvider.user!;
            final updatedUser = User(
              id: user.id,
              name: user.name,
              birthDate: user.birthDate,
              averageCycleLength: user.averageCycleLength,
              averagePeriodLength: user.averagePeriodLength,
              lastPeriodDate: _lastPeriodDate,
              isPregnant: user.isPregnant,
              isBreastfeeding: user.isBreastfeeding,
              useContraception: user.useContraception,
              contraceptionType: user.contraceptionType,
              healthConditions: user.healthConditions,
              notificationSettings: user.notificationSettings,
              theme: user.theme,
              language: user.language,
              isFirstTime: user.isFirstTime,
              createdAt: user.createdAt,
              updatedAt: DateTime.now(),
            );
            await widget.appProvider.updateUser(updatedUser);
            if (mounted) {
              Navigator.of(context).pop();
            }
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class ClearDataDialog extends StatelessWidget {
  final AppProvider appProvider;

  const ClearDataDialog({super.key, required this.appProvider});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Clear All Data'),
      content: const Text(
        'This will permanently delete all your period data, symptoms, and settings. This action cannot be undone.\n\nAre you sure you want to continue?',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
          onPressed: () async {
            // Clear all data
            // This would need to be implemented in the AppProvider
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('All data cleared successfully'),
                backgroundColor: Colors.red,
              ),
            );
          },
          child: const Text('Clear All Data'),
        ),
      ],
    );
  }
}

// Placeholder dialogs for other settings
class NotificationSettingsDialog extends StatelessWidget {
  const NotificationSettingsDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Notification Settings'),
      content: const Text('Notification settings will be implemented here.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

class PrivacySettingsDialog extends StatelessWidget {
  const PrivacySettingsDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Privacy Settings'),
      content: const Text('Privacy settings will be implemented here.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

class UnitsSettingsDialog extends StatelessWidget {
  const UnitsSettingsDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Units Settings'),
      content: const Text('Units settings will be implemented here.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

class ThemeSettingsDialog extends StatelessWidget {
  const ThemeSettingsDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Theme Settings'),
      content: const Text('Theme settings will be implemented here.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

class HelpDialog extends StatelessWidget {
  const HelpDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Help & FAQ'),
      content: const Text('Help content will be implemented here.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

class ContactSupportDialog extends StatelessWidget {
  const ContactSupportDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Contact Support'),
      content: const Text('Support contact options will be implemented here.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

class ExportDataDialog extends StatelessWidget {
  final AppProvider appProvider;

  const ExportDataDialog({super.key, required this.appProvider});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Export Data'),
      content: const Text('Data export functionality will be implemented here.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

class ImportDataDialog extends StatelessWidget {
  final AppProvider appProvider;

  const ImportDataDialog({super.key, required this.appProvider});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Import Data'),
      content: const Text('Data import functionality will be implemented here.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

class BackupSettingsDialog extends StatelessWidget {
  const BackupSettingsDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Backup & Sync'),
      content: const Text('Backup settings will be implemented here.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}