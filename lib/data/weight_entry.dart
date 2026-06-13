class WeightEntry {
  final String uuid;
  final DateTime date;
  final double weightKg;
  final String? notes;

  const WeightEntry({
    required this.uuid,
    required this.date,
    required this.weightKg,
    this.notes,
  });

  Map<String, dynamic> toJson() => {
    'uuid': uuid,
    'date': date.toIso8601String(),
    'weightKg': weightKg,
    if (notes != null) 'notes': notes,
  };

  factory WeightEntry.fromJson(Map<String, dynamic> json) => WeightEntry(
    uuid: json['uuid'] as String,
    date: DateTime.parse(json['date'] as String),
    weightKg: (json['weightKg'] as num).toDouble(),
    notes: json['notes'] as String?,
  );
}
