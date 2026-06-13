import '../l10n/app_localizations.dart';

/// Helper class that maps model keys (UUIDs, enum names, etc.)
/// to localized strings via [AppLocalizations].
///
/// All methods use the generated [AppLocalizations] getters so
/// they automatically pick up the active locale at runtime.
///
/// These helpers are intended for **display only**.  The raw
/// English values stored in JSON / models are left untouched.
class ExerciseLocalizer {
  // ── Exercise names ────────────────────────────────────────────────

  /// Returns the localized name for the exercise identified by [uuid].
  static String exerciseName(AppLocalizations l10n, String uuid) {
    switch (uuid) {
      case 'ex-plank-001':
        return l10n.exercise_plank_name;
      case 'ex-cocoons-001':
        return l10n.exercise_cocoons_name;
      case 'ex-pushups-001':
        return l10n.exercise_pushups_name;
      case 'ex-squats-001':
        return l10n.exercise_squats_name;
      case 'ex-overheadpress-001':
        return l10n.exercise_overheadpress_name;
      case 'ex-jumpingjacks-001':
        return l10n.exercise_jumpingjacks_name;
      case 'ex-deadbug-001':
        return l10n.exercise_deadbug_name;
      case 'ex-bicepcurls-001':
        return l10n.exercise_bicepcurls_name;
      case 'ex-highkneemarch-001':
        return l10n.exercise_highkneemarch_name;
      case 'ex-glutebridge-001':
        return l10n.exercise_glutebridge_name;
      case 'ex-birddog-001':
        return l10n.exercise_birddog_name;
      case 'ex-sidelyinglegraise-001':
        return l10n.exercise_sidelyinglegraise_name;
      case 'ex-rest-001':
        return l10n.exercise_rest_name;
      default:
        return uuid;
    }
  }

  /// Returns the localized description for the exercise identified by [uuid].
  static String exerciseDescription(AppLocalizations l10n, String uuid) {
    switch (uuid) {
      case 'ex-plank-001':
        return l10n.exercise_plank_desc;
      case 'ex-cocoons-001':
        return l10n.exercise_cocoons_desc;
      case 'ex-pushups-001':
        return l10n.exercise_pushups_desc;
      case 'ex-squats-001':
        return l10n.exercise_squats_desc;
      case 'ex-overheadpress-001':
        return l10n.exercise_overheadpress_desc;
      case 'ex-jumpingjacks-001':
        return l10n.exercise_jumpingjacks_desc;
      case 'ex-deadbug-001':
        return l10n.exercise_deadbug_desc;
      case 'ex-bicepcurls-001':
        return l10n.exercise_bicepcurls_desc;
      case 'ex-highkneemarch-001':
        return l10n.exercise_highkneemarch_desc;
      case 'ex-glutebridge-001':
        return l10n.exercise_glutebridge_desc;
      case 'ex-birddog-001':
        return l10n.exercise_birddog_desc;
      case 'ex-sidelyinglegraise-001':
        return l10n.exercise_sidelyinglegraise_desc;
      case 'ex-rest-001':
        return l10n.exercise_rest_desc;
      default:
        return '';
    }
  }

  // ── Categories ───────────────────────────────────────────────────

  /// Returns the localized category label for a key such as `'strength'`.
  static String categoryLabel(AppLocalizations l10n, String key) {
    switch (key) {
      case 'strength':
        return l10n.category_strength;
      case 'cardio':
        return l10n.category_cardio;
      case 'core':
        return l10n.category_core;
      case 'flexibility':
        return l10n.category_flexibility;
      case 'fullbody':
        return l10n.category_fullbody;
      case 'upperbody':
        return l10n.category_upperbody;
      case 'lowerbody':
        return l10n.category_lowerbody;
      default:
        return key;
    }
  }

  // ── Muscles ──────────────────────────────────────────────────────

  /// Returns the localized muscle label for a key such as `'chest'`.
  static String muscleLabel(AppLocalizations l10n, String key) {
    switch (key) {
      case 'chest':
        return l10n.muscle_chest;
      case 'back':
        return l10n.muscle_back;
      case 'shoulders':
        return l10n.muscle_shoulders;
      case 'arms':
        return l10n.muscle_arms;
      case 'legs':
        return l10n.muscle_legs;
      case 'core':
        return l10n.muscle_core;
      case 'fullbody':
        return l10n.muscle_fullbody;
      case 'cardio':
        return l10n.muscle_cardio;
      default:
        return key;
    }
  }

  // ── Levels ───────────────────────────────────────────────────────

