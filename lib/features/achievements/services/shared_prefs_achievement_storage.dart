import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/achievement_state.dart';
import 'achievement_storage.dart';

class SharedPrefsAchievementStorage implements AchievementStorage {
  static const _stateKey = 'achievements_state';
  static const _migrationKey = 'achievement_migration_v2';

  @override
  Future<AchievementState> loadState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_stateKey);
      if (raw == null) return AchievementState.empty();
      return AchievementState.fromJsonString(raw);
    } catch (e) {
      debugPrint('AchievementStorage.loadState error: $e');
      return AchievementState.empty();
    }
  }

  @override
  Future<void> saveState(AchievementState state) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_stateKey, state.toJsonString());
    } catch (e) {
      debugPrint('AchievementStorage.saveState error: $e');
    }
  }

  @override
  Future<bool> hasMigrationRun() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_migrationKey) ?? false;
    } catch (e) {
      debugPrint('AchievementStorage.hasMigrationRun error: $e');
      return false;
    }
  }

  @override
  Future<void> markMigrationComplete() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_migrationKey, true);
    } catch (e) {
      debugPrint('AchievementStorage.markMigrationComplete error: $e');
    }
  }
}
