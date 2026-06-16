// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'AIO Workout';

  @override
  String get nav_home => 'Home';

  @override
  String get nav_history => 'History';

  @override
  String get nav_profile => 'Profile';

  @override
  String get home_greeting_morning => 'Good morning!';

  @override
  String get home_greeting_afternoon => 'Good afternoon!';

  @override
  String get home_greeting_evening => 'Good evening!';

  @override
  String get home_workoutComplete => 'Workout Complete!';

  @override
  String get home_todaysWorkout => 'Today\'s Workout';

  @override
  String get home_thisWeek => 'This Week';

  @override
  String get home_week => 'Week';

  @override
  String get home_day => 'Day';

  @override
  String get home_exercises => 'Exercises';

  @override
  String get home_duration => 'Duration';

  @override
  String get home_completed => 'Completed';

  @override
  String get home_min => 'min';

  @override
  String get home_sets => 'sets';

  @override
  String get home_reps => 'reps';

  @override
  String get home_seconds => 's';

  @override
  String get home_steps => 'Steps';

  @override
  String get home_hydration => 'Hydration';

  @override
  String get home_waterDrank => 'Water drank';

  @override
  String get home_liters => 'liters';

  @override
  String get home_weight => 'Weight';

  @override
  String get home_weightGoal => 'Weight Goal';

  @override
  String get home_logWeight => 'Log Weight';

  @override
  String get home_kg => 'kg';

  @override
  String get home_missedWorkout =>
      '⚠ Complete at least one exercise to finish your workout!';

  @override
  String get home_noExercises =>
      'Great work! You\'ve completed all the exercises today.';

  @override
  String get home_letsGo => 'Let\'s Go!';

  @override
  String get home_completeWorkout => 'Finish Workout';

  @override
  String get home_startWorkout => 'Start Workout';

  @override
  String get home_restDay => 'Rest Day';

  @override
  String get home_restDayDesc =>
      'Take the day off to recover. Your muscles repair and grow during rest.';

  @override
  String get home_restTimer => 'Rest Timer';

  @override
  String get home_restBetweenSets => 'Rest between sets';

  @override
  String get home_skipRest => 'Skip';

  @override
  String get home_startSet => 'Start Set';

  @override
  String get history_title => 'History';

  @override
  String get history_noWorkouts => 'No workouts yet';

  @override
  String get history_week => 'Week';

  @override
  String get history_day => 'Day';

  @override
  String get history_sessions => 'sessions';

  @override
  String get history_session => 'session';

  @override
  String get history_exercises => 'Exercises';

  @override
  String get history_duration => 'Duration';

  @override
  String get history_minutes => 'min';

  @override
  String get history_weight => 'Weight';

  @override
  String get history_resolution => 'Resolution';

  @override
  String get history_steps => 'Steps';

  @override
  String get history_hydration => 'Hydration';

  @override
  String get history_thisWeek => 'This Week';

  @override
  String get history_prevWeek => 'Prev Week';

  @override
  String get history_nextWeek => 'Next Week';

  @override
  String get profile_title => 'Profile';

  @override
  String get profile_editProfile => 'Edit Profile';

  @override
  String get profile_exerciseLibrary => 'Exercise Library';

  @override
  String get profile_workoutPlan => 'Workout Plan';

  @override
  String get profile_notifications => 'Notifications';

  @override
  String get profile_appearance => 'Appearance';

  @override
  String get profile_languageUnits => 'Language & Units';

  @override
  String get profile_english => 'English';

  @override
  String get profile_arabic => 'العربية';

  @override
  String get profile_languageToggle => 'English / العربية';

  @override
  String get profile_metricImperial => 'Metric / Imperial';

  @override
  String get profile_metric => 'Metric (kg, km)';

  @override
  String get profile_imperial => 'Imperial (lb, mi)';

  @override
  String get profile_restTimer => 'Rest Timer';

  @override
  String get profile_restTimerDesc => 'Time between exercise sets';

  @override
  String get profile_done => 'Done';

  @override
  String get profile_workouts => 'Workouts';

  @override
  String get profile_dayStreak => 'Day Streak';

  @override
  String get profile_goal => 'goal';

  @override
  String get profile_day => 'day';

  @override
  String get profile_signOut => 'Sign Out';

  @override
  String get profile_reset => 'Reset';

  @override
  String get profile_support => 'Support';

  @override
  String get profile_account => 'Account';

  @override
  String get profile_preferences => 'Preferences';

  @override
  String get profile_memberSince => 'Member since';

  @override
  String get profile_soon => 'Soon';

  @override
  String get profile_comingSoon => 'Coming soon!';

  @override
  String get profile_help => 'Help & Feedback';

  @override
  String get profile_logUpdates => 'Log & Updates';

  @override
  String get profile_tips => 'Tips & Tricks';

  @override
  String get profile_resetTitle => 'Reset Progress';

  @override
  String get profile_resetSelect => 'Select what to reset:';

  @override
  String get profile_resetWorkout => 'Daily workout progress';

  @override
  String get profile_resetWater => 'Water drank';

  @override
  String get profile_resetSteps => 'Steps count';

  @override
  String get profile_resetAllData => 'Reset All Data';

  @override
  String get profile_resetCancel => 'Cancel';

  @override
  String get profile_resetConfirm => 'Reset';

  @override
  String profile_resetSnackbar(String items) {
    return 'Reset: $items';
  }

  @override
  String get profile_resetAllTitle => 'Reset All Data';

  @override
  String get profile_resetAllBody =>
      'This will permanently delete ALL your data:\n\n• Workout history\n• Weight logs\n• Profile info\n• Custom exercises\n• Progress & streaks\n• Settings & preferences\n\nThis action cannot be undone.';

  @override
  String get profile_resetAllConfirm => 'Delete Everything';

  @override
  String get profile_resetAllSnackbar => 'All data has been reset';

  @override
  String get profile_signOutTitle => 'Sign Out';

  @override
  String get profile_signOutBody => 'Are you sure you want to sign out?';

  @override
  String get profile_signOutSuccess => 'Signed out successfully';

  @override
  String profile_goalDisplay(String goal) {
    return 'Goal: $goal';
  }

  @override
  String profile_ageYrs(String name, int age) {
    return '$name · $age yrs';
  }

  @override
  String get dialog_editProfile => 'Edit Profile';

  @override
  String get dialog_save => 'Save';

  @override
  String get dialog_cancel => 'Cancel';

  @override
  String get dialog_name => 'Name';

  @override
  String get dialog_email => 'Email';

  @override
  String get dialog_age => 'Age';

  @override
  String get dialog_goal => 'Goal';

  @override
  String get dialog_generalFitness => 'General Fitness';

  @override
  String get dialog_weightLoss => 'Weight Loss';

  @override
  String get dialog_muscleGain => 'Muscle Gain';

  @override
  String get dialog_endurance => 'Endurance';

  @override
  String get dialog_flexibility => 'Flexibility';

  @override
  String get dialog_weightLogTitle => 'Log Weight';

  @override
  String get dialog_weightLogKg => 'Weight (kg)';

  @override
  String get dialog_weightLogLb => 'Weight (lb)';

  @override
  String get dialog_workoutPlanTitle => 'Workout Plan';

  @override
  String get dialog_workoutWeek => 'Week';

  @override
  String get dialog_workoutDay => 'Day';

  @override
  String get dialog_workoutFocus => 'Focus';

  @override
  String get dialog_workoutRestDay => 'Rest Day';

  @override
  String get dialog_exerciseProgressTitle => 'Exercise Progress';

  @override
  String get dialog_exerciseSets => 'Sets';

  @override
  String get dialog_exerciseReps => 'Reps';

  @override
  String get dialog_exerciseWeight => 'Weight';

  @override
  String get dialog_exerciseDuration => 'Duration';

  @override
  String get dialog_achievementsTitle => 'Achievements';

  @override
  String get dialog_achievementsUnlocked => 'Unlocked';

  @override
  String get dialog_achievementsLocked => 'Locked';

  @override
  String get dialog_achievementsProgress => 'Progress';

  @override
  String get dialog_achievementsCategory_workout => 'Workout';

  @override
  String get dialog_achievementsCategory_consistency => 'Consistency';

  @override
  String get dialog_achievementsCategory_steps => 'Steps';

  @override
  String get dialog_achievementsCategory_hydration => 'Hydration';

  @override
  String get dialog_achievementsCategory_weight => 'Weight';

  @override
  String get dialog_achievementsCategory_special => 'Special';

  @override
  String get exercise_plank_name => 'Plank';

  @override
  String get exercise_plank_desc =>
      'Hold a straight line from head to heels, supported on forearms and toes.';

  @override
  String get exercise_cocoons_name => 'Cocoons';

  @override
  String get exercise_cocoons_desc =>
      'From high plank, roll into a tight tuck and back out.';

  @override
  String get exercise_pushups_name => 'Push Ups';

  @override
  String get exercise_pushups_desc =>
      'Classic push-up from high plank position. Lower chest to floor and press back up.';

  @override
  String get exercise_squats_name => 'Bodyweight Squats';

  @override
  String get exercise_squats_desc =>
      'Stand with feet shoulder-width, lower hips back and down as if sitting, then stand.';

  @override
  String get exercise_overheadpress_name => 'Overhead Press';

  @override
  String get exercise_overheadpress_desc =>
      'Press dumbbells or bar from shoulder height straight overhead to full lockout.';

  @override
  String get exercise_jumpingjacks_name => 'Jumping Jacks';

  @override
  String get exercise_jumpingjacks_desc =>
      'Jump while spreading legs and raising arms overhead, then return to start.';

  @override
  String get exercise_deadbug_name => 'Dead Bug';

  @override
  String get exercise_deadbug_desc =>
      'Lie on back, extend opposite arm and leg while keeping lower back pressed to floor.';

  @override
  String get exercise_bicepcurls_name => 'Bicep Curls';

  @override
  String get exercise_bicepcurls_desc =>
      'Curl dumbbells from sides to shoulders while keeping elbows tucked.';

  @override
  String get exercise_highkneemarch_name => 'Gentle High-Knee March';

  @override
  String get exercise_highkneemarch_desc =>
      'March in place lifting knees to hip height. Keep core engaged and back straight.';

  @override
  String get exercise_glutebridge_name => 'Glute Bridge';

  @override
  String get exercise_glutebridge_desc =>
      'Lie on back with knees bent, lift hips toward ceiling, squeeze glutes at the top.';

  @override
  String get exercise_birddog_name => 'Bird Dog';

  @override
  String get exercise_birddog_desc =>
      'From all fours, extend opposite arm and leg, hold for 2 seconds, return. Alternate sides.';

  @override
  String get exercise_sidelyinglegraise_name => 'Side-Lying Leg Raise';

  @override
  String get exercise_sidelyinglegraise_desc =>
      'Lie on side, lift top leg keeping hips stacked and core engaged. Lower slowly.';

  @override
  String get exercise_rest_name => 'Rest Day';

  @override
  String get exercise_rest_desc =>
      'Take the day off to recover. Your muscles repair and grow during rest.';

  @override
  String get category_strength => 'Strength';

  @override
  String get category_cardio => 'Cardio';

  @override
  String get category_core => 'Core';

  @override
  String get category_flexibility => 'Flexibility';

  @override
  String get category_fullbody => 'Full Body';

  @override
  String get category_upperbody => 'Upper Body';

  @override
  String get category_lowerbody => 'Lower Body';

  @override
  String get muscle_chest => 'Chest';

  @override
  String get muscle_back => 'Back';

  @override
  String get muscle_shoulders => 'Shoulders';

  @override
  String get muscle_arms => 'Arms';

  @override
  String get muscle_legs => 'Legs';

  @override
  String get muscle_core => 'Core';

  @override
  String get muscle_fullbody => 'Full Body';

  @override
  String get muscle_cardio => 'Cardio';

  @override
  String get level_beginner => 'Beginner';

  @override
  String get level_intermediate => 'Intermediate';

  @override
  String get level_advanced => 'Advanced';

  @override
  String get level_custom => 'Custom';

  @override
  String get equipment_bodyweight => 'Bodyweight';

  @override
  String get equipment_dumbbells => 'Dumbbells';

  @override
  String get focus_core_foundation => 'Core Foundation';

  @override
  String get focus_upper_body_basics => 'Upper Body Basics';

  @override
  String get focus_lower_body_foundation => 'Lower Body Foundation';

  @override
  String get focus_full_body_foundation => 'Full Body Foundation';

  @override
  String get focus_cardio_conditioning => 'Cardio & Conditioning';

  @override
  String get focus_dynamic_core => 'Dynamic Core';

  @override
  String get focus_upper_body_power => 'Upper Body Power';

  @override
  String get focus_lower_body_strength => 'Lower Body Strength';

  @override
  String get focus_full_body_conditioning => 'Full Body Conditioning';

  @override
  String get focus_cardio_endurance => 'Cardio Endurance';

  @override
  String get focus_advanced_core => 'Advanced Core';

  @override
  String get focus_upper_body_peak => 'Upper Body Peak';

  @override
  String get focus_lower_body_peak => 'Lower Body Peak';

  @override
  String get focus_full_body_hiit => 'Full Body HIIT';

  @override
  String get focus_peak_cardio => 'Peak Cardio';

  @override
  String get focus_rest_day => 'Rest Day';

  @override
  String get achievement_first_steps_title => 'First Steps';

  @override
  String get achievement_first_steps_desc => 'Complete your first workout';

  @override
  String get achievement_first_steps_label => 'Workouts';

  @override
  String get achievement_getting_started_title => 'Getting Started';

  @override
  String get achievement_getting_started_desc => 'Complete 10 workouts';

  @override
  String get achievement_getting_started_label => 'Workouts';

  @override
  String get achievement_quarter_century_title => 'Quarter Century';

  @override
  String get achievement_quarter_century_desc => 'Complete 25 workouts';

  @override
  String get achievement_quarter_century_label => 'Workouts';

  @override
  String get achievement_half_century_title => 'Half Century';

  @override
  String get achievement_half_century_desc => 'Complete 50 workouts';

  @override
  String get achievement_half_century_label => 'Workouts';

  @override
  String get achievement_century_club_title => 'Century Club';

  @override
  String get achievement_century_club_desc => 'Complete 100 workouts';

  @override
  String get achievement_century_club_label => 'Workouts';

  @override
  String get achievement_core_crusher_title => 'Core Crusher';

  @override
  String get achievement_core_crusher_desc =>
      'Complete 10 core-focused workouts';

  @override
  String get achievement_core_crusher_label => 'Core workouts';

  @override
  String get achievement_upper_champ_title => 'Upper Body Champ';

  @override
  String get achievement_upper_champ_desc => 'Complete 10 upper body workouts';

  @override
  String get achievement_upper_champ_label => 'Upper body workouts';

  @override
  String get achievement_lower_legend_title => 'Lower Body Legend';

  @override
  String get achievement_lower_legend_desc => 'Complete 10 lower body workouts';

  @override
  String get achievement_lower_legend_label => 'Lower body workouts';

  @override
  String get achievement_full_fusion_title => 'Full Body Fusion';

  @override
  String get achievement_full_fusion_desc => 'Complete 10 full body workouts';

  @override
  String get achievement_full_fusion_label => 'Full body workouts';

  @override
  String get achievement_volume_100_title => 'Volume 100';

  @override
  String get achievement_volume_100_desc => 'Complete 100 total exercise sets';

  @override
  String get achievement_volume_100_label => 'Sets';

  @override
  String get achievement_volume_500_title => 'Volume 500';

  @override
  String get achievement_volume_500_desc => 'Complete 500 total exercise sets';

  @override
  String get achievement_volume_500_label => 'Sets';

  @override
  String get achievement_volume_1k_title => 'Volume 1K';

  @override
  String get achievement_volume_1k_desc => 'Complete 1,000 total exercise sets';

  @override
  String get achievement_volume_1k_label => 'Sets';

  @override
  String get achievement_week_warrior_title => 'Week Warrior';

  @override
  String get achievement_week_warrior_desc =>
      'Complete a full week (5 workouts)';

  @override
  String get achievement_week_warrior_label => 'Week 1 workouts';

  @override
  String get achievement_dedicated_title => 'Dedicated';

  @override
  String get achievement_dedicated_desc => 'Complete 4 consecutive weeks';

  @override
  String get achievement_dedicated_label => 'Consecutive weeks';

  @override
  String get achievement_halfway_there_title => 'Halfway There';

  @override
  String get achievement_halfway_there_desc => 'Complete 6 weeks';

  @override
  String get achievement_halfway_there_label => 'Weeks completed';

  @override
  String get achievement_graduate_title => 'Program Graduate';

  @override
  String get achievement_graduate_desc => 'Complete all 12 weeks';

  @override
  String get achievement_graduate_label => 'Weeks completed';

  @override
  String get achievement_streak_master_title => 'Streak Master';

  @override
  String get achievement_streak_master_desc => 'Complete 5 workouts in a row';

  @override
  String get achievement_streak_master_label => 'Day streak';

  @override
  String get achievement_ten_thousand_title => 'Ten Thousand';

  @override
  String get achievement_ten_thousand_desc => 'Accumulate 10,000 total steps';

  @override
  String get achievement_ten_thousand_label => 'Total steps';

  @override
  String get achievement_walker_title => 'Walker';

  @override
  String get achievement_walker_desc => 'Accumulate 50,000 total steps';

  @override
  String get achievement_walker_label => 'Total steps';

  @override
  String get achievement_explorer_title => 'Explorer';

  @override
  String get achievement_explorer_desc => 'Accumulate 100,000 total steps';

  @override
  String get achievement_explorer_label => 'Total steps';

  @override
  String get achievement_marathoner_title => 'Marathoner';

  @override
  String get achievement_marathoner_desc => 'Accumulate 500,000 total steps';

  @override
  String get achievement_marathoner_label => 'Total steps';

  @override
  String get achievement_well_hydrated_title => 'Well Hydrated';

  @override
  String get achievement_well_hydrated_desc =>
      'Consume 10 liters of water total';

  @override
  String get achievement_well_hydrated_label => 'Total liters';

  @override
  String get achievement_aqua_master_title => 'Aqua Master';

  @override
  String get achievement_aqua_master_desc => 'Consume 50 liters of water total';

  @override
  String get achievement_aqua_master_label => 'Total liters';

  @override
  String get achievement_hydro_homie_title => 'Hydro Homie';

  @override
  String get achievement_hydro_homie_desc =>
      'Consume 100 liters of water total';

  @override
  String get achievement_hydro_homie_label => 'Total liters';

  @override
  String get achievement_starting_point_title => 'Starting Point';

  @override
  String get achievement_starting_point_desc => 'Log your first weight entry';

  @override
  String get achievement_starting_point_label => 'Weight entries';

  @override
  String get achievement_consistent_logger_title => 'Consistent Logger';

  @override
  String get achievement_consistent_logger_desc => 'Log weight 7 times';

  @override
  String get achievement_consistent_logger_label => 'Weight logs';

  @override
  String get achievement_goal_setter_title => 'Goal Setter';

  @override
  String get achievement_goal_setter_desc => 'Set a weight goal';

  @override
  String get achievement_goal_setter_label => 'Goal set';

  @override
  String get achievement_who_am_i_title => 'Who Am I?';

  @override
  String get achievement_who_am_i_desc => 'Fill in all profile fields';

  @override
  String get achievement_who_am_i_label => 'Profile';

  @override
  String get achievement_early_bird_title => 'Early Bird';

  @override
  String get achievement_early_bird_desc => 'Complete 5 workouts before 8 AM';

  @override
  String get achievement_early_bird_label => 'Early workouts';

  @override
  String get achievement_night_owl_title => 'Night Owl';

  @override
  String get achievement_night_owl_desc => 'Complete 5 workouts after 9 PM';

  @override
  String get achievement_night_owl_label => 'Late workouts';

  @override
  String get notif_title => 'Notifications';

  @override
  String get notif_on => 'On';

  @override
  String get notif_off => 'Off';

  @override
  String get notif_done => 'Done';

  @override
  String get notif_save => 'Save';

  @override
  String get notif_cancel => 'Cancel';

  @override
  String get notif_test => 'Test Notification';

  @override
  String get notif_testSent =>
      'Test notification sent. Check your notification tray.';

  @override
  String get notif_pause => 'Pause Notifications';

  @override
  String get notif_resume => 'Resume Notifications';

  @override
  String get notif_paused => 'Paused';

  @override
  String get notif_active => 'Active';

  @override
  String get notif_remaining => 'remaining';

  @override
  String get notif_workoutReminders => 'Workout Reminders';

  @override
  String get notif_progressStats => 'Progress & Stats';

  @override
  String get notif_dailyReminder => 'Daily Workout Reminder';

  @override
  String get notif_dailyReminderSub => 'Remind me to work out daily';

  @override
  String get notif_dailyReminderConfigTitle => 'Daily Reminder';

  @override
  String get notif_dailyReminderConfigBody =>
      'What time should I remind you\nto work out?';

  @override
  String get notif_tapToChange => 'Tap to change';

  @override
  String get notif_missedWorkout => 'Missed Workout Reminder';

  @override
  String get notif_missedWorkoutSub => 'Nudge me after a missed workout';

  @override
  String get notif_missedWorkoutConfigTitle => 'Missed Workout';

  @override
  String get notif_missedWorkoutConfigHeader =>
      'Get a gentle nudge when you miss a workout.';

  @override
  String get notif_waitTime => 'Wait time after missed workout';

  @override
  String get notif_waitTimeDesc => 'How long to wait before sending a reminder';

  @override
  String get notif_achievementNotif => 'Achievement Notification';

  @override
  String get notif_achievementNotifSub => 'Celebrate my achievements';

  @override
  String get notif_recovery => 'Recovery Suggestion';

  @override
  String get notif_recoverySub => 'Suggest rest after consecutive days';

  @override
  String get notif_weeklyProgress => 'Weekly Progress';

  @override
  String get notif_weeklyProgressSub => 'Weekly summary of my stats';

  @override
  String get notif_weeklyProgressConfigTitle => 'Weekly Progress';

  @override
  String get notif_weeklyProgressConfigHeader =>
      'Choose which day you\'d like to receive\nyour weekly progress summary.';

  @override
  String get notif_weightFollowUp => 'Weight Follow-Up';

  @override
  String get notif_weightFollowUpSub => 'Remind me to log my weight';

  @override
  String get notif_weightConfigTitle => 'Weight Follow-Up';

  @override
  String get notif_weightConfigHeader =>
      'Remind yourself to log your weight regularly and track toward your goal.';

  @override
  String get notif_targetWeight => 'Target Weight';

  @override
  String get notif_remindEvery => 'Remind me every…';

  @override
  String get notif_quietHours => 'Quiet Hours';

  @override
  String get notif_quietHoursSub =>
      'Suppress notifications during specified hours';

  @override
  String get notif_quietHoursConfigTitle => 'Quiet Hours';

  @override
  String get notif_quietHoursDesc =>
      'Notifications will be suppressed between start and end time.';

  @override
  String get notif_startTime => 'Start';

  @override
  String get notif_endTime => 'End';

  @override
  String get notif_dailyBody => 'Ready to crush it 💪';

  @override
  String get notif_missedBody =>
      'You missed your workout today. Time to get back on track!';

  @override
  String get notif_recoveryBody => 'You may benefit from a recovery day.';

  @override
  String get notif_restCompleteTitle => 'Rest Complete';

  @override
  String get notif_restCompleteBody => 'Rest complete. Start next set.';

  @override
  String get general_saveError => 'Couldn\'t save workout. Please try again.';

  @override
  String get general_saved => 'Saved!';

  @override
  String get general_loading => 'Loading…';

  @override
  String get celebration_workoutComplete => 'Workout Complete!';

  @override
  String get weekday_monday_abbr => 'Mo';

  @override
  String get weekday_tuesday_abbr => 'Tu';

  @override
  String get weekday_wednesday_abbr => 'We';

  @override
  String get weekday_thursday_abbr => 'Th';

  @override
  String get weekday_friday_abbr => 'Fr';

  @override
  String get weekday_saturday_abbr => 'Sa';

  @override
  String get weekday_sunday_abbr => 'Su';

  @override
  String get dialog_changePhoto => 'Change Photo';

  @override
  String get dialog_camera => 'Camera';

  @override
  String get dialog_gallery => 'Gallery';

  @override
  String get dialog_removePhoto => 'Remove';

  @override
  String get dialog_unsavedChanges => 'Unsaved Changes';

  @override
  String get dialog_unsavedChangesBody =>
      'You have unsaved changes. Discard them?';

  @override
  String get dialog_keepEditing => 'Keep Editing';

  @override
  String get dialog_discard => 'Discard';

  @override
  String get dialog_fullName => 'Full Name';

  @override
  String get dialog_enterNameHint => 'Enter your name';

  @override
  String get dialog_dateOfBirth => 'Date of Birth';

  @override
  String get dialog_tapToSelect => 'Tap to select';

  @override
  String dialog_ageDisplay(int age) {
    return 'Age: $age';
  }

  @override
  String get dialog_weight => 'Weight';

  @override
  String get dialog_weightHint => 'e.g. 70';

  @override
  String get dialog_weightRange => 'Enter 20–300 kg';

  @override
  String get dialog_height => 'Height';

  @override
  String get dialog_heightHint => 'e.g. 175';

  @override
  String get dialog_heightRange => 'Enter 50–250 cm';

  @override
  String get dialog_bodyMassIndex => 'Body Mass Index';

  @override
  String get dialog_underweight => 'Underweight';

  @override
  String get dialog_normal => 'Normal';

  @override
  String get dialog_overweight => 'Overweight';

  @override
  String get dialog_obese => 'Obese';

  @override
  String get dialog_gender => 'Gender';

  @override
  String get dialog_male => 'Male';

  @override
  String get dialog_female => 'Female';

  @override
  String get dialog_otherGender => 'Other';

  @override
  String get dialog_saveChanges => 'Save Changes';

  @override
  String get dialog_required => 'Required';

  @override
  String get dialog_enterValidName => 'Enter a valid name';

  @override
  String get dialog_enterValidEmail => 'Enter a valid email';

  @override
  String get dialog_enterNumber => 'Enter a number';

  @override
  String get dialog_minAgeError => 'You must be at least 10 years old';

  @override
  String get dialog_verifyDob => 'Please verify your date of birth';

  @override
  String dialog_failedToSave(String error) {
    return 'Failed to save: $error';
  }

  @override
  String dialog_setOfSemantics(int current, int total) {
    return 'Set $current of $total';
  }

  @override
  String dialog_ofTotal(int total) {
    return 'of $total';
  }

  @override
  String dialog_setLabel(int number) {
    return 'Set $number';
  }

  @override
  String dialog_secondsHold(int seconds) {
    return '${seconds}s hold';
  }

  @override
  String dialog_repsCount(int reps) {
    return '$reps reps';
  }

  @override
  String dialog_weightKgLabel(double weight) {
    return '$weight kg';
  }

  @override
  String dialog_startSet(int number) {
    return 'Start Set $number';
  }

  @override
  String get dialog_completeSet => 'Complete Set';

  @override
  String get dialog_hold => 'Hold';

  @override
  String get dialog_skipHold => 'Skip Hold';

  @override
  String get dialog_rest => 'Rest';

  @override
  String get dialog_allSetsDone => 'All Sets Done!';

  @override
  String get dialog_greatWork => 'Great work!';

  @override
  String get dialog_backToWorkout => 'Back to Workout';

  @override
  String get dialog_endWorkout => 'End Workout';

  @override
  String get dialog_endWorkoutTitle => 'End Workout?';

  @override
  String dialog_endWorkoutBody(int current, int total) {
    return 'You’ve completed $current of $total sets.';
  }

  @override
  String get dialog_restTimerActive => 'Rest timer is active.';

  @override
  String dialog_equipment(String equipment) {
    return 'Equipment: $equipment';
  }

  @override
  String get dialog_watchOnYoutube => 'Watch on YouTube';

  @override
  String get dialog_setTargetWeight => 'Set Target Weight';

  @override
  String get dialog_setGoal => 'Set Goal';

  @override
  String get dialog_saveWeight => 'Save Weight';

  @override
  String get dialog_saving => 'Saving…';

  @override
  String get dialog_recordWeightSubtitle => 'Record your weight for today';

  @override
  String get dialog_today => 'Today';

  @override
  String get dialog_setTargetWeightLink => 'Set target weight';

  @override
  String get dialog_allFilter => 'All';

  @override
  String get dialog_noAchievements => 'No achievements in this category';

  @override
  String get dialog_12WeekProgram => '12-Week Program';

  @override
  String dialog_weekDayDisplay(int week, int day) {
    return 'Week $week — Day $day';
  }

  @override
  String get dialog_workoutsLabel => 'workouts';

  @override
  String get dialog_foundationPhase => 'Foundation Phase';

  @override
  String get dialog_buildingPhase => 'Building Phase';

  @override
  String get dialog_peakPhase => 'Peak Phase';

  @override
  String get dialog_foundation => 'Foundation';

  @override
  String get dialog_building => 'Building';

  @override
  String get dialog_peak => 'Peak';

  @override
  String dialog_weekLabel(int week) {
    return 'Week $week';
  }

  @override
  String get dialog_current => 'Current';

  @override
  String get notif_hydrationReminder => 'Hydration Reminder';

  @override
  String get notif_hydrationReminderSub =>
      'Get reminded to drink water throughout the day';

  @override
  String get notif_hydrationReminderConfigTitle => 'Hydration Reminder';

  @override
  String get notif_hydrationReminderConfigBody =>
      'Configure your hydration reminder settings';

  @override
  String get notif_hydrationEnable => 'Enable Hydration Reminder';

  @override
  String get notif_hydrationEnableSub =>
      'Receive periodic reminders to stay hydrated';

  @override
  String get notif_hydrationInterval => 'Reminder Interval';

  @override
  String get notif_hydrationActiveHours => 'Active Hours';

  @override
  String get notif_hydrationRemindersPerDay => 'Reminders per day';

  @override
  String get notif_hydrationAmountPerReminder => 'Amount per reminder';

  @override
  String notif_hydrationBasedOnGoal(String goal) {
    return 'Based on your ${goal}L daily goal';
  }

  @override
  String notif_hydrationMessage(int amount) {
    return 'Time to hydrate! Drink ~${amount}mL to stay on track 💧';
  }

  @override
  String get notif_enableAchievement => 'Enable Achievement Notifications';

  @override
  String get notif_enableAchievementSub =>
      'Get notified when you unlock a new achievement';

  @override
  String get notif_enableRecovery => 'Enable Recovery Suggestions';

  @override
  String get notif_enableRecoverySub =>
      'Get reminded to take rest days after consecutive workouts';

  @override
  String get notif_enableQuietHours => 'Enable Quiet Hours';

  @override
  String get notif_chooseStartTime => 'Choose start time';

  @override
  String get notif_chooseEndTime => 'Choose end time';

  @override
  String get notif_enableDailyReminder => 'Enable Daily Reminder';

  @override
  String get notif_enableDailyReminderSub =>
      'Receive a daily reminder to complete your workout';

  @override
  String get notif_enableMissedWorkout => 'Enable Missed Workout Reminder';

  @override
  String get notif_enableMissedWorkoutSub =>
      'Get a nudge when you miss a workout';

  @override
  String get notif_hour => 'hour';

  @override
  String get notif_hours => 'hours';

  @override
  String get notif_day => 'day';

  @override
  String get notif_confirmTurnOff => 'Turn off all notifications?';

  @override
  String get notif_confirmTurnOffBody =>
      'You won\'t receive any workout reminders, achievements, or progress updates.';

  @override
  String get notif_keepEnabled => 'Keep On';

  @override
  String get notif_turnOff => 'Turn Off';

  @override
  String notif_nextScheduled(String time) {
    return 'Next: $time';
  }

  @override
  String get notif_weekdayMonday => 'Monday';

  @override
  String get notif_weekdayTuesday => 'Tuesday';

  @override
  String get notif_weekdayWednesday => 'Wednesday';

  @override
  String get notif_weekdayThursday => 'Thursday';

  @override
  String get notif_weekdayFriday => 'Friday';

  @override
  String get notif_weekdaySaturday => 'Saturday';

  @override
  String get notif_weekdaySunday => 'Sunday';

  @override
  String get notif_chooseDay => 'Choose day';

  @override
  String get notif_notificationTime => 'Notification time';

  @override
  String get notif_slideToSetWeight => 'Slide to set your target weight';

  @override
  String get notif_weightGoalQuestion => 'What weight are you working toward?';

  @override
  String get notif_frequencyQuestion =>
      'How often to ask you to log your weight';

  @override
  String get notif_everyDay => 'Every day';

  @override
  String get notif_weekly => 'Weekly';

  @override
  String get notif_every2Weeks => 'Every 2 weeks';

  @override
  String notif_everyNDays(int days) {
    return 'Every $days days';
  }

  @override
  String get notif_kilograms => 'Kilograms';

  @override
  String get notif_pounds => 'Pounds';

  @override
  String get helpFeedback_title => 'Help & Feedback';

  @override
  String get helpFeedback_helpTab => 'Help';

  @override
  String get helpFeedback_feedbackTab => 'Feedback';

  @override
  String get helpFeedback_faq => 'Frequently Asked Questions';

  @override
  String get helpFeedback_faqSubtitle => 'Quick answers to common questions';

  @override
  String get helpFeedback_quickLinks => 'Quick Links';

  @override
  String home_kGoal(int count) {
    return '${count}k goal';
  }

  @override
  String home_kLabel(int count) {
    return '${count}k';
  }

  @override
  String home_km(String distance) {
    return '$distance km';
  }

  @override
  String home_kcal(String calories) {
    return '$calories kcal';
  }

  @override
  String get home_tapToAdd => 'Tap to add';

  @override
  String get home_tapToRecord => 'Tap to record';

  @override
  String get home_loggedToday => 'Logged today';

  @override
  String get home_loggedYesterday => 'Logged yesterday';

  @override
  String home_loggedDaysAgo(int count) {
    return '$count days ago';
  }

  @override
  String home_workoutsCount(int count) {
    return '$count workouts';
  }

  @override
  String get helpFeedback_exerciseGuide => 'Exercise Guide';

  @override
  String get helpFeedback_exerciseGuideDesc =>
      'Browse exercises with form tips and videos';

  @override
  String get helpFeedback_changelog => 'What\'s New';

  @override
  String get helpFeedback_changelogDesc =>
      'See the latest updates and improvements';

  @override
  String get helpFeedback_notificationTips => 'Notification Tips';

  @override
  String get helpFeedback_notificationTipsDesc =>
      'Configure reminders to stay on track';

  @override
  String get helpFeedback_tips => 'Tips & Tricks';

  @override
  String get helpFeedback_tipsDesc =>
      'Science-backed advice for your fitness journey';

  @override
  String get helpFeedback_category => 'Category';

  @override
  String get helpFeedback_bugReport => 'Bug Report';

  @override
  String get helpFeedback_featureRequest => 'Feature Request';

  @override
  String get helpFeedback_generalFeedback => 'General Feedback';

  @override
  String get helpFeedback_question => 'Question';

  @override
  String get helpFeedback_name => 'Name';

  @override
  String get helpFeedback_nameHint => 'Your name';

  @override
  String get helpFeedback_email => 'Email';

  @override
  String get helpFeedback_emailHint => 'your@email.com';

  @override
  String get helpFeedback_subject => 'Subject';

  @override
  String get helpFeedback_subjectHint => 'Brief summary';

  @override
  String get helpFeedback_message => 'Message';

  @override
  String get helpFeedback_messageHint => 'Tell us what you think…';

  @override
  String get helpFeedback_sendViaWhatsapp => 'Send via WhatsApp';

  @override
  String get helpFeedback_sending => 'Opening WhatsApp…';

  @override
  String get helpFeedback_success =>
      'Draft opened in WhatsApp! Thanks for helping us improve.';

  @override
  String get helpFeedback_required => 'Required';

  @override
  String helpFeedback_minLength(Object count) {
    return 'Minimum $count characters';
  }

  @override
  String get helpFeedback_enterValidEmail => 'Enter a valid email';

  @override
  String get helpFeedback_attachScreenshot => 'Attach Screenshot';

  @override
  String get helpFeedback_removeScreenshot => 'Remove';

  @override
  String get helpFeedback_openInWhatsapp => 'Open in WhatsApp';

  @override
  String get helpFeedback_whatsappFailed =>
      'Could not open WhatsApp. Please try again.';

  @override
  String get helpFeedback_openLink => 'Open link';

  @override
  String get faq_howToLogWorkouts => 'How do I log workouts?';

  @override
  String get faq_howToLogWorkoutsAnswer =>
      'Go to the Home screen and tap \"Start Workout\" on today\'s workout card. Complete exercises by tapping each set, and finish with \"Complete Workout\".';

  @override
  String get faq_howToTrackSteps => 'How do I track my steps?';

  @override
  String get faq_howToTrackStepsAnswer =>
      'Steps are tracked automatically if your device has a sensor. You can also tap the Steps card on the Home screen to manually add steps.';

  @override
  String get faq_howToLogWater => 'How do I log water intake?';

  @override
  String get faq_howToLogWaterAnswer =>
      'Tap the Hydration card on the Home screen to add water. Each tap adds one glass (250 ml). You can also set a daily goal in Notifications.';

  @override
  String get faq_howAchievementsWork => 'How do achievements work?';

  @override
  String get faq_howAchievementsWorkAnswer =>
      'Achievements unlock automatically as you hit milestones — completing workouts, logging steps, drinking water, etc. Check your progress on the Achievements card.';

  @override
  String get faq_howToChangePlan => 'How do I change my workout plan?';

  @override
  String get faq_howToChangePlanAnswer =>
      'Go to Profile → Workout Plan to choose a different week-day combination. Your progress will be preserved.';

  @override
  String get faq_howToSetGoals => 'How do I set step and hydration goals?';

  @override
  String get faq_howToSetGoalsAnswer =>
      'Tap the Steps or Hydration card on the Home screen, then long-press to adjust your daily targets.';

  @override
  String get faq_howNotificationsWork => 'How do notifications work?';

  @override
  String get faq_howNotificationsWorkAnswer =>
      'Go to Profile → Notifications to enable daily reminders, missed workout nudges, achievement alerts, and hydration reminders with custom schedules.';

  @override
  String get faq_howToLogWeight => 'How do I log my weight?';

  @override
  String get faq_howToLogWeightAnswer =>
      'On the Home screen, tap \"Log Weight\" in the Weight section to record your current weight and track progress toward your goal.';
}
