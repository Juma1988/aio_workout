library;

import 'package:flutter/material.dart';

import '../../data/exercise.dart' show Level;

/// Visual identity for exercise taxonomy: colors and icons.
///
/// Lives in the theme layer on purpose — `lib/data/` models expose keys
/// only, so a rebrand or dark-mode tweak never touches data classes.
class ExerciseVisuals {
  static const Color _fallback = Color(0xFF9E9E9E);

  static const Map<String, Color> _categoryColors = {
    'strength': Color(0xFFFF5722),
    'cardio': Color(0xFF4CAF50),
    'core': Color(0xFF2196F3),
    'flexibility': Color(0xFF9C27B0),
    'fullbody': Color(0xFFF44336),
    'upperbody': Color(0xFFFF9800),
    'lowerbody': Color(0xFF00BCD4),
  };

  static const Map<String, IconData> _categoryIcons = {
    'strength': Icons.fitness_center,
    'cardio': Icons.directions_run,
    'core': Icons.sync_alt,
    'flexibility': Icons.self_improvement,
    'fullbody': Icons.whatshot,
    'upperbody': Icons.arrow_upward,
    'lowerbody': Icons.arrow_downward,
  };

  static const Map<String, Color> _muscleColors = {
    'chest': Color(0xFFFF5722),
    'back': Color(0xFF2196F3),
    'shoulders': Color(0xFFFF9800),
    'arms': Color(0xFF4CAF50),
    'legs': Color(0xFF00BCD4),
    'core': Color(0xFF9C27B0),
    'fullbody': Color(0xFFF44336),
    'cardio': Color(0xFFE91E63),
  };

  static const Map<Level, Color> _levelColors = {
    Level.beginner: Color(0xFF43A047),
    Level.intermediate: Color(0xFFFFA000),
    Level.advanced: Color(0xFFE53935),
    Level.custom: Color(0xFF8E24AA),
  };

  static Color categoryColor(String key) => _categoryColors[key] ?? _fallback;

  static IconData categoryIcon(String key) =>
      _categoryIcons[key] ?? Icons.fitness_center;

  static Color muscleColor(String key) => _muscleColors[key] ?? _fallback;

  static Color levelColor(Level level) => _levelColors[level] ?? _fallback;
}
