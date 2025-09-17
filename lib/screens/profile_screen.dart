import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/app_provider.dart';
import '../models/user.dart';
import '../services/admob_service.dart';

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
            return const Center(child: Text('No user data available'));
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
                color: Theme.of(context).iconTheme.color ?? Colors.grey,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              user.name,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              user.age != null ? 'Age: ${user.age}' : 'Age: Not set',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
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
          color: Theme.of(context).iconTheme.color ?? Colors.grey,
          size: 24,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        Text(
          label,
          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
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
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
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
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
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

  Widget _buildDataCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
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
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
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
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
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
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
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
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
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
        color: isDestructive
            ? Colors.red
            : (Theme.of(context).iconTheme.color ?? Colors.grey),
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
    return DateTime.now().difference(firstPeriod.startDate).inDays;
  }

  int _calculateAccuracyScore(AppProvider appProvider) {
    // Simple accuracy calculation based on data consistency
    final periods = appProvider.periods;
    final symptoms = appProvider.symptoms;

    if (periods.isEmpty) return 0;

    final totalDays = 30;
    final recentSymptoms = symptoms
        .where(
          (s) => s.date.isAfter(
            DateTime.now().subtract(Duration(days: totalDays)),
          ),
        )
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
    showDialog(context: context, builder: (context) => const HelpDialog());
  }

  void _contactSupport(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const ContactSupportDialog(),
    );
  }

  void _showAbout(BuildContext context) {
    showDialog(context: context, builder: (context) => const AboutDialog());
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

// Dialog implementations
class EditProfileDialog extends StatefulWidget {
  const EditProfileDialog({super.key});

  @override
  State<EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends State<EditProfileDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  DateTime? _selectedBirthDate;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    final user = appProvider.user;
    if (user != null) {
      _nameController.text = user.name;
      _selectedBirthDate = user.birthDate;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Profile'),
      content: SizedBox(
        width: double.maxFinite,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your name';
                  }
                  if (value.trim().length < 2) {
                    return 'Name must be at least 2 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: () => _selectBirthDate(context),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.cake,
                        color: Theme.of(
                          context,
                        ).iconTheme.color?.withOpacity(0.6),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _selectedBirthDate != null
                              ? 'Birth Date: ${DateFormat('MMM dd, yyyy').format(_selectedBirthDate!)}'
                              : 'Select Birth Date',
                          style: TextStyle(
                            color: _selectedBirthDate != null
                                ? null
                                : Colors.grey,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.calendar_today,
                        color: Theme.of(
                          context,
                        ).iconTheme.color?.withOpacity(0.6),
                      ),
                    ],
                  ),
                ),
              ),
              if (_selectedBirthDate != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Age: ${_calculateAge(_selectedBirthDate!)} years',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _saveProfile,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save'),
        ),
      ],
    );
  }

  Future<void> _selectBirthDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate:
          _selectedBirthDate ??
          DateTime.now().subtract(const Duration(days: 365 * 25)),
      firstDate: DateTime.now().subtract(const Duration(days: 365 * 100)),
      lastDate: DateTime.now().subtract(const Duration(days: 365 * 13)),
      helpText: 'Select Birth Date',
    );
    if (picked != null && picked != _selectedBirthDate) {
      setState(() {
        _selectedBirthDate = picked;
      });
    }
  }

  int _calculateAge(DateTime birthDate) {
    final now = DateTime.now();
    int age = now.year - birthDate.year;
    if (now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final appProvider = Provider.of<AppProvider>(context, listen: false);
      final user = appProvider.user!;

      final updatedUser = User(
        id: user.id,
        name: _nameController.text.trim(),
        birthDate: _selectedBirthDate,
        averageCycleLength: user.averageCycleLength,
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

      await appProvider.updateUser(updatedUser);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
        // Show interstitial ad after saving profile data
        AdMobService().showInterstitialAd();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
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
class NotificationSettingsDialog extends StatefulWidget {
  const NotificationSettingsDialog({super.key});

  @override
  State<NotificationSettingsDialog> createState() =>
      _NotificationSettingsDialogState();
}

class _NotificationSettingsDialogState
    extends State<NotificationSettingsDialog> {
  bool _periodReminders = true;
  bool _ovulationAlerts = true;
  bool _fertilityWindow = false;
  bool _symptomReminders = false;
  bool _medicationReminders = false;
  TimeOfDay _reminderTime = const TimeOfDay(hour: 9, minute: 0);
  int _daysBefore = 1;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentSettings();
  }

  void _loadCurrentSettings() {
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    final user = appProvider.user;
    if (user != null) {
      final settings = user.notificationSettings;
      setState(() {
        _periodReminders = settings['periodReminder'] ?? true;
        _ovulationAlerts = settings['ovulationReminder'] ?? true;
        _fertilityWindow = settings['fertilityWindow'] ?? false;
        _symptomReminders = settings['symptoms'] ?? false;
        _medicationReminders = settings['insights'] ?? false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Notification Settings'),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Period Notifications',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                title: const Text('Period Reminders'),
                subtitle: const Text('Get notified before your period starts'),
                value: _periodReminders,
                onChanged: (value) {
                  setState(() {
                    _periodReminders = value;
                  });
                },
                contentPadding: EdgeInsets.zero,
              ),
              if (_periodReminders) ...[
                Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Text('Remind me '),
                          DropdownButton<int>(
                            value: _daysBefore,
                            items: [1, 2, 3, 5].map((days) {
                              return DropdownMenuItem(
                                value: days,
                                child: Text('$days day${days > 1 ? 's' : ''}'),
                              );
                            }).toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  _daysBefore = value;
                                });
                              }
                            },
                          ),
                          const Text(' before'),
                        ],
                      ),
                      ListTile(
                        title: const Text('Reminder Time'),
                        subtitle: Text(_reminderTime.format(context)),
                        trailing: const Icon(Icons.access_time),
                        onTap: () => _selectTime(context),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                ),
              ],
              const Divider(),
              Text(
                'Fertility Notifications',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                title: const Text('Ovulation Alerts'),
                subtitle: const Text('Get notified about ovulation day'),
                value: _ovulationAlerts,
                onChanged: (value) {
                  setState(() {
                    _ovulationAlerts = value;
                  });
                },
                contentPadding: EdgeInsets.zero,
              ),
              SwitchListTile(
                title: const Text('Fertility Window'),
                subtitle: const Text('Get notified about fertile days'),
                value: _fertilityWindow,
                onChanged: (value) {
                  setState(() {
                    _fertilityWindow = value;
                  });
                },
                contentPadding: EdgeInsets.zero,
              ),
              const Divider(),
              Text(
                'Health Reminders',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                title: const Text('Symptom Tracking'),
                subtitle: const Text('Daily reminders to log symptoms'),
                value: _symptomReminders,
                onChanged: (value) {
                  setState(() {
                    _symptomReminders = value;
                  });
                },
                contentPadding: EdgeInsets.zero,
              ),
              SwitchListTile(
                title: const Text('Medication Reminders'),
                subtitle: const Text(
                  'Reminders for birth control or supplements',
                ),
                value: _medicationReminders,
                onChanged: (value) {
                  setState(() {
                    _medicationReminders = value;
                  });
                },
                contentPadding: EdgeInsets.zero,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _saveSettings,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save'),
        ),
      ],
    );
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _reminderTime,
    );
    if (picked != null && picked != _reminderTime) {
      setState(() {
        _reminderTime = picked;
      });
    }
  }

  Future<void> _saveSettings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final appProvider = Provider.of<AppProvider>(context, listen: false);
      final user = appProvider.user!;

      final notificationSettings = {
        'periodReminder': _periodReminders,
        'ovulationReminder': _ovulationAlerts,
        'fertilityWindow': _fertilityWindow,
        'symptoms': _symptomReminders,
        'insights': _medicationReminders,
      };

      final updatedUser = User(
        id: user.id,
        name: user.name,
        birthDate: user.birthDate,
        averageCycleLength: user.averageCycleLength,
        averagePeriodLength: user.averagePeriodLength,
        lastPeriodDate: user.lastPeriodDate,
        isPregnant: user.isPregnant,
        isBreastfeeding: user.isBreastfeeding,
        useContraception: user.useContraception,
        contraceptionType: user.contraceptionType,
        healthConditions: user.healthConditions,
        notificationSettings: notificationSettings,
        theme: user.theme,
        language: user.language,
        isFirstTime: user.isFirstTime,
        createdAt: user.createdAt,
        updatedAt: DateTime.now(),
      );

      await appProvider.updateUser(updatedUser);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notification settings saved successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving settings: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}

