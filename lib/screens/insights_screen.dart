import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'dart:math';
import '../providers/app_provider.dart';
import '../models/period.dart';
import '../models/symptom.dart';
import '../services/prediction_service.dart';

class InsightsScreen extends StatefulWidget {
  const InsightsScreen({super.key});

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _selectedTabIndex = _tabController.index;
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Insights'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Trends'),
            Tab(text: 'Health'),
          ],
        ),
      ),
      body: Consumer<AppProvider>(
        builder: (context, appProvider, child) {
          if (appProvider.periods.isEmpty) {
            return _buildEmptyState();
          }

          switch (_selectedTabIndex) {
            case 0:
              return _buildOverviewTab(appProvider);
            case 1:
              return _buildTrendsTab(appProvider);
            case 2:
              return _buildHealthTab(appProvider);
            default:
              return _buildOverviewTab(appProvider);
          }
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.insights,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 24),
          Text(
            'No Data Yet',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Log your periods to see insights\nand track your cycle patterns',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab(AppProvider appProvider) {
    final periods = appProvider.periods;
    final user = appProvider.user!;
    
    final avgCycleLength = PredictionService.calculateAverageCycleLength(periods);
    final avgPeriodLength = PredictionService.calculateAveragePeriodLength(periods);
    final cycleVariability = _calculateCycleVariability(periods);
    final lastPeriod = periods.isNotEmpty ? periods.first : null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatsGrid(appProvider),
          const SizedBox(height: 24),
          _buildCycleLengthChart(periods),
          const SizedBox(height: 24),
          _buildPeriodLengthChart(periods),
          const SizedBox(height: 24),
          _buildInsightsCard(appProvider),
        ],
      ),
    );
  }

  Widget _buildTrendsTab(AppProvider appProvider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFlowTrendsChart(appProvider.periods),
          const SizedBox(height: 24),
          _buildSymptomTrendsChart(appProvider.symptoms),
          const SizedBox(height: 24),
          _buildCycleRegularityChart(appProvider.periods),
        ],
      ),
    );
  }

  Widget _buildHealthTab(AppProvider appProvider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHealthScoreCard(appProvider),
          const SizedBox(height: 24),
          _buildSymptomFrequencyChart(appProvider.symptoms),
          const SizedBox(height: 24),
          _buildHealthRecommendations(appProvider),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(AppProvider appProvider) {
    final periods = appProvider.periods;
    final avgCycleLength = periods.length > 1 
        ? PredictionService.calculateAverageCycleLength(periods)
        : appProvider.user!.averageCycleLength.toDouble();
    final avgPeriodLength = PredictionService.calculateAveragePeriodLength(periods);
    final cycleVariability = _calculateCycleVariability(periods);

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.5,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      children: [
        _buildStatCard(
          'Avg Cycle Length',
          '${avgCycleLength.round()} days',
          Icons.refresh,
          Colors.blue,
        ),
        _buildStatCard(
          'Avg Period Length',
          '${avgPeriodLength.round()} days',
          Icons.water_drop,
          Colors.pink,
        ),
        _buildStatCard(
          'Cycle Variability',
          '±${cycleVariability.round()} days',
          Icons.trending_up,
          cycleVariability <= 3 ? Colors.green : Colors.orange,
        ),
        _buildStatCard(
          'Total Cycles',
          '${periods.length}',
          Icons.analytics,
          Colors.purple,
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCycleLengthChart(List<Period> periods) {
    if (periods.length < 2) {
      return _buildChartPlaceholder('Cycle Length Trends', 'Need more cycles for trends');
    }

    final cycleLengths = <FlSpot>[];
    for (int i = 0; i < periods.length - 1; i++) {
      final cycleLength = periods[i].startDate.difference(periods[i + 1].startDate).inDays;
      cycleLengths.add(FlSpot(i.toDouble(), cycleLength.toDouble()));
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Cycle Length Trends',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: true),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text('${value.toInt()}d');
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          return Text('${value.toInt() + 1}');
                        },
                      ),
                    ),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    LineChartBarData(
                      spots: cycleLengths,
                      isCurved: true,
                      color: Colors.blue,
                      barWidth: 3,
                      dotData: const FlDotData(show: true),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodLengthChart(List<Period> periods) {
    final completedPeriods = periods.where((p) => p.endDate != null).toList();
    
    if (completedPeriods.isEmpty) {
      return _buildChartPlaceholder('Period Length Trends', 'No completed periods yet');
    }

    final periodLengths = <FlSpot>[];
    for (int i = 0; i < completedPeriods.length; i++) {
      periodLengths.add(FlSpot(i.toDouble(), completedPeriods[i].length.toDouble()));
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Period Length Trends',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: true),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text('${value.toInt()}d');
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          return Text('${value.toInt() + 1}');
                        },
                      ),
                    ),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    LineChartBarData(
                      spots: periodLengths,
                      isCurved: true,
                      color: Colors.pink,
                      barWidth: 3,
                      dotData: const FlDotData(show: true),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFlowTrendsChart(List<Period> periods) {
    if (periods.isEmpty) {
      return _buildChartPlaceholder('Flow Trends', 'No period data yet');
    }

    final flowData = <String, int>{};
    for (final period in periods) {
      final flowText = _getFlowText(period.flow);
      flowData[flowText] = (flowData[flowText] ?? 0) + 1;
    }

    final sections = flowData.entries.map((entry) {
      final color = _getFlowColor(_getFlowValue(entry.key));
      return PieChartSectionData(
        color: color,
        value: entry.value.toDouble(),
        title: '${entry.value}',
        radius: 60,
        titleStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Flow Distribution',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: Row(
                children: [
                  Expanded(
                    child: PieChart(
                      PieChartData(
                        sections: sections,
                        centerSpaceRadius: 40,
                        sectionsSpace: 2,
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: flowData.entries.map((entry) {
                      final color = _getFlowColor(_getFlowValue(entry.key));
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Container(
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(entry.key),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSymptomTrendsChart(List<Symptom> symptoms) {
    if (symptoms.isEmpty) {
      return _buildChartPlaceholder('Symptom Trends', 'No symptoms logged yet');
    }

    final symptomCounts = <String, int>{};
    for (final symptom in symptoms) {
      for (final physical in symptom.physicalSymptoms) {
        symptomCounts[physical] = (symptomCounts[physical] ?? 0) + 1;
      }
      for (final emotional in symptom.emotionalSymptoms) {
        symptomCounts[emotional] = (symptomCounts[emotional] ?? 0) + 1;
      }
    }

    final topSymptoms = symptomCounts.entries
        .toList()
        ..sort((a, b) => b.value.compareTo(a.value));
    
    final chartData = topSymptoms.take(5).map((entry) {
      return BarChartGroupData(
        x: topSymptoms.indexOf(entry),
        barRods: [
          BarChartRodData(
            toY: entry.value.toDouble(),
            color: Colors.purple,
            width: 20,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      );
    }).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Most Common Symptoms',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: topSymptoms.isNotEmpty ? topSymptoms.first.value.toDouble() + 2 : 10,
                  barGroups: chartData,
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text('${value.toInt()}');
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() < topSymptoms.length) {
                            final symptom = topSymptoms[value.toInt()].key;
                            return Text(
                              symptom.length > 8 ? '${symptom.substring(0, 8)}...' : symptom,
                              style: const TextStyle(fontSize: 10),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  gridData: const FlGridData(show: false),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCycleRegularityChart(List<Period> periods) {
    if (periods.length < 3) {
      return _buildChartPlaceholder('Cycle Regularity', 'Need more cycles for analysis');
    }

    final variability = _calculateCycleVariability(periods);
    final regularityScore = _calculateRegularityScore(variability);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Cycle Regularity',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: SizedBox(
                width: 150,
                height: 150,
                child: CircularProgressIndicator(
                  value: regularityScore / 100,
                  strokeWidth: 12,
                  backgroundColor: Colors.grey.shade300,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _getRegularityColor(regularityScore),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: Column(
                children: [
                  Text(
                    '${regularityScore.round()}%',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: _getRegularityColor(regularityScore),
                    ),
                  ),
                  Text(
                    _getRegularityText(regularityScore),
                    style: TextStyle(
                      fontSize: 16,
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

  Widget _buildHealthScoreCard(AppProvider appProvider) {
    final healthScore = _calculateHealthScore(appProvider);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Health Score',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      SizedBox(
                        width: 100,
                        height: 100,
                        child: CircularProgressIndicator(
                          value: healthScore / 100,
                          strokeWidth: 8,
                          backgroundColor: Colors.grey.shade300,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            _getHealthScoreColor(healthScore),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '${healthScore.round()}%',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: _getHealthScoreColor(healthScore),
                        ),
                      ),
                      Text(
                        _getHealthScoreText(healthScore),
                        style: TextStyle(
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHealthMetric('Cycle Regularity', _calculateRegularityScore(_calculateCycleVariability(appProvider.periods))),
                      const SizedBox(height: 8),
                      _buildHealthMetric('Symptom Severity', _calculateSymptomSeverity(appProvider.symptoms)),
                      const SizedBox(height: 8),
                      _buildHealthMetric('Data Consistency', _calculateDataConsistency(appProvider)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthMetric(String label, double score) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 12),
          ),
        ),
        Container(
          width: 60,
          height: 8,
          decoration: BoxDecoration(
            color: Colors.grey.shade300,
            borderRadius: BorderRadius.circular(4),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: score / 100,
            child: Container(
              decoration: BoxDecoration(
                color: _getHealthScoreColor(score),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSymptomFrequencyChart(List<Symptom> symptoms) {
    if (symptoms.isEmpty) {
      return _buildChartPlaceholder('Symptom Frequency', 'No symptoms logged yet');
    }

    final last30Days = DateTime.now().subtract(const Duration(days: 30));
    final recentSymptoms = symptoms.where((s) => s.date.isAfter(last30Days)).toList();
    
    final frequencyData = <String, int>{};
    for (final symptom in recentSymptoms) {
      final week = 'Week ${((DateTime.now().difference(symptom.date).inDays) / 7).floor() + 1}';
      frequencyData[week] = (frequencyData[week] ?? 0) + 1;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Symptom Frequency (Last 30 Days)',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            if (frequencyData.isEmpty)
              const Center(
                child: Text('No symptoms in the last 30 days'),
              )
            else
              ...frequencyData.entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 60,
                        child: Text(entry.key),
                      ),
                      Expanded(
                        child: Container(
                          height: 20,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: entry.value / (frequencyData.values.reduce((a, b) => a > b ? a : b)),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.purple,
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('${entry.value}'),
                    ],
                  ),
                );
              }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthRecommendations(AppProvider appProvider) {
    final recommendations = _generateHealthRecommendations(appProvider);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Health Recommendations',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...recommendations.map((rec) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      rec['icon'] as IconData,
                      color: rec['color'] as Color,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            rec['title'] as String,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            rec['description'] as String,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightsCard(AppProvider appProvider) {
    final insights = PredictionService.generateInsights(appProvider.periods, appProvider.user!);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.lightbulb,
                  color: Colors.amber,
                ),
                const SizedBox(width: 8),
                Text(
                  'AI Insights',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...insights.map((insight) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.circle,
                      size: 8,
                      color: Theme.of(context).primaryColor,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        insight,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildChartPlaceholder(String title, String message) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 40),
            Center(
              child: Column(
                children: [
                  Icon(
                    Icons.bar_chart,
                    size: 48,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    message,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // Helper methods
  double _calculateCycleVariability(List<Period> periods) {
    if (periods.length < 2) return 0;
    
    final cycleLengths = <int>[];
    for (int i = 0; i < periods.length - 1; i++) {
      cycleLengths.add(periods[i].startDate.difference(periods[i + 1].startDate).inDays);
    }
    
    final mean = cycleLengths.reduce((a, b) => a + b) / cycleLengths.length;
    final variance = cycleLengths.map((x) => (x - mean) * (x - mean)).reduce((a, b) => a + b) / cycleLengths.length;
    return sqrt(variance);
  }

  double _calculateRegularityScore(double variability) {
    if (variability <= 2) return 100;
    if (variability <= 4) return 80;
    if (variability <= 6) return 60;
    if (variability <= 8) return 40;
    return 20;
  }

  double _calculateHealthScore(AppProvider appProvider) {
    final regularityScore = _calculateRegularityScore(_calculateCycleVariability(appProvider.periods));
    final symptomScore = _calculateSymptomSeverity(appProvider.symptoms);
    final consistencyScore = _calculateDataConsistency(appProvider);
    
    return (regularityScore + symptomScore + consistencyScore) / 3;
  }

  double _calculateSymptomSeverity(List<Symptom> symptoms) {
    if (symptoms.isEmpty) return 100;
    
    final avgPainLevel = symptoms
        .where((s) => s.painLevel != null)
        .map((s) => s.painLevel!)
        .fold(0, (a, b) => a + b) / symptoms.length;
    
    return 100 - (avgPainLevel * 10);
  }

  double _calculateDataConsistency(AppProvider appProvider) {
    final totalDays = 30;
    final loggedDays = appProvider.symptoms
        .where((s) => s.date.isAfter(DateTime.now().subtract(Duration(days: totalDays))))
        .length;
    
    return (loggedDays / totalDays) * 100;
  }

  List<Map<String, dynamic>> _generateHealthRecommendations(AppProvider appProvider) {
    final recommendations = <Map<String, dynamic>>[];
    
    final variability = _calculateCycleVariability(appProvider.periods);
    if (variability > 6) {
      recommendations.add({
        'icon': Icons.warning,
        'color': Colors.orange,
        'title': 'Irregular Cycles',
        'description': 'Consider tracking stress levels and lifestyle factors',
      });
    }
    
    final avgPainLevel = appProvider.symptoms
        .where((s) => s.painLevel != null)
        .map((s) => s.painLevel!)
        .fold(0.0, (a, b) => a + b) / appProvider.symptoms.length;
    
    if (avgPainLevel > 7) {
      recommendations.add({
        'icon': Icons.healing,
        'color': Colors.red,
        'title': 'High Pain Levels',
        'description': 'Consider consulting with a healthcare provider',
      });
    }
    
    recommendations.add({
      'icon': Icons.fitness_center,
      'color': Colors.green,
      'title': 'Stay Active',
      'description': 'Regular exercise can help reduce period symptoms',
    });
    
    recommendations.add({
      'icon': Icons.local_drink,
      'color': Colors.blue,
      'title': 'Stay Hydrated',
      'description': 'Drink plenty of water throughout your cycle',
    });
    
    return recommendations;
  }

  Color _getFlowColor(int flow) {
    switch (flow) {
      case 1: return Colors.pink.shade200;
      case 2: return Colors.pink.shade400;
      case 3: return Colors.pink.shade600;
      case 4: return Colors.red.shade600;
      case 5: return Colors.red.shade800;
      default: return Colors.pink;
    }
  }

  String _getFlowText(int flow) {
    switch (flow) {
      case 1: return 'Light';
      case 2: return 'Light-Medium';
      case 3: return 'Medium';
      case 4: return 'Heavy';
      case 5: return 'Very Heavy';
      default: return 'Medium';
    }
  }

  int _getFlowValue(String flowText) {
    switch (flowText) {
      case 'Light': return 1;
      case 'Light-Medium': return 2;
      case 'Medium': return 3;
      case 'Heavy': return 4;
      case 'Very Heavy': return 5;
      default: return 3;
    }
  }

  Color _getRegularityColor(double score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.orange;
    return Colors.red;
  }

  String _getRegularityText(double score) {
    if (score >= 80) return 'Very Regular';
    if (score >= 60) return 'Somewhat Regular';
    return 'Irregular';
  }

  Color _getHealthScoreColor(double score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.orange;
    return Colors.red;
  }

  String _getHealthScoreText(double score) {
    if (score >= 80) return 'Excellent';
    if (score >= 60) return 'Good';
    return 'Needs Attention';
  }
}