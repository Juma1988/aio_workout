import 'package:flutter/material.dart';
import '../../../data/exercise_localizer.dart';
import '../../../l10n/app_localizations.dart';
import 'achievement_category.dart';

class AchievementDefinition {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final AchievementCategory category;
  final int target;
  final String progressLabel;
  final bool isHidden;
  final int sortOrder;

  const AchievementDefinition({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.category,
    required this.target,
    required this.progressLabel,
    this.isHidden = false,
    this.sortOrder = 0,
  });

  /// Returns the localized achievement title via [ExerciseLocalizer].
  String localizedTitle(AppLocalizations l10n) =>
      ExerciseLocalizer.achievementTitle(l10n, id);

  /// Returns the localized achievement description via [ExerciseLocalizer].
  String localizedDescription(AppLocalizations l10n) =>
      ExerciseLocalizer.achievementDescription(l10n, id);

  /// Returns the localized progress label via [ExerciseLocalizer].
  String localizedProgressLabel(AppLocalizations l10n) =>
      ExerciseLocalizer.achievementProgressLabel(l10n, id);
}