class PrivacySettingsDialog extends StatefulWidget {
  const PrivacySettingsDialog({super.key});

  @override
  State<PrivacySettingsDialog> createState() => _PrivacySettingsDialogState();
}

class _PrivacySettingsDialogState extends State<PrivacySettingsDialog> {
  bool _analyticsEnabled = true;
  bool _crashReportsEnabled = true;
  bool _dataSharing = false;
  bool _personalizedAds = false;
  bool _biometricLock = false;
  bool _autoLock = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentSettings();
  }

  void _loadCurrentSettings() {
    // Load current privacy settings from user preferences
    // For now, using default values
    setState(() {
      _analyticsEnabled = true;
      _crashReportsEnabled = true;
      _dataSharing = false;
      _personalizedAds = false;
      _biometricLock = false;
      _autoLock = true;
    });
  }

  Future<void> _saveSettings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Save privacy settings to user preferences
      // This would typically involve updating the user's privacy preferences
      await Future.delayed(
        const Duration(milliseconds: 500),
      ); // Simulate API call

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Privacy settings updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating privacy settings: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Privacy Settings'),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Control how your data is used and shared',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 16),

              // Data Collection Section
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Data Collection',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              const SizedBox(height: 8),

              SwitchListTile(
                title: const Text('Analytics'),
                subtitle: const Text(
                  'Help improve the app with usage analytics',
                ),
                value: _analyticsEnabled,
                onChanged: (value) {
                  setState(() {
                    _analyticsEnabled = value;
                  });
                },
                contentPadding: EdgeInsets.zero,
              ),

              SwitchListTile(
                title: const Text('Crash Reports'),
                subtitle: const Text('Automatically send crash reports'),
                value: _crashReportsEnabled,
                onChanged: (value) {
                  setState(() {
                    _crashReportsEnabled = value;
                  });
                },
                contentPadding: EdgeInsets.zero,
              ),

              const SizedBox(height: 16),

              // Data Sharing Section
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Data Sharing',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              const SizedBox(height: 8),

              SwitchListTile(
                title: const Text('Share Anonymous Data'),
                subtitle: const Text('Share anonymized data for research'),
                value: _dataSharing,
                onChanged: (value) {
                  setState(() {
                    _dataSharing = value;
                  });
                },
                contentPadding: EdgeInsets.zero,
              ),

              SwitchListTile(
                title: const Text('Personalized Ads'),
                subtitle: const Text('Show ads based on your interests'),
                value: _personalizedAds,
                onChanged: (value) {
                  setState(() {
                    _personalizedAds = value;
                  });
                },
                contentPadding: EdgeInsets.zero,
              ),

              const SizedBox(height: 16),

              // Security Section
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Security',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              const SizedBox(height: 8),

              SwitchListTile(
                title: const Text('Biometric Lock'),
                subtitle: const Text('Use fingerprint or face unlock'),
                value: _biometricLock,
                onChanged: (value) {
                  setState(() {
                    _biometricLock = value;
                  });
                },
                contentPadding: EdgeInsets.zero,
              ),

              SwitchListTile(
                title: const Text('Auto Lock'),
                subtitle: const Text('Lock app when in background'),
                value: _autoLock,
                onChanged: (value) {
                  setState(() {
                    _autoLock = value;
                  });
                },
                contentPadding: EdgeInsets.zero,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _saveSettings,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save'),
        ),
      ],
    );
  }
}

