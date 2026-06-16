import 'package:flutter/material.dart';

enum HydrationSource {
  water('Water', Icons.water_drop_rounded),
  tea('Tea', Icons.local_cafe_rounded),
  coffee('Coffee', Icons.coffee_rounded),
  juice('Juice', Icons.local_drink_rounded),
  soda('Soda', Icons.local_drink_rounded),
  smoothie('Smoothie', Icons.ramen_dining_rounded),
  other('Other', Icons.add_circle_rounded);

  const HydrationSource(this.label, this.icon);
  final String label;
  final IconData icon;
}

class HydrationEntry {
  final String id;
  final String date;
  final DateTime timestamp;
  final double liters;
  final HydrationSource source;
  final String notes;

  const HydrationEntry({
    required this.id,
    required this.date,
    required this.timestamp,
    required this.liters,
    required this.source,
    this.notes = '',
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'date': date,
    'timestamp': timestamp.toIso8601String(),
    'liters': liters,
    'source': source.name,
    'notes': notes,
  };

  factory HydrationEntry.fromJson(Map<String, dynamic> json) => HydrationEntry(
    id: json['id'] as String? ?? '',
    date: json['date'] as String,
    timestamp: json['timestamp'] != null
        ? DateTime.parse(json['timestamp'] as String)
        : DateTime.now(),
    liters: (json['liters'] as num?)?.toDouble() ?? 0.0,
    source: HydrationSource.values.firstWhere(
      (e) => e.name == json['source'],
      orElse: () => HydrationSource.other,
    ),
    notes: json['notes'] as String? ?? '',
  );
}

class DailyHydrationSummary {
  final String date;
  final double totalLiters;
  final double goalLiters;
  final double goalProgress;
  final List<HydrationEntry> entries;

  const DailyHydrationSummary({
    required this.date,
    required this.totalLiters,
    required this.goalLiters,
    required this.goalProgress,
    this.entries = const [],
  });

  factory DailyHydrationSummary.fromEntries(
    String date,
    List<HydrationEntry> entries,
    double goalLiters,
  ) {
    final total = entries.fold(0.0, (sum, e) => sum + e.liters);
    return DailyHydrationSummary(
      date: date,
      totalLiters: total,
      goalLiters: goalLiters,
      goalProgress: goalLiters > 0 ? (total / goalLiters).clamp(0.0, 1.0) : 0.0,
      entries: entries,
    );
  }
}

class WeeklyHydrationData {
  final List<DailyHydrationSummary> days;
  final double totalLiters;
  final double totalGoalLiters;
  final double averageDailyLiters;
  final int daysMetGoal;

  const WeeklyHydrationData({
    required this.days,
    required this.totalLiters,
    required this.totalGoalLiters,
    required this.averageDailyLiters,
    required this.daysMetGoal,
  });
}

class MonthlyHydrationData {
  final List<WeeklyHydrationData> weeks;
  final double totalLiters;
  final double totalGoalLiters;
  final double averageDailyLiters;
  final int activeDays;
  final int daysMetGoal;

  const MonthlyHydrationData({
    required this.weeks,
    required this.totalLiters,
    required this.totalGoalLiters,
    required this.averageDailyLiters,
    required this.activeDays,
    required this.daysMetGoal,
  });
}
