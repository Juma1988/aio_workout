import '../models/achievement_state.dart';

abstract class AchievementStorage {
  Future<AchievementState> loadState();
  Future<void> saveState(AchievementState state);
  Future<bool> hasMigrationRun();
  Future<void> markMigrationComplete();
}