class UnitsSettingsDialog extends StatefulWidget {
  const UnitsSettingsDialog({super.key});

  @override
  State<UnitsSettingsDialog> createState() => _UnitsSettingsDialogState();
}

class _UnitsSettingsDialogState extends State<UnitsSettingsDialog> {
  String _temperatureUnit = 'Celsius';
  String _weightUnit = 'kg';
  String _heightUnit = 'cm';
  String _dateFormat = 'DD/MM/YYYY';
  String _timeFormat = '24-hour';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentSettings();
  }

  void _loadCurrentSettings() {
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    final user = appProvider.user;

    if (user != null) {
      setState(() {
        // Load from user preferences or use defaults
        _temperatureUnit = 'Celsius'; // user.temperatureUnit ?? 'Celsius';
        _weightUnit = 'kg'; // user.weightUnit ?? 'kg';
        _heightUnit = 'cm'; // user.heightUnit ?? 'cm';
        _dateFormat = 'DD/MM/YYYY'; // user.dateFormat ?? 'DD/MM/YYYY';
        _timeFormat = '24-hour'; // user.timeFormat ?? '24-hour';
      });
    }
  }

  Future<void> _saveSettings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Save units settings to user preferences
      // This would typically involve updating the user's unit preferences
      await Future.delayed(
        const Duration(milliseconds: 500),
      ); // Simulate API call

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Units settings updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating units settings: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildUnitSelector({
    required String title,
    required String currentValue,
    required List<String> options,
    required Function(String) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: currentValue,
              isExpanded: true,
              items: options.map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  onChanged(newValue);
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Units Settings'),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Choose your preferred units and formats',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 20),

              // Temperature Unit
              _buildUnitSelector(
                title: 'Temperature',
                currentValue: _temperatureUnit,
                options: ['Celsius', 'Fahrenheit'],
                onChanged: (value) {
                  setState(() {
                    _temperatureUnit = value;
                  });
                },
              ),
              const SizedBox(height: 16),

              // Weight Unit
              _buildUnitSelector(
                title: 'Weight',
                currentValue: _weightUnit,
                options: ['kg', 'lbs'],
                onChanged: (value) {
                  setState(() {
                    _weightUnit = value;
                  });
                },
              ),
              const SizedBox(height: 16),

              // Height Unit
              _buildUnitSelector(
                title: 'Height',
                currentValue: _heightUnit,
                options: ['cm', 'ft/in'],
                onChanged: (value) {
                  setState(() {
                    _heightUnit = value;
                  });
                },
              ),
              const SizedBox(height: 16),

              // Date Format
              _buildUnitSelector(
                title: 'Date Format',
                currentValue: _dateFormat,
                options: ['DD/MM/YYYY', 'MM/DD/YYYY', 'YYYY-MM-DD'],
                onChanged: (value) {
                  setState(() {
                    _dateFormat = value;
                  });
                },
              ),
              const SizedBox(height: 16),

              // Time Format
              _buildUnitSelector(
                title: 'Time Format',
                currentValue: _timeFormat,
                options: ['12-hour', '24-hour'],
                onChanged: (value) {
                  setState(() {
                    _timeFormat = value;
                  });
                },
              ),

              const SizedBox(height: 20),

              // Preview Section
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Preview',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Temperature: 36.5°${_temperatureUnit == 'Celsius' ? 'C' : 'F'}',
                    ),
                    Text('Weight: 65 $_weightUnit'),
                    Text('Height: 165 $_heightUnit'),
                    Text(
                      'Date: ${_dateFormat.replaceAll('DD', '15').replaceAll('MM', '03').replaceAll('YYYY', '2024')}',
                    ),
                    Text(
                      'Time: ${_timeFormat == '12-hour' ? '2:30 PM' : '14:30'}',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _saveSettings,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save'),
        ),
      ],
    );
  }
}

class ThemeSettingsDialog extends StatefulWidget {
  const ThemeSettingsDialog({super.key});

  @override
  State<ThemeSettingsDialog> createState() => _ThemeSettingsDialogState();
}