  /// Returns the localized label for a level name such as `'beginner'`.
  ///
  /// See also [Level.localized] which calls this method directly.
  static String levelLabel(AppLocalizations l10n, String levelName) {
    switch (levelName) {
      case 'beginner':
        return l10n.level_beginner;
      case 'intermediate':
        return l10n.level_intermediate;
      case 'advanced':
        return l10n.level_advanced;
      case 'custom':
        return l10n.level_custom;
      default:
        return levelName;
    }
  }

  // ── Focus names ──────────────────────────────────────────────────

  /// Returns the localized focus name for the given English [focus] string
  /// (e.g. `"Core Foundation"`, `"Rest Day"`, etc.).
  ///
  /// These are the values produced by [getFocusForDay] in `workout_log.dart`.
  /// Because the focus names stored in [WorkoutSession] JSON are always
  /// English, you can pass `session.focus` directly to this method.
  static String focusName(AppLocalizations l10n, String focus) {
    switch (focus) {
      case 'Core Foundation':
        return l10n.focus_core_foundation;
      case 'Upper Body Basics':
        return l10n.focus_upper_body_basics;
      case 'Lower Body Foundation':
        return l10n.focus_lower_body_foundation;
      case 'Full Body Foundation':
        return l10n.focus_full_body_foundation;
      case 'Cardio & Conditioning':
        return l10n.focus_cardio_conditioning;
      case 'Dynamic Core':
        return l10n.focus_dynamic_core;
      case 'Upper Body Power':
        return l10n.focus_upper_body_power;
      case 'Lower Body Strength':
        return l10n.focus_lower_body_strength;
      case 'Full Body Conditioning':
        return l10n.focus_full_body_conditioning;
      case 'Cardio Endurance':
        return l10n.focus_cardio_endurance;
      case 'Advanced Core':
        return l10n.focus_advanced_core;
      case 'Upper Body Peak':
        return l10n.focus_upper_body_peak;
      case 'Lower Body Peak':
        return l10n.focus_lower_body_peak;
      case 'Full Body HIIT':
        return l10n.focus_full_body_hiit;
      case 'Peak Cardio':
        return l10n.focus_peak_cardio;
      case 'Rest Day':
        return l10n.focus_rest_day;
      default:
        return focus;
    }
  }

  // ── Achievements ─────────────────────────────────────────────────

  /// Returns the localized title for the achievement identified by [id].
  static String achievementTitle(AppLocalizations l10n, String id) {
    switch (id) {
      case 'first_steps':
        return l10n.achievement_first_steps_title;
      case 'workout_10':
        return l10n.achievement_getting_started_title;
      case 'workout_25':
        return l10n.achievement_quarter_century_title;
      case 'workout_50':
        return l10n.achievement_half_century_title;
      case 'workout_100':
        return l10n.achievement_century_club_title;
      case 'core_crusher':
        return l10n.achievement_core_crusher_title;
      case 'upper_champ':
        return l10n.achievement_upper_champ_title;
      case 'lower_legend':
        return l10n.achievement_lower_legend_title;
      case 'full_fusion':
        return l10n.achievement_full_fusion_title;
      case 'volume_100':
        return l10n.achievement_volume_100_title;
      case 'volume_500':
        return l10n.achievement_volume_500_title;
      case 'volume_1000':
        return l10n.achievement_volume_1k_title;
      case 'week_warrior':
        return l10n.achievement_week_warrior_title;
      case 'dedicated':
        return l10n.achievement_dedicated_title;
      case 'halfway':
        return l10n.achievement_halfway_there_title;
      case 'graduate':
        return l10n.achievement_graduate_title;
      case 'streak_5':
        return l10n.achievement_streak_master_title;
      case 'steps_10k':
        return l10n.achievement_ten_thousand_title;
      case 'steps_50k':
        return l10n.achievement_walker_title;
      case 'steps_100k':
        return l10n.achievement_explorer_title;
      case 'steps_500k':
        return l10n.achievement_marathoner_title;
      case 'water_10L':
        return l10n.achievement_well_hydrated_title;
      case 'water_50L':
        return l10n.achievement_aqua_master_title;
      case 'water_100L':
        return l10n.achievement_hydro_homie_title;
      case 'first_weight':
        return l10n.achievement_starting_point_title;
      case 'weight_consistent':
        return l10n.achievement_consistent_logger_title;
      case 'goal_setter':
        return l10n.achievement_goal_setter_title;
      case 'profile_complete':
        return l10n.achievement_who_am_i_title;
      case 'early_bird':
        return l10n.achievement_early_bird_title;
      case 'night_owl':
        return l10n.achievement_night_owl_title;
      default:
        return id;
    }
  }

