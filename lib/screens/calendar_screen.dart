import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../providers/app_provider.dart';
import '../models/period.dart';
import '../models/symptom.dart';
import '../services/prediction_service.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late final ValueNotifier<List<CalendarEvent>> _selectedEvents;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
    _selectedEvents = ValueNotifier(_getEventsForDay(_selectedDay!));
  }

  @override
  void dispose() {
    _selectedEvents.dispose();
    super.dispose();
  }

  List<CalendarEvent> _getEventsForDay(DateTime day) {
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    final events = <CalendarEvent>[];

    // Check for periods
    for (final period in appProvider.periods) {
      if (_isDateInPeriod(day, period)) {
        events.add(
          CalendarEvent(
            title: 'Period Day ${_getPeriodDay(day, period)}',
            type: CalendarEventType.period,
            flow: period.flow,
          ),
        );
      }
    }

    // Check for symptoms
    final daySymptoms = appProvider.symptoms
        .where((s) => DateUtils.isSameDay(s.date, day))
        .toList();

    for (final symptom in daySymptoms) {
      events.add(
        CalendarEvent(
          title: 'Symptoms logged',
          type: CalendarEventType.symptom,
          symptom: symptom,
        ),
      );
    }

    // Check for predictions
    if (appProvider.user != null && appProvider.periods.isNotEmpty) {
      final user = appProvider.user!;
      final periods = appProvider.periods;

      final nextPeriod = PredictionService.predictNextPeriod(periods, user);
      final nextOvulation = PredictionService.predictOvulation(periods, user);
      final fertilityWindow = PredictionService.calculateFertilityWindow(
        periods,
        user,
      );

      if (nextPeriod != null && DateUtils.isSameDay(day, nextPeriod)) {
        events.add(
          CalendarEvent(
            title: 'Predicted Period Start',
            type: CalendarEventType.predictedPeriod,
          ),
        );
      }

      if (nextOvulation != null && DateUtils.isSameDay(day, nextOvulation)) {
        events.add(
          CalendarEvent(
            title: 'Predicted Ovulation',
            type: CalendarEventType.ovulation,
          ),
        );
      }

      if (fertilityWindow != null) {
        final start = fertilityWindow['start']!;
        final end = fertilityWindow['end']!;
        if (day.isAfter(start.subtract(const Duration(days: 1))) &&
            day.isBefore(end.add(const Duration(days: 1)))) {
          events.add(
            CalendarEvent(
              title: 'Fertility Window',
              type: CalendarEventType.fertility,
            ),
          );
        }
      }
    }

    return events;
  }

  bool _isDateInPeriod(DateTime date, Period period) {
    if (period.endDate == null) {
      return DateUtils.isSameDay(date, period.startDate);
    }
    return date.isAfter(period.startDate.subtract(const Duration(days: 1))) &&
        date.isBefore(period.endDate!.add(const Duration(days: 1)));
  }

  int _getPeriodDay(DateTime date, Period period) {
    return date.difference(period.startDate).inDays + 1;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendar'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.today),
            onPressed: () {
              setState(() {
                _focusedDay = DateTime.now();
                _selectedDay = DateTime.now();
                _selectedEvents.value = _getEventsForDay(_selectedDay!);
              });
            },
          ),
        ],
      ),
      body: Consumer<AppProvider>(
        builder: (context, appProvider, child) {
          return SingleChildScrollView(
            child: Column(
              children: [
                _buildLegend(),
                const SizedBox(height: 8),
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.4,
                  child: TableCalendar<CalendarEvent>(
                    firstDay: DateTime.utc(2020, 1, 1),
                    lastDay: DateTime.utc(2030, 12, 31),
                    focusedDay: _focusedDay,
                    calendarFormat: _calendarFormat,
                    eventLoader: _getEventsForDay,
                    startingDayOfWeek: StartingDayOfWeek.monday,
                    availableGestures: AvailableGestures.all,
                    calendarStyle: CalendarStyle(
                      outsideDaysVisible: false,
                      weekendTextStyle: TextStyle(color: Colors.red.shade600),
                      holidayTextStyle: TextStyle(color: Colors.red.shade600),
                      selectedDecoration: BoxDecoration(
                        color: Theme.of(context).primaryColor,
                        shape: BoxShape.circle,
                      ),
                      todayDecoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withOpacity(0.5),
                        shape: BoxShape.circle,
                      ),
                      markerDecoration: BoxDecoration(
                        color: Colors.pink.shade300,
                        shape: BoxShape.circle,
                      ),
                    ),
                    onDaySelected: (selectedDay, focusedDay) {
                      if (!isSameDay(_selectedDay, selectedDay)) {
                        setState(() {
                          _selectedDay = selectedDay;
                          _focusedDay = focusedDay;
                          _selectedEvents.value = _getEventsForDay(selectedDay);
                        });
                      }
                    },
                    onFormatChanged: (format) {
                      if (_calendarFormat != format) {
                        setState(() {
                          _calendarFormat = format;
                        });
                      }
                    },
                    onPageChanged: (focusedDay) {
                      _focusedDay = focusedDay;
                    },
                    calendarBuilders: CalendarBuilders(
                      markerBuilder: (context, day, events) {
                        if (events.isEmpty) return null;

                        return Positioned(
                          bottom: 1,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: events.take(3).map((event) {
                              return Container(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 1,
                                ),
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: _getEventColor(event),
                                  shape: BoxShape.circle,
                                ),
                              );
                            }).toList(),
                          ),
                        );
                      },
                      defaultBuilder: (context, day, focusedDay) {
                        final events = _getEventsForDay(day);
                        final periodEvent = events.firstWhere(
                          (e) => e.type == CalendarEventType.period,
                          orElse: () => CalendarEvent(
                            title: '',
                            type: CalendarEventType.period,
                          ),
                        );

                        if (periodEvent.title.isNotEmpty) {
                          return Container(
                            margin: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: _getFlowColor(
                                periodEvent.flow ?? 3,
                              ).withOpacity(0.3),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: _getFlowColor(periodEvent.flow ?? 3),
                                width: 2,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                '${day.day}',
                                style: TextStyle(
                                  color: _getFlowColor(periodEvent.flow ?? 3),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          );
                        }

                        final fertilityEvent = events.firstWhere(
                          (e) => e.type == CalendarEventType.fertility,
                          orElse: () => CalendarEvent(
                            title: '',
                            type: CalendarEventType.fertility,
                          ),
                        );

                        if (fertilityEvent.title.isNotEmpty) {
                          return Container(
                            margin: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.2),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.green, width: 1),
                            ),
                            child: Center(
                              child: Text(
                                '${day.day}',
                                style: const TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          );
                        }

                        final ovulationEvent = events.firstWhere(
                          (e) => e.type == CalendarEventType.ovulation,
                          orElse: () => CalendarEvent(
                            title: '',
                            type: CalendarEventType.ovulation,
                          ),
                        );

                        if (ovulationEvent.title.isNotEmpty) {
                          return Container(
                            margin: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.3),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.orange,
                                width: 2,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                '${day.day}',
                                style: const TextStyle(
                                  color: Colors.orange,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          );
                        }

                        return null;
                      },
                    ),
                  ),
                ),
                ValueListenableBuilder<List<CalendarEvent>>(
                  valueListenable: _selectedEvents,
                  builder: (context, value, _) {
                    return _buildEventsList(value);
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildLegend() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Legend',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              _buildLegendItem('Period', Colors.pink, Icons.water_drop),
              _buildLegendItem('Fertility', Colors.green, Icons.favorite),
              _buildLegendItem('Ovulation', Colors.orange, Icons.egg),
              _buildLegendItem('Symptoms', Colors.purple, Icons.healing),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color, IconData icon) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildEventsList(List<CalendarEvent> events) {
    if (events.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_note,
              size: 48,
              color: Theme.of(context).iconTheme.color?.withOpacity(0.4),
            ),
            const SizedBox(height: 12),
            Text(
              'No events for ${DateFormat('MMM dd, yyyy').format(_selectedDay!)}',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: events.length,
      itemBuilder: (context, index) {
        final event = events[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _getEventColor(event).withOpacity(0.2),
              child: Icon(
                _getEventIcon(event.type),
                color: _getEventColor(event),
                size: 20,
              ),
            ),
            title: Text(event.title),
            subtitle: _buildEventSubtitle(event),
            trailing:
                event.type == CalendarEventType.period && event.flow != null
                ? Chip(
                    label: Text(
                      _getFlowText(event.flow!),
                      style: const TextStyle(fontSize: 10),
                    ),
                    backgroundColor: _getFlowColor(
                      event.flow!,
                    ).withOpacity(0.2),
                  )
                : null,
          ),
        );
      },
    );
  }

  Widget? _buildEventSubtitle(CalendarEvent event) {
    switch (event.type) {
      case CalendarEventType.symptom:
        if (event.symptom != null) {
          final symptoms = [
            ...event.symptom!.physicalSymptoms,
            ...event.symptom!.emotionalSymptoms,
          ];
          return Text(
            symptoms.join(', '),
            style: TextStyle(color: Colors.white.withOpacity(0.7)),
          );
        }
        break;
      case CalendarEventType.period:
        return Text(
          'Menstrual flow',
          style: TextStyle(color: Colors.white.withOpacity(0.7)),
        );
      case CalendarEventType.fertility:
        return Text(
          'High chance of conception',
          style: TextStyle(color: Colors.white.withOpacity(0.7)),
        );
      case CalendarEventType.ovulation:
        return Text(
          'Egg release predicted',
          style: TextStyle(color: Colors.white.withOpacity(0.7)),
        );
      case CalendarEventType.predictedPeriod:
        return Text(
          'Based on cycle history',
          style: TextStyle(color: Colors.white.withOpacity(0.7)),
        );
    }
    return null;
  }

  Color _getEventColor(CalendarEvent event) {
    switch (event.type) {
      case CalendarEventType.period:
        return _getFlowColor(event.flow ?? 3);
      case CalendarEventType.fertility:
        return Colors.green;
      case CalendarEventType.ovulation:
        return Colors.orange;
      case CalendarEventType.symptom:
        return Colors.purple;
      case CalendarEventType.predictedPeriod:
        return Colors.pink.shade300;
    }
  }

  IconData _getEventIcon(CalendarEventType type) {
    switch (type) {
      case CalendarEventType.period:
      case CalendarEventType.predictedPeriod:
        return Icons.water_drop;
      case CalendarEventType.fertility:
        return Icons.favorite;
      case CalendarEventType.ovulation:
        return Icons.egg;
      case CalendarEventType.symptom:
        return Icons.healing;
    }
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
        return 'Light-Med';
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

class CalendarEvent {
  final String title;
  final CalendarEventType type;
  final int? flow;
  final Symptom? symptom;

  CalendarEvent({
    required this.title,
    required this.type,
    this.flow,
    this.symptom,
  });
}

enum CalendarEventType {
  period,
  fertility,
  ovulation,
  symptom,
  predictedPeriod,
}