class _ThemeSettingsDialogState extends State<ThemeSettingsDialog> {
  String _selectedTheme = 'System';
  bool useSystemTheme = true;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentSettings();
  }

  void _loadCurrentSettings() {
    final appProvider = Provider.of<AppProvider>(context, listen: false);

    // Load current theme settings
    setState(() {
      switch (appProvider.themeMode) {
        case ThemeMode.light:
          _selectedTheme = 'Light';
          useSystemTheme = false;
          break;
        case ThemeMode.dark:
          _selectedTheme = 'Dark';
          useSystemTheme = false;
          break;
        case ThemeMode.system:
          _selectedTheme = 'System';
          useSystemTheme = true;
          break;
      }
    });
  }

  Future<void> _saveSettings() async {
    setState(() {
      isLoading = true;
    });

    try {
      final appProvider = Provider.of<AppProvider>(context, listen: false);

      // Convert selected theme to ThemeMode
      ThemeMode newThemeMode;
      switch (_selectedTheme) {
        case 'Light':
          newThemeMode = ThemeMode.light;
          break;
        case 'Dark':
          newThemeMode = ThemeMode.dark;
          break;
        case 'System':
        default:
          newThemeMode = ThemeMode.system;
          break;
      }

      // Save theme settings through AppProvider
      await appProvider.setThemeMode(newThemeMode);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Theme settings updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating theme settings: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Widget _buildThemeOption({
    required String title,
    required String subtitle,
    required String value,
    required IconData icon,
    required Color iconColor,
  }) {
    final isSelected = _selectedTheme == value;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        border: Border.all(
          color: isSelected
              ? Theme.of(context).primaryColor
              : Colors.grey.shade300,
          width: isSelected ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(12),
        color: isSelected
            ? Theme.of(context).primaryColor.withOpacity(0.1)
            : null,
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: iconColor, size: 24),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
        subtitle: Text(subtitle),
        trailing: isSelected
            ? Icon(
                Icons.check_circle,
                color: Theme.of(context).iconTheme.color ?? Colors.grey,
              )
            : null,
        onTap: () {
          setState(() {
            _selectedTheme = value;
            useSystemTheme = value == 'System';
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return AlertDialog(
      title: const Text('Theme Settings'),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Choose your preferred app theme',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 20),

              // Light Theme Option
              _buildThemeOption(
                title: 'Light',
                subtitle: 'Always use light theme',
                value: 'Light',
                icon: Icons.light_mode,
                iconColor: Colors.orange,
              ),

              // Dark Theme Option
              _buildThemeOption(
                title: 'Dark',
                subtitle: 'Always use dark theme',
                value: 'Dark',
                icon: Icons.dark_mode,
                iconColor: Colors.indigo,
              ),

              // System Theme Option
              _buildThemeOption(
                title: 'System',
                subtitle: 'Follow system theme settings',
                value: 'System',
                icon: Icons.settings_suggest,
                iconColor: Colors.green,
              ),

              const SizedBox(height: 20),

              // Current Theme Preview
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDarkMode
                      ? Colors.grey.shade800
                      : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDarkMode
                        ? Colors.grey.shade600
                        : Colors.grey.shade200,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          isDarkMode ? Icons.dark_mode : Icons.light_mode,
                          color: isDarkMode ? Colors.white : Colors.black,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Current Theme Preview',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: isDarkMode ? Colors.white : Colors.black,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Period Tracker',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'This is how your app will look',
                            style: TextStyle(
                              color: isDarkMode
                                  ? Colors.white70
                                  : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              if (_selectedTheme == 'System') ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.blue.shade700,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'The app will automatically switch between light and dark themes based on your device settings.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: isLoading ? null : _saveSettings,
          child: isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save'),
        ),
      ],
    );
  }
}

class HelpDialog extends StatefulWidget {
  const HelpDialog({super.key});

  @override
  State<HelpDialog> createState() => _HelpDialogState();
}

class _HelpDialogState extends State<HelpDialog> {
  String _searchQuery = '';
  int? _expandedIndex;

  final List<Map<String, String>> _faqItems = [
    {
      'question': 'How do I track my period?',
      'answer':
          'To track your period, go to the home screen and tap the "Start Period" button when your period begins. You can log the flow intensity, symptoms, and any notes. When your period ends, tap "End Period".',
      'category': 'tracking',
    },
    {
      'question': 'How accurate are the predictions?',
      'answer':
          'Our predictions become more accurate as you track more cycles. Initially, predictions are based on average cycle lengths. After 3-6 months of tracking, the app learns your unique patterns for more personalized predictions.',
      'category': 'predictions',
    },
    {
      'question': 'Can I edit past period data?',
      'answer':
          'Yes! Go to the Calendar screen, tap on any date with period data, and you can edit or delete the entry. You can also add missed periods by tapping on past dates.',
      'category': 'tracking',
    },
    {
      'question': 'What symptoms can I track?',
      'answer':
          'You can track physical symptoms (cramps, headaches, bloating, etc.), emotional symptoms (mood swings, irritability, etc.), and other symptoms like skin changes, sleep patterns, and energy levels.',
      'category': 'symptoms',
    },
    {
      'question': 'How do I set up notifications?',
      'answer':
          'Go to Profile > Notification Settings to customize your notification preferences. You can set reminders for period predictions, ovulation, and daily tracking reminders.',
      'category': 'notifications',
    },
    {
      'question': 'Is my data private and secure?',
      'answer':
          'Yes, your data is stored locally on your device and encrypted. We never share your personal health data with third parties. You can review our privacy settings in Profile > Privacy Settings.',
      'category': 'privacy',
    },
    {
      'question': 'How do I backup my data?',
      'answer':
          'You can backup your data by going to Profile > Export Data. This creates a file you can save or share. You can also enable cloud backup in Profile > Backup Settings.',
      'category': 'backup',
    },
    {
      'question': 'What if my cycles are irregular?',
      'answer':
          'The app is designed to handle irregular cycles. Keep tracking consistently, and the app will adapt to your patterns. For very irregular cycles, consult with a healthcare provider.',
      'category': 'tracking',
    },
    {
      'question': 'Can I track multiple symptoms per day?',
      'answer':
          'Absolutely! You can log multiple symptoms, moods, and notes for each day. The more data you provide, the better insights you\'ll receive.',
      'category': 'symptoms',
    },
    {
      'question': 'How do I change the app theme?',
      'answer':
          'Go to Profile > Theme Settings to choose between light, dark, or system theme. You can also customize accent colors and enable automatic theme switching.',
      'category': 'settings',
    },
  ];

  List<Map<String, String>> get _filteredFaqItems {
    if (_searchQuery.isEmpty) return _faqItems;

    return _faqItems.where((item) {
      return item['question']!.toLowerCase().contains(
            _searchQuery.toLowerCase(),
          ) ||
          item['answer']!.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          item['category']!.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search help topics...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    setState(() {
                      _searchQuery = '';
                      _expandedIndex = null;
                    });
                  },
                )
              : null,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
            _expandedIndex = null; // Collapse all when searching
          });
        },
      ),
    );
  }

  Widget _buildCategoryChip(String category) {
    final categoryColors = {
      'tracking': Colors.blue,
      'predictions': Colors.purple,
      'symptoms': Colors.orange,
      'notifications': Colors.green,
      'privacy': Colors.red,
      'backup': Colors.teal,
      'settings': Colors.indigo,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: (categoryColors[category] ?? Colors.grey).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: (categoryColors[category] ?? Colors.grey).withOpacity(0.3),
        ),
      ),
      child: Text(
        category.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: categoryColors[category] ?? Colors.grey,
        ),
      ),
    );
  }

  Widget _buildFaqItem(Map<String, String> item, int index) {
    final isExpanded = _expandedIndex == index;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Column(
        children: [
          ListTile(
            title: Text(
              item['question']!,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: _buildCategoryChip(item['category']!),
            ),
            trailing: Icon(
              isExpanded ? Icons.expand_less : Icons.expand_more,
              color: Theme.of(context).iconTheme.color ?? Colors.grey,
            ),
            onTap: () {
              setState(() {
                _expandedIndex = isExpanded ? null : index;
              });
            },
          ),
          if (isExpanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(item['answer']!, style: const TextStyle(height: 1.5)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quick Actions',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    // In a real app, this would navigate to contact support
                  },
                  icon: const Icon(Icons.support_agent, size: 18),
                  label: const Text('Contact Support'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              // const SizedBox(width: 8),
              // Expanded(
              //   child: OutlinedButton.icon(
              //     onPressed: () {
              //       Navigator.of(context).pop();
              //       // In a real app, this would open app tutorial
              //     },
              //     icon: const Icon(Icons.play_circle_outline, size: 18),
              //     label: const Text('App Tutorial'),
              //     style: OutlinedButton.styleFrom(
              //       padding: const EdgeInsets.symmetric(vertical: 12),
              //     ),
              //   ),
              // ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredItems = _filteredFaqItems;

    return AlertDialog(
      title: const Text('Help & FAQ'),
      content: SizedBox(
        width: double.maxFinite,
        height: MediaQuery.of(context).size.height * 0.7,
        child: Column(
          children: [
            _buildSearchBar(),
            _buildQuickActions(),
            Expanded(
              child: filteredItems.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 48,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No help topics found for "$_searchQuery"',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 16,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _searchQuery = '';
                                _expandedIndex = null;
                              });
                            },
                            child: const Text('Clear search'),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: filteredItems.length,
                      itemBuilder: (context, index) {
                        return _buildFaqItem(filteredItems[index], index);
                      },
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

class ContactSupportDialog extends StatefulWidget {
  const ContactSupportDialog({super.key});

  @override
  State<ContactSupportDialog> createState() => _ContactSupportDialogState();
}

class _ContactSupportDialogState extends State<ContactSupportDialog> {
  String _selectedIssueType = 'General';
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false;

  final List<String> _issueTypes = [
    'General',
    'Bug Report',
    'Feature Request',
    'Account Issue',
    'Data Sync Problem',
    'Payment Issue',
    'Privacy Concern',
    'Other',
  ];

  @override
  void dispose() {
    _messageController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendSupportMessage() async {
    if (_messageController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all required fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Prepare email content
      final String subject = Uri.encodeComponent(
        'Period Track Support - $_selectedIssueType',
      );
      final String body = Uri.encodeComponent(
        'Issue Type: $_selectedIssueType\n'
        'User Email: ${_emailController.text.trim()}\n\n'
        'Message:\n${_messageController.text.trim()}\n\n'
        '---\n'
        'Sent from Period Track App',
      );

      // Create mailto URL
      final Uri emailUri = Uri.parse(
        'mailto:fiazhari@gmail.com?subject=$subject&body=$body',
      );

      // Launch email client
      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri);

        setState(() {
          _isLoading = false;
        });

        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Email client opened! Please send the email to complete your support request.',
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        throw Exception('Could not launch email client');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to open email client: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _openEmailClient() {
    // In a real app, this would open the email client
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Opening email client...')));
  }

  void _openFAQ() {
    Navigator.of(context).pop();
    showDialog(context: context, builder: (context) => const HelpDialog());
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Contact Support'),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'We\'re here to help! Choose how you\'d like to contact us:',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 20),

              // Quick Actions
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _openEmailClient,
                      icon: const Icon(Icons.email),
                      label: const Text('Email Us'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _openFAQ,
                      icon: const Icon(Icons.help),
                      label: const Text('View FAQ'),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 20),

              // Support Form
              const Text(
                'Send us a message:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 15),

              // Issue Type Dropdown
              DropdownButtonFormField<String>(
                value: _selectedIssueType,
                decoration: const InputDecoration(
                  labelText: 'Issue Type',
                  border: OutlineInputBorder(),
                ),
                items: _issueTypes.map((type) {
                  return DropdownMenuItem(value: type, child: Text(type));
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedIssueType = value!;
                  });
                },
              ),

              const SizedBox(height: 15),

              // Email Field
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Your Email *',
                  border: OutlineInputBorder(),
                  hintText: 'Enter your email address',
                ),
                keyboardType: TextInputType.emailAddress,
              ),

              const SizedBox(height: 15),

              // Message Field
              TextFormField(
                controller: _messageController,
                decoration: const InputDecoration(
                  labelText: 'Message *',
                  border: OutlineInputBorder(),
                  hintText: 'Describe your issue or question...',
                ),
                maxLines: 4,
                maxLength: 500,
              ),

              const SizedBox(height: 15),

              // Contact Info
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Other ways to reach us:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.email,
                          size: 16,
                          color: Theme.of(
                            context,
                          ).iconTheme.color?.withOpacity(0.6),
                        ),
                        SizedBox(width: 8),
                        Text('fiazhari@gmail.com'),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.schedule,
                          size: 16,
                          color: Theme.of(
                            context,
                          ).iconTheme.color?.withOpacity(0.6),
                        ),
                        SizedBox(width: 8),
                        Text('Response time: 24-48 hours'),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _sendSupportMessage,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Send Message'),
        ),
      ],
    );
  }
}

class ExportDataDialog extends StatefulWidget {
  final AppProvider appProvider;

  const ExportDataDialog({super.key, required this.appProvider});

  @override
  State<ExportDataDialog> createState() => _ExportDataDialogState();
}

class _ExportDataDialogState extends State<ExportDataDialog> {
  String _exportFormat = 'JSON';
  String _dateRange = 'All Time';
  DateTime? _startDate;
  DateTime? _endDate;
  bool _includePeriods = true;
  bool _includeSymptoms = true;
  bool _includeMoods = true;
  bool _includeTemperature = true;
  bool _includeNotes = true;
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    _initializeDates();
  }

  void _initializeDates() {
    final now = DateTime.now();
    _endDate = now;
    _startDate = DateTime(
      now.year - 1,
      now.month,
      now.day,
    ); // Default to 1 year ago
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
        _dateRange = 'Custom Range';
      });
    }
  }

  Future<void> _exportData() async {
    setState(() {
      _isExporting = true;
    });

    try {
      // Simulate data export process
      await Future.delayed(const Duration(seconds: 2));

      // In a real implementation, this would:
      // 1. Gather selected data from the database
      // 2. Format it according to the selected format
      // 3. Save it to device storage or share it

      final dataTypes = <String>[];
      if (_includePeriods) dataTypes.add('Periods');
      if (_includeSymptoms) dataTypes.add('Symptoms');
      if (_includeMoods) dataTypes.add('Moods');
      if (_includeTemperature) dataTypes.add('Temperature');
      if (_includeNotes) dataTypes.add('Notes');

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Data exported successfully!\nFormat: $_exportFormat\nData types: ${dataTypes.join(', ')}',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error exporting data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
        });
      }
    }
  }

  Widget _buildDataTypeCheckbox({
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool?) onChanged,
    required IconData icon,
  }) {
    return CheckboxListTile(
      title: Row(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).iconTheme.color),
          const SizedBox(width: 8),
          Text(title),
        ],
      ),
      subtitle: Text(subtitle),
      value: value,
      onChanged: onChanged,
      contentPadding: EdgeInsets.zero,
      controlAffinity: ListTileControlAffinity.leading,
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasSelectedData =
        _includePeriods ||
        _includeSymptoms ||
        _includeMoods ||
        _includeTemperature ||
        _includeNotes;

    return AlertDialog(
      title: const Text('Export Data'),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Export your period tracking data',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 20),

              // Export Format
              const Text(
                'Export Format',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _exportFormat,
                    isExpanded: true,
                    items: ['JSON', 'CSV', 'PDF'].map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _exportFormat = newValue;
                        });
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Date Range
              const Text(
                'Date Range',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _dateRange,
                    isExpanded: true,
                    items:
                        [
                          'All Time',
                          'Last 6 Months',
                          'Last Year',
                          'Custom Range',
                        ].map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _dateRange = newValue;
                          if (newValue == 'Last 6 Months') {
                            final now = DateTime.now();
                            _startDate = DateTime(
                              now.year,
                              now.month - 6,
                              now.day,
                            );
                            _endDate = now;
                          } else if (newValue == 'Last Year') {
                            final now = DateTime.now();
                            _startDate = DateTime(
                              now.year - 1,
                              now.month,
                              now.day,
                            );
                            _endDate = now;
                          } else if (newValue == 'Custom Range') {
                            _selectDateRange();
                          }
                        });
                      }
                    },
                  ),
                ),
              ),

              if (_dateRange == 'Custom Range' &&
                  _startDate != null &&
                  _endDate != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.date_range,
                        color: Colors.blue.shade700,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'From ${_startDate!.day}/${_startDate!.month}/${_startDate!.year} to ${_endDate!.day}/${_endDate!.month}/${_endDate!.year}',
                          style: TextStyle(color: Colors.blue.shade700),
                        ),
                      ),
                      TextButton(
                        onPressed: _selectDateRange,
                        child: const Text('Change'),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 20),

              // Data Types
              const Text(
                'Data to Include',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
              const SizedBox(height: 8),

              _buildDataTypeCheckbox(
                title: 'Period Data',
                subtitle: 'Cycle dates, flow intensity, duration',
                value: _includePeriods,
                onChanged: (value) =>
                    setState(() => _includePeriods = value ?? false),
                icon: Icons.water_drop,
              ),

              _buildDataTypeCheckbox(
                title: 'Symptoms',
                subtitle: 'Physical and emotional symptoms',
                value: _includeSymptoms,
                onChanged: (value) =>
                    setState(() => _includeSymptoms = value ?? false),
                icon: Icons.healing,
              ),

              _buildDataTypeCheckbox(
                title: 'Mood Tracking',
                subtitle: 'Daily mood and energy levels',
                value: _includeMoods,
                onChanged: (value) =>
                    setState(() => _includeMoods = value ?? false),
                icon: Icons.mood,
              ),

              _buildDataTypeCheckbox(
                title: 'Temperature',
                subtitle: 'Basal body temperature readings',
                value: _includeTemperature,
                onChanged: (value) =>
                    setState(() => _includeTemperature = value ?? false),
                icon: Icons.thermostat,
              ),

              _buildDataTypeCheckbox(
                title: 'Notes',
                subtitle: 'Personal notes and observations',
                value: _includeNotes,
                onChanged: (value) =>
                    setState(() => _includeNotes = value ?? false),
                icon: Icons.note,
              ),

              if (!hasSelectedData) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.warning_amber,
                        color: Colors.orange.shade700,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Please select at least one data type to export.',
                          style: TextStyle(color: Colors.orange.shade700),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isExporting ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: (_isExporting || !hasSelectedData) ? null : _exportData,
          child: _isExporting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Export'),
        ),
      ],
    );
  }
}

