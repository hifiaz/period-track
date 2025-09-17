class Cycle {
  final String id;
  final DateTime startDate;
  final DateTime? endDate;
  final int length; // Total cycle length in days
  final int periodLength; // Period duration in days
  final DateTime? ovulationDate;
  final DateTime? fertilityWindowStart;
  final DateTime? fertilityWindowEnd;
  final List<String> symptoms;
  final double? basalTemperature;
  final String? cervicalMucus;
  final String? mood;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  Cycle({
    required this.id,
    required this.startDate,
    this.endDate,
    required this.length,
    required this.periodLength,
    this.ovulationDate,
    this.fertilityWindowStart,
    this.fertilityWindowEnd,
    required this.symptoms,
    this.basalTemperature,
    this.cervicalMucus,
    this.mood,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  // Check if cycle is complete
  bool get isComplete => endDate != null;

  // Calculate cycle phase
  String getCyclePhase(DateTime date) {
    if (date.isBefore(startDate)) return 'Previous Cycle';
    
    final dayInCycle = date.difference(startDate).inDays + 1;
    
    if (dayInCycle <= periodLength) {
      return 'Menstrual';
    } else if (dayInCycle <= 13) {
      return 'Follicular';
    } else if (dayInCycle <= 15) {
      return 'Ovulation';
    } else {
      return 'Luteal';
    }
  }

  // Check if date is in fertility window
  bool isInFertilityWindow(DateTime date) {
    if (fertilityWindowStart == null || fertilityWindowEnd == null) return false;
    return date.isAfter(fertilityWindowStart!.subtract(const Duration(days: 1))) &&
           date.isBefore(fertilityWindowEnd!.add(const Duration(days: 1)));
  }

  // JSON serialization
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'length': length,
      'periodLength': periodLength,
      'ovulationDate': ovulationDate?.toIso8601String(),
      'fertilityWindowStart': fertilityWindowStart?.toIso8601String(),
      'fertilityWindowEnd': fertilityWindowEnd?.toIso8601String(),
      'symptoms': symptoms,
      'basalTemperature': basalTemperature,
      'cervicalMucus': cervicalMucus,
      'mood': mood,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Cycle.fromJson(Map<String, dynamic> json) {
    return Cycle(
      id: json['id'],
      startDate: DateTime.parse(json['startDate']),
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
      length: json['length'],
      periodLength: json['periodLength'],
      ovulationDate: json['ovulationDate'] != null ? DateTime.parse(json['ovulationDate']) : null,
      fertilityWindowStart: json['fertilityWindowStart'] != null ? DateTime.parse(json['fertilityWindowStart']) : null,
      fertilityWindowEnd: json['fertilityWindowEnd'] != null ? DateTime.parse(json['fertilityWindowEnd']) : null,
      symptoms: List<String>.from(json['symptoms']),
      basalTemperature: json['basalTemperature']?.toDouble(),
      cervicalMucus: json['cervicalMucus'],
      mood: json['mood'],
      notes: json['notes'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Cycle copyWith({
    String? id,
    DateTime? startDate,
    DateTime? endDate,
    int? length,
    int? periodLength,
    DateTime? ovulationDate,
    DateTime? fertilityWindowStart,
    DateTime? fertilityWindowEnd,
    List<String>? symptoms,
    double? basalTemperature,
    String? cervicalMucus,
    String? mood,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Cycle(
      id: id ?? this.id,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      length: length ?? this.length,
      periodLength: periodLength ?? this.periodLength,
      ovulationDate: ovulationDate ?? this.ovulationDate,
      fertilityWindowStart: fertilityWindowStart ?? this.fertilityWindowStart,
      fertilityWindowEnd: fertilityWindowEnd ?? this.fertilityWindowEnd,
      symptoms: symptoms ?? this.symptoms,
      basalTemperature: basalTemperature ?? this.basalTemperature,
      cervicalMucus: cervicalMucus ?? this.cervicalMucus,
      mood: mood ?? this.mood,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Cycle && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}