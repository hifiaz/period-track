class Symptom {
  final String id;
  final DateTime date;
  final List<String> physicalSymptoms;
  final List<String> emotionalSymptoms;
  final int? painLevel; // 1-10 scale
  final String? painLocation;
  final double? basalTemperature;
  final String? cervicalMucus;
  final String? mood;
  final int? energyLevel; // 1-5 scale
  final int? sleepQuality; // 1-5 scale
  final int? stressLevel; // 1-5 scale
  final bool? sexualActivity;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  Symptom({
    required this.id,
    required this.date,
    this.physicalSymptoms = const [],
    this.emotionalSymptoms = const [],
    this.painLevel,
    this.painLocation,
    this.basalTemperature,
    this.cervicalMucus,
    this.mood,
    this.energyLevel,
    this.sleepQuality,
    this.stressLevel,
    this.sexualActivity,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  // Get all symptoms combined
  List<String> get allSymptoms => [...physicalSymptoms, ...emotionalSymptoms];

  // Check if has any symptoms
  bool get hasSymptoms => physicalSymptoms.isNotEmpty || emotionalSymptoms.isNotEmpty;

  // Get symptom severity based on pain level and number of symptoms
  String get severity {
    final symptomCount = allSymptoms.length;
    final pain = painLevel ?? 0;
    
    if (pain >= 8 || symptomCount >= 8) return 'Severe';
    if (pain >= 5 || symptomCount >= 5) return 'Moderate';
    if (pain >= 3 || symptomCount >= 3) return 'Mild';
    if (pain > 0 || symptomCount > 0) return 'Light';
    return 'None';
  }

  // JSON serialization
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'physicalSymptoms': physicalSymptoms,
      'emotionalSymptoms': emotionalSymptoms,
      'painLevel': painLevel,
      'painLocation': painLocation,
      'basalTemperature': basalTemperature,
      'cervicalMucus': cervicalMucus,
      'mood': mood,
      'energyLevel': energyLevel,
      'sleepQuality': sleepQuality,
      'stressLevel': stressLevel,
      'sexualActivity': sexualActivity,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Symptom.fromJson(Map<String, dynamic> json) {
    return Symptom(
      id: json['id'],
      date: DateTime.parse(json['date']),
      physicalSymptoms: List<String>.from(json['physicalSymptoms'] ?? []),
      emotionalSymptoms: List<String>.from(json['emotionalSymptoms'] ?? []),
      painLevel: json['painLevel'],
      painLocation: json['painLocation'],
      basalTemperature: json['basalTemperature']?.toDouble(),
      cervicalMucus: json['cervicalMucus'],
      mood: json['mood'],
      energyLevel: json['energyLevel'],
      sleepQuality: json['sleepQuality'],
      stressLevel: json['stressLevel'],
      sexualActivity: json['sexualActivity'],
      notes: json['notes'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Symptom copyWith({
    String? id,
    DateTime? date,
    List<String>? physicalSymptoms,
    List<String>? emotionalSymptoms,
    int? painLevel,
    String? painLocation,
    double? basalTemperature,
    String? cervicalMucus,
    String? mood,
    int? energyLevel,
    int? sleepQuality,
    int? stressLevel,
    bool? sexualActivity,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Symptom(
      id: id ?? this.id,
      date: date ?? this.date,
      physicalSymptoms: physicalSymptoms ?? this.physicalSymptoms,
      emotionalSymptoms: emotionalSymptoms ?? this.emotionalSymptoms,
      painLevel: painLevel ?? this.painLevel,
      painLocation: painLocation ?? this.painLocation,
      basalTemperature: basalTemperature ?? this.basalTemperature,
      cervicalMucus: cervicalMucus ?? this.cervicalMucus,
      mood: mood ?? this.mood,
      energyLevel: energyLevel ?? this.energyLevel,
      sleepQuality: sleepQuality ?? this.sleepQuality,
      stressLevel: stressLevel ?? this.stressLevel,
      sexualActivity: sexualActivity ?? this.sexualActivity,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Symptom && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

// Predefined symptom lists
class SymptomConstants {
  static const List<String> physicalSymptoms = [
    'Cramps',
    'Headache',
    'Backache',
    'Breast tenderness',
    'Bloating',
    'Nausea',
    'Fatigue',
    'Acne',
    'Hot flashes',
    'Dizziness',
    'Constipation',
    'Diarrhea',
    'Food cravings',
    'Insomnia',
    'Joint pain',
    'Muscle aches',
  ];

  static const List<String> emotionalSymptoms = [
    'Mood swings',
    'Irritability',
    'Anxiety',
    'Depression',
    'Crying spells',
    'Anger',
    'Confusion',
    'Social withdrawal',
    'Tension',
    'Restlessness',
  ];

  static const List<String> moodOptions = [
    'Happy',
    'Sad',
    'Angry',
    'Anxious',
    'Calm',
    'Energetic',
    'Tired',
    'Stressed',
    'Content',
    'Overwhelmed',
  ];

  static const List<String> cervicalMucusOptions = [
    'Dry',
    'Sticky',
    'Creamy',
    'Watery',
    'Egg white',
  ];

  static const List<String> painLocations = [
    'Lower abdomen',
    'Lower back',
    'Upper abdomen',
    'Pelvis',
    'Thighs',
    'Head',
    'Breasts',
    'All over',
  ];
}