  /// Returns the localized description for the achievement identified by [id].
  static String achievementDescription(AppLocalizations l10n, String id) {
    switch (id) {
      case 'first_steps':
        return l10n.achievement_first_steps_desc;
      case 'workout_10':
        return l10n.achievement_getting_started_desc;
      case 'workout_25':
        return l10n.achievement_quarter_century_desc;
      case 'workout_50':
        return l10n.achievement_half_century_desc;
      case 'workout_100':
        return l10n.achievement_century_club_desc;
      case 'core_crusher':
        return l10n.achievement_core_crusher_desc;
      case 'upper_champ':
        return l10n.achievement_upper_champ_desc;
      case 'lower_legend':
        return l10n.achievement_lower_legend_desc;
      case 'full_fusion':
        return l10n.achievement_full_fusion_desc;
      case 'volume_100':
        return l10n.achievement_volume_100_desc;
      case 'volume_500':
        return l10n.achievement_volume_500_desc;
      case 'volume_1000':
        return l10n.achievement_volume_1k_desc;
      case 'week_warrior':
        return l10n.achievement_week_warrior_desc;
      case 'dedicated':
        return l10n.achievement_dedicated_desc;
      case 'halfway':
        return l10n.achievement_halfway_there_desc;
      case 'graduate':
        return l10n.achievement_graduate_desc;
      case 'streak_5':
        return l10n.achievement_streak_master_desc;
      case 'steps_10k':
        return l10n.achievement_ten_thousand_desc;
      case 'steps_50k':
        return l10n.achievement_walker_desc;
      case 'steps_100k':
        return l10n.achievement_explorer_desc;
      case 'steps_500k':
        return l10n.achievement_marathoner_desc;
      case 'water_10L':
        return l10n.achievement_well_hydrated_desc;
      case 'water_50L':
        return l10n.achievement_aqua_master_desc;
      case 'water_100L':
        return l10n.achievement_hydro_homie_desc;
      case 'first_weight':
        return l10n.achievement_starting_point_desc;
      case 'weight_consistent':
        return l10n.achievement_consistent_logger_desc;
      case 'goal_setter':
        return l10n.achievement_goal_setter_desc;
      case 'profile_complete':
        return l10n.achievement_who_am_i_desc;
      case 'early_bird':
        return l10n.achievement_early_bird_desc;
      case 'night_owl':
        return l10n.achievement_night_owl_desc;
      default:
        return '';
    }
  }

  /// Returns the localized progress label for the achievement identified by [id].
  static String achievementProgressLabel(AppLocalizations l10n, String id) {
    switch (id) {
      case 'first_steps':
        return l10n.achievement_first_steps_label;
      case 'workout_10':
        return l10n.achievement_getting_started_label;
      case 'workout_25':
        return l10n.achievement_quarter_century_label;
      case 'workout_50':
        return l10n.achievement_half_century_label;
      case 'workout_100':
        return l10n.achievement_century_club_label;
      case 'core_crusher':
        return l10n.achievement_core_crusher_label;
      case 'upper_champ':
        return l10n.achievement_upper_champ_label;
      case 'lower_legend':
        return l10n.achievement_lower_legend_label;
      case 'full_fusion':
        return l10n.achievement_full_fusion_label;
      case 'volume_100':
        return l10n.achievement_volume_100_label;
      case 'volume_500':
        return l10n.achievement_volume_500_label;
      case 'volume_1000':
        return l10n.achievement_volume_1k_label;
      case 'week_warrior':
        return l10n.achievement_week_warrior_label;
      case 'dedicated':
        return l10n.achievement_dedicated_label;
      case 'halfway':
        return l10n.achievement_halfway_there_label;
      case 'graduate':
        return l10n.achievement_graduate_label;
      case 'streak_5':
        return l10n.achievement_streak_master_label;
      case 'steps_10k':
        return l10n.achievement_ten_thousand_label;
      case 'steps_50k':
        return l10n.achievement_walker_label;
      case 'steps_100k':
        return l10n.achievement_explorer_label;
      case 'steps_500k':
        return l10n.achievement_marathoner_label;
      case 'water_10L':
        return l10n.achievement_well_hydrated_label;
      case 'water_50L':
        return l10n.achievement_aqua_master_label;
      case 'water_100L':
        return l10n.achievement_hydro_homie_label;
      case 'first_weight':
        return l10n.achievement_starting_point_label;
      case 'weight_consistent':
        return l10n.achievement_consistent_logger_label;
      case 'goal_setter':
        return l10n.achievement_goal_setter_label;
      case 'profile_complete':
        return l10n.achievement_who_am_i_label;
      case 'early_bird':
        return l10n.achievement_early_bird_label;
      case 'night_owl':
        return l10n.achievement_night_owl_label;
      default:
        return '';
    }
  }
}
