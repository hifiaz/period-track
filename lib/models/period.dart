class Period {
  final String id;
  final DateTime startDate;
  final DateTime? endDate;
  final int flow; // 1-5 scale (light to heavy)
  final List<String> symptoms;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  Period({
    required this.id,
    required this.startDate,
    this.endDate,
    required this.flow,
    required this.symptoms,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  // Calculate period length
  int get length {
    if (endDate == null) return 1;
    return endDate!.difference(startDate).inDays + 1;
  }

  // Check if period is ongoing
  bool get isOngoing => endDate == null;

  // JSON serialization
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'flow': flow,
      'symptoms': symptoms,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Period.fromJson(Map<String, dynamic> json) {
    return Period(
      id: json['id'],
      startDate: DateTime.parse(json['startDate']),
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
      flow: json['flow'],
      symptoms: List<String>.from(json['symptoms']),
      notes: json['notes'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Period copyWith({
    String? id,
    DateTime? startDate,
    DateTime? endDate,
    int? flow,
    List<String>? symptoms,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Period(
      id: id ?? this.id,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      flow: flow ?? this.flow,
      symptoms: symptoms ?? this.symptoms,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Period && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}