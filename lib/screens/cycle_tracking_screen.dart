import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/period.dart';
import '../models/symptom.dart';
import '../providers/app_provider.dart';
import '../services/admob_service.dart';
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
                const SizedBox(height: 16),
                _buildTodaysMoodCard(appProvider),
                const SizedBox(height: 16),
                _buildTodaysTemperatureCard(appProvider),
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

      final daysUntilNext = nextPeriod?.difference(DateTime.now()).inDays;

      cachedData = {'nextPeriod': nextPeriod, 'daysUntilNext': daysUntilNext};

      _performanceService.cacheData(cacheKey, cachedData);
      _performanceService.endOperation('cycle_prediction_calculation');
    }

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
                    color: Theme.of(context).iconTheme.color,
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
                        : Theme.of(context).iconTheme.color ?? Colors.grey,
                  ),
                ),
                Expanded(
                  child: _buildOverviewItem(
                    'Cycle Length',
                    '${user.averageCycleLength} days',
                    Icons.refresh,
                    Theme.of(context).iconTheme.color ?? Colors.grey,
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
                    Theme.of(context).iconTheme.color ?? Colors.grey,
                  ),
                ),
                Expanded(
                  child: _buildOverviewItem(
                    'Total Cycles',
                    '${periods.length}',
                    Icons.analytics,
                    Theme.of(context).iconTheme.color ?? Colors.grey,
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
        Icon(icon, color: color, size: 24,),
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
              Icon(Icons.insights, size: 48, color: Theme.of(context).iconTheme.color?.withOpacity(0.4)),
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
                Icon(Icons.insights, color: Theme.of(context).iconTheme.color),
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
            ...[
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
    final List<String> displayItems = [];
    
    // Add physical and emotional symptoms
    displayItems.addAll(symptom.physicalSymptoms);
    displayItems.addAll(symptom.emotionalSymptoms);
    
    // Add mood if present
    if (symptom.mood != null) {
      displayItems.add('Mood: ${symptom.mood}');
    }
    
    // Add temperature if present
    if (symptom.basalTemperature != null) {
      displayItems.add('Temperature: ${symptom.basalTemperature!.toStringAsFixed(1)}°C');
    }
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
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
            if (displayItems.isNotEmpty)
              Text(
                displayItems.join(', '),
                style: const TextStyle(fontSize: 14),
              ),
            if (symptom.energyLevel != null || symptom.painLevel != null || symptom.notes != null) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
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
                  if (symptom.energyLevel != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Energy: ${symptom.energyLevel}/10',
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.blue,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ],
            if (symptom.notes != null && symptom.notes!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Notes: ${symptom.notes}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
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

  Widget _buildTodaysMoodCard(AppProvider appProvider) {
    final today = DateTime.now();
    final todaysSymptoms = appProvider.symptoms
        .where((s) => DateUtils.isSameDay(s.date, today))
        .toList();

    final moodData = todaysSymptoms
        .where((s) => s.mood != null || s.energyLevel != null)
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
                  'Today\'s Mood',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () => _showMoodTrackingDialog(context),
                  child: const Text('Track'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (moodData.isEmpty)
              Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.mood_outlined,
                      size: 48,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No mood logged today',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              )
            else
              ...moodData.map((symptom) => _buildMoodItem(symptom)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildMoodItem(Symptom symptom) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.purple.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.purple.shade200),
        ),
        child: Row(
          children: [
            Icon(Icons.mood, color: Colors.purple.shade600),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (symptom.mood != null)
                    Text(
                      'Mood: ${symptom.mood}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  if (symptom.energyLevel != null)
                    Text(
                      'Energy Level: ${symptom.energyLevel}/10',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodaysTemperatureCard(AppProvider appProvider) {
    final today = DateTime.now();
    final todaysSymptoms = appProvider.symptoms
        .where((s) => DateUtils.isSameDay(s.date, today))
        .toList();

    final temperatureData = todaysSymptoms
        .where((s) => s.basalTemperature != null)
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
                  'Today\'s Temperature',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () => _showTemperatureDialog(context),
                  child: const Text('Log'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (temperatureData.isEmpty)
              Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.thermostat_outlined,
                      size: 48,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No temperature logged today',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              )
            else
              ...temperatureData.map((symptom) => _buildTemperatureItem(symptom)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildTemperatureItem(Symptom symptom) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.blue.shade200),
        ),
        child: Row(
          children: [
            Icon(Icons.thermostat, color: Colors.blue.shade600),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Basal Body Temperature: ${symptom.basalTemperature!.toStringAsFixed(1)}°C',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
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
                final now = DateTime.now();
                final suggestedEndDate = _startDate.add(const Duration(days: 5));
                final initialDate = _endDate ?? 
                    (suggestedEndDate.isAfter(now) ? now : suggestedEndDate);
                
                final date = await showDatePicker(
                  context: context,
                  initialDate: initialDate,
                  firstDate: _startDate,
                  lastDate: now,
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
              // Show interstitial ad after saving period data
              AdMobService().showInterstitialAd();
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

// Symptom tracking dialogs
class AddSymptomsDialog extends StatefulWidget {
  const AddSymptomsDialog({Key? key}) : super(key: key);

  @override
  State<AddSymptomsDialog> createState() => _AddSymptomsDialogState();
}

class _AddSymptomsDialogState extends State<AddSymptomsDialog> {
  final Set<String> _selectedSymptoms = {};
  final TextEditingController _notesController = TextEditingController();

  final List<Map<String, dynamic>> _symptoms = [
    {'name': 'Cramps', 'icon': Icons.healing, 'color': Colors.red},
    {'name': 'Headache', 'icon': Icons.psychology, 'color': Colors.orange},
    {'name': 'Bloating', 'icon': Icons.expand_circle_down, 'color': Colors.blue},
    {'name': 'Breast Tenderness', 'icon': Icons.favorite, 'color': Colors.pink},
    {'name': 'Fatigue', 'icon': Icons.battery_0_bar, 'color': Colors.grey},
    {'name': 'Nausea', 'icon': Icons.sick, 'color': Colors.green},
    {'name': 'Back Pain', 'icon': Icons.accessibility_new, 'color': Colors.brown},
    {'name': 'Acne', 'icon': Icons.face, 'color': Colors.purple},
    {'name': 'Food Cravings', 'icon': Icons.restaurant, 'color': Colors.amber},
    {'name': 'Mood Swings', 'icon': Icons.mood, 'color': Colors.indigo},
  ];

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Track Symptoms'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select symptoms you\'re experiencing:',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            Flexible(
              child: SingleChildScrollView(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _symptoms.map((symptom) {
                    final isSelected = _selectedSymptoms.contains(symptom['name']);
                    return FilterChip(
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedSymptoms.add(symptom['name']);
                          } else {
                            _selectedSymptoms.remove(symptom['name']);
                          }
                        });
                      },
                      avatar: Icon(
                        symptom['icon'],
                        size: 18,
                        color: isSelected ? Colors.white : symptom['color'],
                      ),
                      label: Text(symptom['name']),
                      backgroundColor: symptom['color'].withOpacity(0.1),
                      selectedColor: symptom['color'],
                      checkmarkColor: Colors.white,
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                hintText: 'Add any additional details...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
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
          onPressed: _selectedSymptoms.isEmpty ? null : () async {
            final appProvider = Provider.of<AppProvider>(context, listen: false);
            
            try {
              // Save symptoms data to AppProvider
               await appProvider.addOrUpdateSymptom(
                 date: DateTime.now(),
                 physicalSymptoms: _selectedSymptoms.toList(),
                 notes: _notesController.text.isNotEmpty ? _notesController.text : null,
               );
              
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Logged ${_selectedSymptoms.length} symptom(s)'),
                    backgroundColor: Colors.green,
                  ),
                );
                Navigator.of(context).pop();
                // Show interstitial ad after saving symptoms data
                AdMobService().showInterstitialAd();
              }
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error saving symptoms: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class MoodTrackingDialog extends StatefulWidget {
  const MoodTrackingDialog({Key? key}) : super(key: key);

  @override
  State<MoodTrackingDialog> createState() => _MoodTrackingDialogState();
}

class _MoodTrackingDialogState extends State<MoodTrackingDialog> {
  String? _selectedMood;
  int _energyLevel = 5;
  final TextEditingController _notesController = TextEditingController();

  final List<Map<String, dynamic>> _moods = [
    {'name': 'Happy', 'icon': '😊', 'color': Colors.yellow},
    {'name': 'Sad', 'icon': '😢', 'color': Colors.blue},
    {'name': 'Anxious', 'icon': '😰', 'color': Colors.orange},
    {'name': 'Angry', 'icon': '😠', 'color': Colors.red},
    {'name': 'Calm', 'icon': '😌', 'color': Colors.green},
    {'name': 'Excited', 'icon': '🤩', 'color': Colors.purple},
    {'name': 'Tired', 'icon': '😴', 'color': Colors.grey},
    {'name': 'Stressed', 'icon': '😫', 'color': Colors.deepOrange},
  ];

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Track Mood'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'How are you feeling today?',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _moods.map((mood) {
                        final isSelected = _selectedMood == mood['name'];
                        return ChoiceChip(
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              _selectedMood = selected ? mood['name'] : null;
                            });
                          },
                          avatar: Text(
                            mood['icon'],
                            style: const TextStyle(fontSize: 16),
                          ),
                          label: Text(mood['name']),
                          backgroundColor: mood['color'].withOpacity(0.1),
                          selectedColor: mood['color'].withOpacity(0.3),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Energy Level',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Text('Low'),
                        Expanded(
                          child: Slider(
                            value: _energyLevel.toDouble(),
                            min: 1,
                            max: 10,
                            divisions: 9,
                            label: _energyLevel.toString(),
                            onChanged: (value) {
                              setState(() {
                                _energyLevel = value.round();
                              });
                            },
                          ),
                        ),
                        const Text('High'),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _notesController,
                      decoration: const InputDecoration(
                        labelText: 'Notes (optional)',
                        hintText: 'How are you feeling? Any thoughts?',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
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
          onPressed: _selectedMood == null ? null : () async {
            final appProvider = Provider.of<AppProvider>(context, listen: false);
            
            try {
              // Save mood and energy data to AppProvider
              await appProvider.addOrUpdateSymptom(
                date: DateTime.now(),
                mood: _selectedMood,
                energyLevel: _energyLevel,
                notes: _notesController.text.isNotEmpty ? _notesController.text : null,
              );
              
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Mood logged: $_selectedMood (Energy: $_energyLevel/10)'),
                    backgroundColor: Colors.green,
                  ),
                );
                Navigator.of(context).pop();
                // Show interstitial ad after saving mood data
                AdMobService().showInterstitialAd();
              }
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error saving mood data: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class TemperatureDialog extends StatefulWidget {
  const TemperatureDialog({Key? key}) : super(key: key);

  @override
  State<TemperatureDialog> createState() => _TemperatureDialogState();
}

class _TemperatureDialogState extends State<TemperatureDialog> {
  final TextEditingController _temperatureController = TextEditingController();
  bool _isCelsius = true;
  TimeOfDay _selectedTime = TimeOfDay.now();
  final TextEditingController _notesController = TextEditingController();
  String? _errorText;

  @override
  void dispose() {
    _temperatureController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _validateTemperature(String value) {
    setState(() {
      if (value.isEmpty) {
        _errorText = 'Please enter a temperature';
        return;
      }

      final temp = double.tryParse(value);
      if (temp == null) {
        _errorText = 'Please enter a valid number';
        return;
      }

      if (_isCelsius) {
        if (temp < 35.0 || temp > 42.0) {
          _errorText = 'Temperature should be between 35°C and 42°C';
          return;
        }
      } else {
        if (temp < 95.0 || temp > 107.6) {
          _errorText = 'Temperature should be between 95°F and 107.6°F';
          return;
        }
      }

      _errorText = null;
    });
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Log Temperature'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Basal Body Temperature',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const Text(
              'Best measured first thing in the morning before getting out of bed.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _temperatureController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Temperature',
                      suffixText: _isCelsius ? '°C' : '°F',
                      border: const OutlineInputBorder(),
                      errorText: _errorText,
                    ),
                    onChanged: _validateTemperature,
                  ),
                ),
                const SizedBox(width: 12),
                SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(value: true, label: Text('°C')),
                    ButtonSegment(value: false, label: Text('°F')),
                  ],
                  selected: {_isCelsius},
                  onSelectionChanged: (Set<bool> selection) {
                    setState(() {
                      _isCelsius = selection.first;
                      _validateTemperature(_temperatureController.text);
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.access_time, size: 20),
                const SizedBox(width: 8),
                const Text('Time taken:'),
                const Spacer(),
                TextButton(
                  onPressed: _selectTime,
                  child: Text(_selectedTime.format(context)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                hintText: 'Sleep quality, illness, etc.',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
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
          onPressed: _errorText != null || _temperatureController.text.isEmpty ? null : () async {
            final appProvider = Provider.of<AppProvider>(context, listen: false);
            final temp = double.parse(_temperatureController.text);
            final unit = _isCelsius ? '°C' : '°F';
            
            try {
              // Convert Fahrenheit to Celsius for storage if needed
              final tempInCelsius = _isCelsius ? temp : (temp - 32) * 5 / 9;
              
              // Save temperature data to AppProvider
              await appProvider.addOrUpdateSymptom(
                date: DateTime.now(),
                basalTemperature: tempInCelsius,
                notes: _notesController.text.isNotEmpty ? _notesController.text : null,
              );
              
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Temperature logged: $temp$unit at ${_selectedTime.format(context)}'),
                    backgroundColor: Colors.green,
                  ),
                );
                Navigator.of(context).pop();
              }
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error saving temperature: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
