import 'achievement_definition.dart';
import 'achievement_progress_snapshot.dart';

class AchievementResult {
  final AchievementDefinition definition;
  final bool isUnlocked;
  final DateTime? unlockedAt;
  final AchievementProgressSnapshot? progress;

  const AchievementResult({
    required this.definition,
    required this.isUnlocked,
    this.unlockedAt,
    this.progress,
  });

  bool get hasProgress => progress != null && !isUnlocked;

  double get progressFraction =>
      hasProgress ? progress!.fraction : (isUnlocked ? 1.0 : 0.0);
}
