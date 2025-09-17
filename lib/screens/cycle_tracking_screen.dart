import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/period.dart';
import '../models/symptom.dart';
import '../providers/app_provider.dart';
import '../services/performance_service.dart';
import '../services/prediction_service.dart';

class CycleTrackingScreen extends StatefulWidget {
  const CycleTrackingScreen({super.key});

  @override
  State<CycleTrackingScreen> createState() => _CycleTrackingScreenState();
}

class _CycleTrackingScreenState extends State<CycleTrackingScreen> {
  final PerformanceService _performanceService = PerformanceService();

  @override
  void initState() {
    super.initState();
    _performanceService.startOperation('cycle_tracking_init');

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _performanceService.endOperation('cycle_tracking_init');
    });
  }

  @override
  Widget build(BuildContext context) {
    _performanceService.startOperation('cycle_tracking_build');
    return Scaffold(
      appBar: AppBar(
        title: const Text('Period Track'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddPeriodDialog(context),
          ),
        ],
      ),
      body: Consumer<AppProvider>(
        builder: (context, appProvider, child) {
          if (appProvider.user == null) {
            return const Center(child: Text('Please complete setup first'));
          }

          final result = SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCycleOverviewCard(appProvider),
                const SizedBox(height: 16),
                _buildQuickActionsCard(appProvider),
                const SizedBox(height: 16),
                _buildPredictionsCard(appProvider),
                const SizedBox(height: 16),
                _buildRecentPeriodsCard(appProvider),
                const SizedBox(height: 16),
                _buildTodaysSymptomsCard(appProvider),
              ],
            ),
          );

          _performanceService.endOperation('cycle_tracking_build');
          return result;
        },
      ),
    );
  }

  Widget _buildCycleOverviewCard(AppProvider appProvider) {
    final user = appProvider.user!;
    final periods = appProvider.periods;

    // Cache prediction calculations for better performance
    final cacheKey = 'cycle_overview_${user.id}_${periods.length}';
    var cachedData = _performanceService.getCachedData<Map<String, dynamic>>(
      cacheKey,
    );

    if (cachedData == null) {
      _performanceService.startOperation('cycle_prediction_calculation');

      final nextPeriod = periods.isNotEmpty
          ? PredictionService.predictNextPeriod(periods, user)
          : null;

      final daysUntilNext = nextPeriod != null
          ? nextPeriod.difference(DateTime.now()).inDays
          : null;

      cachedData = {'nextPeriod': nextPeriod, 'daysUntilNext': daysUntilNext};

      _performanceService.cacheData(cacheKey, cachedData);
      _performanceService.endOperation('cycle_prediction_calculation');
    }

    final nextPeriod = cachedData['nextPeriod'] as DateTime?;
    final daysUntilNext = cachedData['daysUntilNext'] as int?;

    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.favorite,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Cycle Overview',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildOverviewItem(
                    'Next Period',
                    daysUntilNext != null
                        ? daysUntilNext > 0
                              ? 'In $daysUntilNext days'
                              : daysUntilNext == 0
                              ? 'Today'
                              : '${-daysUntilNext} days late'
                        : 'Unknown',
                    Icons.calendar_today,
                    daysUntilNext != null && daysUntilNext < 0
                        ? Colors.red
                        : Theme.of(context).primaryColor,
                  ),
                ),
                Expanded(
                  child: _buildOverviewItem(
                    'Cycle Length',
                    '${user.averageCycleLength} days',
                    Icons.refresh,
                    Theme.of(context).primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildOverviewItem(
                    'Period Length',
                    '${user.averagePeriodLength} days',
                    Icons.water_drop,
                    Theme.of(context).primaryColor,
                  ),
                ),
                Expanded(
                  child: _buildOverviewItem(
                    'Total Cycles',
                    '${periods.length}',
                    Icons.analytics,
                    Theme.of(context).primaryColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.7)),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildQuickActionsCard(AppProvider appProvider) {
    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Actions',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    'Log Period',
                    Icons.water_drop,
                    Colors.pink,
                    () => _showAddPeriodDialog(context),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    'Add Symptoms',
                    Icons.healing,
                    Colors.orange,
                    () => _showAddSymptomsDialog(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    'Track Mood',
                    Icons.mood,
                    Colors.purple,
                    () => _showMoodTrackingDialog(context),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    'Temperature',
                    Icons.thermostat,
                    Colors.blue,
                    () => _showTemperatureDialog(context),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
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
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPredictionsCard(AppProvider appProvider) {
    final user = appProvider.user!;
    final periods = appProvider.periods;

    if (periods.isEmpty) {
      return Card(
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Icon(Icons.insights, size: 48, color: Colors.grey.shade400),
              const SizedBox(height: 12),
              Text(
                'No predictions yet',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Log your first period to see predictions',
                style: TextStyle(color: Colors.grey.shade600),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    final nextPeriod = PredictionService.predictNextPeriod(periods, user);
    final nextOvulation = PredictionService.predictOvulation(periods, user);
    final fertilityWindow = PredictionService.calculateFertilityWindow(
      periods,
      user,
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.insights, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Predictions',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (nextPeriod != null) ...[
              _buildPredictionItem(
                'Next Period',
                DateFormat('MMM dd, yyyy').format(nextPeriod),
                Icons.water_drop,
                Colors.pink,
              ),
              const SizedBox(height: 12),
            ],
            if (nextOvulation != null) ...[
              _buildPredictionItem(
                'Next Ovulation',
                DateFormat('MMM dd, yyyy').format(nextOvulation),
                Icons.egg,
                Colors.orange,
              ),
              const SizedBox(height: 12),
            ],
            if (fertilityWindow != null) ...[
              _buildPredictionItem(
                'Fertility Window',
                '${DateFormat('MMM dd').format(fertilityWindow['start']!)} - ${DateFormat('MMM dd').format(fertilityWindow['end']!)}',
                Icons.favorite,
                Colors.green,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPredictionItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                value,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRecentPeriodsCard(AppProvider appProvider) {
    final periods = appProvider.periods.take(3).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Periods',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: () {
                    // Navigate to full period history
                  },
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (periods.isEmpty)
              Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.water_drop_outlined,
                      size: 48,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No periods logged yet',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              )
            else
              ...periods.map((period) => _buildPeriodItem(period)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodItem(Period period) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: _getFlowColor(period.flow),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('MMM dd, yyyy').format(period.startDate),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  period.endDate != null ? '${period.length} days' : 'Ongoing',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          Text(
            _getFlowText(period.flow),
            style: TextStyle(
              fontSize: 12,
              color: _getFlowColor(period.flow),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodaysSymptomsCard(AppProvider appProvider) {
    final today = DateTime.now();
    final todaysSymptoms = appProvider.symptoms
        .where((s) => DateUtils.isSameDay(s.date, today))
        .toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Today\'s Symptoms',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: () => _showAddSymptomsDialog(context),
                  child: const Text('Add'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (todaysSymptoms.isEmpty)
              Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.healing_outlined,
                      size: 48,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No symptoms logged today',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              )
            else
              ...todaysSymptoms
                  .map((symptom) => _buildSymptomItem(symptom))
                  .toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildSymptomItem(Symptom symptom) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(Icons.circle, size: 8, color: Theme.of(context).primaryColor),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              [
                ...symptom.physicalSymptoms,
                ...symptom.emotionalSymptoms,
              ].join(', '),
              style: const TextStyle(fontSize: 14),
            ),
          ),
          if (symptom.painLevel != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getPainLevelColor(symptom.painLevel!).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Pain: ${symptom.painLevel}/10',
                style: TextStyle(
                  fontSize: 10,
                  color: _getPainLevelColor(symptom.painLevel!),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Color _getFlowColor(int flow) {
    switch (flow) {
      case 1:
        return Colors.pink.shade200;
      case 2:
        return Colors.pink.shade400;
      case 3:
        return Colors.pink.shade600;
      case 4:
        return Colors.red.shade600;
      case 5:
        return Colors.red.shade800;
      default:
        return Colors.pink;
    }
  }

  String _getFlowText(int flow) {
    switch (flow) {
      case 1:
        return 'Light';
      case 2:
        return 'Light-Medium';
      case 3:
        return 'Medium';
      case 4:
        return 'Heavy';
      case 5:
        return 'Very Heavy';
      default:
        return 'Medium';
    }
  }

  Color _getPainLevelColor(int painLevel) {
    if (painLevel <= 3) return Colors.green;
    if (painLevel <= 6) return Colors.orange;
    return Colors.red;
  }

  void _showAddPeriodDialog(BuildContext context) {
    showDialog(context: context, builder: (context) => const AddPeriodDialog());
  }

  void _showAddSymptomsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const AddSymptomsDialog(),
    );
  }

  void _showMoodTrackingDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const MoodTrackingDialog(),
    );
  }

  void _showTemperatureDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const TemperatureDialog(),
    );
  }
}

// Dialog widgets will be implemented next
class AddPeriodDialog extends StatefulWidget {
  const AddPeriodDialog({super.key});

  @override
  State<AddPeriodDialog> createState() => _AddPeriodDialogState();
}

class _AddPeriodDialogState extends State<AddPeriodDialog> {
  DateTime _startDate = DateTime.now();
  DateTime? _endDate;
  int _flow = 3;
  final List<String> _symptoms = [];
  String _notes = '';

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Log Period'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Start Date'),
              subtitle: Text(DateFormat('MMM dd, yyyy').format(_startDate)),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _startDate,
                  firstDate: DateTime.now().subtract(const Duration(days: 365)),
                  lastDate: DateTime.now(),
                );
                if (date != null) {
                  setState(() {
                    _startDate = date;
                  });
                }
              },
            ),
            ListTile(
              title: const Text('End Date (Optional)'),
              subtitle: Text(
                _endDate != null
                    ? DateFormat('MMM dd, yyyy').format(_endDate!)
                    : 'Not set',
              ),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate:
                      _endDate ?? _startDate.add(const Duration(days: 5)),
                  firstDate: _startDate,
                  lastDate: DateTime.now(),
                );
                if (date != null) {
                  setState(() {
                    _endDate = date;
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            Text('Flow: ${_getFlowTextForDialog(_flow)}'),
            Slider(
              value: _flow.toDouble(),
              min: 1,
              max: 5,
              divisions: 4,
              onChanged: (value) {
                setState(() {
                  _flow = value.round();
                });
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            final appProvider = Provider.of<AppProvider>(
              context,
              listen: false,
            );
            await appProvider.addPeriod(
              startDate: _startDate,
              endDate: _endDate,
              flow: _flow,
              symptoms: _symptoms,
              notes: _notes.isNotEmpty ? _notes : null,
            );
            if (mounted) {
              Navigator.of(context).pop();
            }
          },
          child: const Text('Save'),
        ),
      ],
    );
  }

  String _getFlowTextForDialog(int flow) {
    switch (flow) {
      case 1:
        return 'Light';
      case 2:
        return 'Light-Medium';
      case 3:
        return 'Medium';
      case 4:
        return 'Heavy';
      case 5:
        return 'Very Heavy';
      default:
        return 'Medium';
    }
  }
}

// Placeholder dialogs - will be implemented later
class AddSymptomsDialog extends StatelessWidget {
  const AddSymptomsDialog();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Symptoms'),
      content: const Text('Symptom tracking dialog will be implemented here.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

class MoodTrackingDialog extends StatelessWidget {
  const MoodTrackingDialog();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Track Mood'),
      content: const Text('Mood tracking dialog will be implemented here.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

class TemperatureDialog extends StatelessWidget {
  const TemperatureDialog();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Log Temperature'),
      content: const Text(
        'Temperature tracking dialog will be implemented here.',
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