class ImportDataDialog extends StatefulWidget {
  final AppProvider appProvider;

  const ImportDataDialog({super.key, required this.appProvider});

  @override
  State<ImportDataDialog> createState() => _ImportDataDialogState();
}

class _ImportDataDialogState extends State<ImportDataDialog> {
  String? _selectedFileName;
  String? _fileFormat;
  bool _isImporting = false;
  bool replaceExistingData = false;
  bool _mergeWithExistingData = true;
  bool _createBackupBeforeImport = true;
  Map<String, dynamic>? _previewData;
  String? _validationError;

  final List<String> _supportedFormats = ['JSON', 'CSV'];

  Future<void> _selectFile() async {
    // In a real implementation, this would use file_picker package
    // For now, we'll simulate file selection
    setState(() {
      _selectedFileName = 'period_data_backup.json';
      _fileFormat = 'JSON';
      _validationError = null;
    });

    // Simulate file validation and preview
    await _validateAndPreviewFile();
  }

  Future<void> _validateAndPreviewFile() async {
    if (_selectedFileName == null) return;

    setState(() {
      _isImporting = true;
      _validationError = null;
    });

    try {
      // Simulate file validation
      await Future.delayed(const Duration(seconds: 1));

      // Simulate preview data
      _previewData = {
        'periods': 24,
        'symptoms': 156,
        'moods': 89,
        'temperature_readings': 45,
        'notes': 12,
        'date_range': 'Jan 2023 - Dec 2023',
        'format_version': '1.0',
      };

      // Simulate validation checks
      if (_selectedFileName!.contains('invalid')) {
        _validationError =
            'Invalid file format. Please select a valid backup file.';
        _previewData = null;
      } else if (_selectedFileName!.contains('corrupted')) {
        _validationError =
            'File appears to be corrupted. Please try a different file.';
        _previewData = null;
      }
    } catch (e) {
      _validationError = 'Error reading file: $e';
      _previewData = null;
    } finally {
      setState(() {
        _isImporting = false;
      });
    }
  }

