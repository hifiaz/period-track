class User {
  final String id;
  final String name;
  final DateTime? birthDate;
  final int averageCycleLength;
  final int averagePeriodLength;
  final DateTime? lastPeriodDate;
  final bool isPregnant;
  final bool isBreastfeeding;
  final bool useContraception;
  final String? contraceptionType;
  final List<String> healthConditions;
  final Map<String, bool> notificationSettings;
  final String theme; // 'light', 'dark', 'system'
  final String language;
  final bool isFirstTime;
  final DateTime createdAt;
  final DateTime updatedAt;

  User({
    required this.id,
    required this.name,
    this.birthDate,
    this.averageCycleLength = 28,
    this.averagePeriodLength = 5,
    this.lastPeriodDate,
    this.isPregnant = false,
    this.isBreastfeeding = false,
    this.useContraception = false,
    this.contraceptionType,
    this.healthConditions = const [],
    this.notificationSettings = const {
      'periodReminder': true,
      'ovulationReminder': true,
      'fertilityWindow': true,
      'symptoms': false,
      'insights': true,
    },
    this.theme = 'system',
    this.language = 'en',
    this.isFirstTime = true,
    required this.createdAt,
    required this.updatedAt,
  });

  // Calculate age
  int? get age {
    if (birthDate == null) return null;
    final now = DateTime.now();
    int age = now.year - birthDate!.year;
    if (now.month < birthDate!.month || 
        (now.month == birthDate!.month && now.day < birthDate!.day)) {
      age--;
    }
    return age;
  }

  // Predict next period date
  DateTime? get nextPeriodPrediction {
    if (lastPeriodDate == null) return null;
    return lastPeriodDate!.add(Duration(days: averageCycleLength));
  }

  // Predict ovulation date
  DateTime? get nextOvulationPrediction {
    if (lastPeriodDate == null) return null;
    return lastPeriodDate!.add(Duration(days: averageCycleLength - 14));
  }

  // Get fertility window
  Map<String, DateTime?> get fertilityWindow {
    final ovulation = nextOvulationPrediction;
    if (ovulation == null) return {'start': null, 'end': null};
    
    return {
      'start': ovulation.subtract(const Duration(days: 5)),
      'end': ovulation.add(const Duration(days: 1)),
    };
  }

  // JSON serialization
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'birthDate': birthDate?.toIso8601String(),
      'averageCycleLength': averageCycleLength,
      'averagePeriodLength': averagePeriodLength,
      'lastPeriodDate': lastPeriodDate?.toIso8601String(),
      'isPregnant': isPregnant,
      'isBreastfeeding': isBreastfeeding,
      'useContraception': useContraception,
      'contraceptionType': contraceptionType,
      'healthConditions': healthConditions,
      'notificationSettings': notificationSettings,
      'theme': theme,
      'language': language,
      'isFirstTime': isFirstTime,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      birthDate: json['birthDate'] != null ? DateTime.parse(json['birthDate']) : null,
      averageCycleLength: json['averageCycleLength'] ?? 28,
      averagePeriodLength: json['averagePeriodLength'] ?? 5,
      lastPeriodDate: json['lastPeriodDate'] != null ? DateTime.parse(json['lastPeriodDate']) : null,
      isPregnant: json['isPregnant'] ?? false,
      isBreastfeeding: json['isBreastfeeding'] ?? false,
      useContraception: json['useContraception'] ?? false,
      contraceptionType: json['contraceptionType'],
      healthConditions: List<String>.from(json['healthConditions'] ?? []),
      notificationSettings: Map<String, bool>.from(json['notificationSettings'] ?? {
        'periodReminder': true,
        'ovulationReminder': true,
        'fertilityWindow': true,
        'symptoms': false,
        'insights': true,
      }),
      theme: json['theme'] ?? 'system',
      language: json['language'] ?? 'en',
      isFirstTime: json['isFirstTime'] ?? true,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  User copyWith({
    String? id,
    String? name,
    DateTime? birthDate,
    int? averageCycleLength,
    int? averagePeriodLength,
    DateTime? lastPeriodDate,
    bool? isPregnant,
    bool? isBreastfeeding,
    bool? useContraception,
    String? contraceptionType,
    List<String>? healthConditions,
    Map<String, bool>? notificationSettings,
    String? theme,
    String? language,
    bool? isFirstTime,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      birthDate: birthDate ?? this.birthDate,
      averageCycleLength: averageCycleLength ?? this.averageCycleLength,
      averagePeriodLength: averagePeriodLength ?? this.averagePeriodLength,
      lastPeriodDate: lastPeriodDate ?? this.lastPeriodDate,
      isPregnant: isPregnant ?? this.isPregnant,
      isBreastfeeding: isBreastfeeding ?? this.isBreastfeeding,
      useContraception: useContraception ?? this.useContraception,
      contraceptionType: contraceptionType ?? this.contraceptionType,
      healthConditions: healthConditions ?? this.healthConditions,
      notificationSettings: notificationSettings ?? this.notificationSettings,
      theme: theme ?? this.theme,
      language: language ?? this.language,
      isFirstTime: isFirstTime ?? this.isFirstTime,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is User && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}