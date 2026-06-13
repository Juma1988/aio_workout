import 'package:flutter/material.dart';

enum AchievementCategory {
  workout(
    label: 'Workout',
    icon: Icons.fitness_center,
    colorValue: 0xFF22C55E,
  ),
  consistency(
    label: 'Consistency',
    icon: Icons.calendar_month,
    colorValue: 0xFFF59E0B,
  ),
  steps(
    label: 'Steps',
    icon: Icons.directions_run,
    colorValue: 0xFFF97316,
  ),
  hydration(
    label: 'Hydration',
    icon: Icons.water_drop,
    colorValue: 0xFF3B82F6,
  ),
  weight(
    label: 'Weight',
    icon: Icons.monitor_weight_outlined,
    colorValue: 0xFFA855F7,
  ),
  special(
    label: 'Special',
    icon: Icons.auto_awesome,
    colorValue: 0xFFEF4444,
  );

  final String label;
  final IconData icon;
  final int colorValue;

  const AchievementCategory({
    required this.label,
    required this.icon,
    required this.colorValue,
  });

  Color get color => Color(colorValue);

  static const List<AchievementCategory> ordered = [
    AchievementCategory.workout,
    AchievementCategory.consistency,
    AchievementCategory.steps,
    AchievementCategory.hydration,
    AchievementCategory.weight,
    AchievementCategory.special,
  ];

  static AchievementCategory fromString(String value) {
    return AchievementCategory.values.firstWhere(
      (c) => c.name == value,
      orElse: () => AchievementCategory.workout,
    );
  }
}