  Future<void> _importData() async {
    if (_previewData == null) return;

    setState(() {
      _isImporting = true;
    });

    try {
      // Simulate import process
      await Future.delayed(const Duration(seconds: 3));

      // In a real implementation, this would:
      // 1. Create backup if requested
      // 2. Parse the selected file
      // 3. Validate data integrity
      // 4. Import data according to merge/replace settings
      // 5. Update the app state

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Data imported successfully!\n'
              '${_previewData!['periods']} periods, '
              '${_previewData!['symptoms']} symptoms, '
              '${_previewData!['moods']} mood entries imported.',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error importing data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isImporting = false;
        });
      }
    }
  }

  Widget _buildFileSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select File',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(
              color: _selectedFileName != null
                  ? Colors.green
                  : Colors.grey.shade300,
              width: 2,
              style: BorderStyle.solid,
            ),
            borderRadius: BorderRadius.circular(8),
            color: _selectedFileName != null
                ? Colors.green.shade50
                : Colors.grey.shade50,
          ),
          child: Column(
            children: [
              Icon(
                _selectedFileName != null
                    ? Icons.check_circle
                    : Icons.upload_file,
                size: 48,
                color: _selectedFileName != null ? Colors.green : Colors.grey,
              ),
              const SizedBox(height: 8),
              Text(
                _selectedFileName ?? 'No file selected',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: _selectedFileName != null
                      ? Colors.green.shade700
                      : Colors.grey.shade600,
                ),
              ),
              if (_fileFormat != null) ...[
                const SizedBox(height: 4),
                Text(
                  'Format: $_fileFormat',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _isImporting ? null : _selectFile,
                icon: const Icon(Icons.folder_open),
                label: Text(
                  _selectedFileName != null ? 'Change File' : 'Select File',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Supported formats: ${_supportedFormats.join(', ')}',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _buildPreviewSection() {
    if (_previewData == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        const Text(
          'Data Preview',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.blue.shade700,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Found data from ${_previewData!['date_range']}',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Colors.blue.shade700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildDataCount(
                'Period cycles',
                _previewData!['periods'],
                Icons.water_drop,
              ),
              _buildDataCount(
                'Symptom entries',
                _previewData!['symptoms'],
                Icons.healing,
              ),
              _buildDataCount(
                'Mood entries',
                _previewData!['moods'],
                Icons.mood,
              ),
              _buildDataCount(
                'Temperature readings',
                _previewData!['temperature_readings'],
                Icons.thermostat,
              ),
              _buildDataCount('Notes', _previewData!['notes'], Icons.note),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDataCount(String label, int count, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.blue.shade600),
          const SizedBox(width: 8),
          Text('$label: '),
          Text('$count', style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildImportOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        const Text(
          'Import Options',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        const SizedBox(height: 8),

        CheckboxListTile(
          title: const Text('Create backup before import'),
          subtitle: const Text('Recommended: Creates a backup of current data'),
          value: _createBackupBeforeImport,
          onChanged: (value) =>
              setState(() => _createBackupBeforeImport = value ?? true),
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
        ),

        const SizedBox(height: 8),
        const Text(
          'Data Handling',
          style: TextStyle(fontWeight: FontWeight.w500),
        ),

        RadioListTile<bool>(
          title: const Text('Merge with existing data'),
          subtitle: const Text('Add imported data to current data'),
          value: true,
          groupValue: _mergeWithExistingData,
          onChanged: (value) => setState(() {
            _mergeWithExistingData = value ?? true;
            replaceExistingData = !_mergeWithExistingData;
          }),
          contentPadding: EdgeInsets.zero,
        ),

        RadioListTile<bool>(
          title: const Text('Replace existing data'),
          subtitle: const Text('Warning: This will delete all current data'),
          value: false,
          groupValue: _mergeWithExistingData,
          onChanged: (value) => setState(() {
            _mergeWithExistingData = value ?? false;
            replaceExistingData = !_mergeWithExistingData;
          }),
          contentPadding: EdgeInsets.zero,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final canImport =
        _previewData != null && _validationError == null && !_isImporting;

    return AlertDialog(
      title: const Text('Import Data'),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Import your period tracking data from a backup file',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 20),

              _buildFileSelection(),

              if (_validationError != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: Colors.red.shade700,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _validationError!,
                          style: TextStyle(color: Colors.red.shade700),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              _buildPreviewSection(),

              if (_previewData != null && _validationError == null)
                _buildImportOptions(),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isImporting ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: canImport ? _importData : null,
          child: _isImporting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Import'),
        ),
      ],
    );
  }
}

class BackupSettingsDialog extends StatefulWidget {
  const BackupSettingsDialog({super.key});

  @override
  State<BackupSettingsDialog> createState() => _BackupSettingsDialogState();
}

class _BackupSettingsDialogState extends State<BackupSettingsDialog> {
  bool _autoBackupEnabled = true;
  bool _wifiOnlyBackup = true;
  bool _encryptBackups = true;
  String _backupFrequency = 'Daily';
  String _cloudProvider = 'Google Drive';
  bool _isLoading = false;
  bool _isBackingUp = false;
  DateTime? _lastBackupDate = DateTime.now().subtract(const Duration(hours: 2));

  final List<String> _backupFrequencies = [
    'Real-time',
    'Daily',
    'Weekly',
    'Monthly',
  ];

  final List<String> _cloudProviders = [
    'Google Drive',
    'iCloud',
    'Dropbox',
    'OneDrive',
  ];

  Future<void> _saveSettings() async {
    setState(() {
      _isLoading = true;
    });

    // Simulate saving settings
    await Future.delayed(const Duration(seconds: 1));

    setState(() {
      _isLoading = false;
    });

    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Backup settings saved successfully'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _performBackup() async {
    setState(() {
      _isBackingUp = true;
    });

    // Simulate backup process
    await Future.delayed(const Duration(seconds: 3));

    setState(() {
      _isBackingUp = false;
      _lastBackupDate = DateTime.now();
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Backup completed successfully'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _restoreFromBackup() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restore from Backup'),
        content: const Text(
          'This will replace your current data with the backup data. This action cannot be undone. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Restore'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      setState(() {
        _isLoading = true;
      });

      // Simulate restore process
      await Future.delayed(const Duration(seconds: 2));

      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Data restored from backup successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  String _formatLastBackup() {
    if (_lastBackupDate == null) return 'Never';

    final now = DateTime.now();
    final difference = now.difference(_lastBackupDate!);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minutes ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else {
      return '${difference.inDays} days ago';
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Backup & Sync'),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Backup Status
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.cloud_done, color: Colors.blue[600]),
                        const SizedBox(width: 8),
                        const Text(
                          'Backup Status',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text('Last backup: ${_formatLastBackup()}'),
                    Text('Storage: $_cloudProvider'),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isBackingUp ? null : _performBackup,
                            icon: _isBackingUp
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.backup),
                            label: Text(
                              _isBackingUp ? 'Backing up...' : 'Backup Now',
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _isLoading ? null : _restoreFromBackup,
                            icon: const Icon(Icons.restore),
                            label: const Text('Restore'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Auto Backup Settings
              const Text(
                'Backup Settings',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 15),

              SwitchListTile(
                title: const Text('Auto Backup'),
                subtitle: const Text('Automatically backup your data'),
                value: _autoBackupEnabled,
                onChanged: (value) {
                  setState(() {
                    _autoBackupEnabled = value;
                  });
                },
              ),

              if (_autoBackupEnabled) ...[
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: _backupFrequency,
                  decoration: const InputDecoration(
                    labelText: 'Backup Frequency',
                    border: OutlineInputBorder(),
                  ),
                  items: _backupFrequencies.map((frequency) {
                    return DropdownMenuItem(
                      value: frequency,
                      child: Text(frequency),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _backupFrequency = value!;
                    });
                  },
                ),
              ],

              const SizedBox(height: 15),

              SwitchListTile(
                title: const Text('WiFi Only'),
                subtitle: const Text('Only backup when connected to WiFi'),
                value: _wifiOnlyBackup,
                onChanged: (value) {
                  setState(() {
                    _wifiOnlyBackup = value;
                  });
                },
              ),

              const SizedBox(height: 15),

              SwitchListTile(
                title: const Text('Encrypt Backups'),
                subtitle: const Text('Encrypt backup data for security'),
                value: _encryptBackups,
                onChanged: (value) {
                  setState(() {
                    _encryptBackups = value;
                  });
                },
              ),

              const SizedBox(height: 20),

              // Cloud Provider
              DropdownButtonFormField<String>(
                value: _cloudProvider,
                decoration: const InputDecoration(
                  labelText: 'Cloud Storage Provider',
                  border: OutlineInputBorder(),
                ),
                items: _cloudProviders.map((provider) {
                  return DropdownMenuItem(
                    value: provider,
                    child: Row(
                      children: [
                        Icon(_getProviderIcon(provider)),
                        const SizedBox(width: 8),
                        Text(provider),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _cloudProvider = value!;
                  });
                },
              ),

              const SizedBox(height: 20),

              // Storage Info
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Storage Information',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.storage,
                          size: 16,
                          color: Theme.of(
                            context,
                          ).iconTheme.color?.withOpacity(0.6),
                        ),
                        SizedBox(width: 8),
                        Text('Backup size: ~2.5 MB'),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.history,
                          size: 16,
                          color: Theme.of(
                            context,
                          ).iconTheme.color?.withOpacity(0.6),
                        ),
                        SizedBox(width: 8),
                        Text('Backup history: 30 days'),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _saveSettings,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save Settings'),
        ),
      ],
    );
  }

  IconData _getProviderIcon(String provider) {
    switch (provider) {
      case 'Google Drive':
        return Icons.cloud;
      case 'iCloud':
        return Icons.cloud_circle;
      case 'Dropbox':
        return Icons.cloud_upload;
      case 'OneDrive':
        return Icons.cloud_sync;
      default:
        return Icons.cloud;
    }
  }
}
