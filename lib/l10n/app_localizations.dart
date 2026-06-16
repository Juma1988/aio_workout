import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'AIO Workout'**
  String get appTitle;

  /// No description provided for @nav_home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get nav_home;

  /// No description provided for @nav_history.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get nav_history;

  /// No description provided for @nav_profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get nav_profile;

  /// No description provided for @home_greeting_morning.
  ///
  /// In en, this message translates to:
  /// **'Good morning!'**
  String get home_greeting_morning;

  /// No description provided for @home_greeting_afternoon.
  ///
  /// In en, this message translates to:
  /// **'Good afternoon!'**
  String get home_greeting_afternoon;

  /// No description provided for @home_greeting_evening.
  ///
  /// In en, this message translates to:
  /// **'Good evening!'**
  String get home_greeting_evening;

  /// No description provided for @home_workoutComplete.
  ///
  /// In en, this message translates to:
  /// **'Workout Complete!'**
  String get home_workoutComplete;

  /// No description provided for @home_todaysWorkout.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Workout'**
  String get home_todaysWorkout;

  /// No description provided for @home_thisWeek.
  ///
  /// In en, this message translates to:
  /// **'This Week'**
  String get home_thisWeek;

  /// No description provided for @home_week.
  ///
  /// In en, this message translates to:
  /// **'Week'**
  String get home_week;

  /// No description provided for @home_day.
  ///
  /// In en, this message translates to:
  /// **'Day'**
  String get home_day;

  /// No description provided for @home_exercises.
  ///
  /// In en, this message translates to:
  /// **'Exercises'**
  String get home_exercises;

  /// No description provided for @home_duration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get home_duration;

  /// No description provided for @home_completed.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get home_completed;

  /// No description provided for @home_min.
  ///
  /// In en, this message translates to:
  /// **'min'**
  String get home_min;

  /// No description provided for @home_sets.
  ///
  /// In en, this message translates to:
  /// **'sets'**
  String get home_sets;

  /// No description provided for @home_reps.
  ///
  /// In en, this message translates to:
  /// **'reps'**
  String get home_reps;

  /// No description provided for @home_seconds.
  ///
  /// In en, this message translates to:
  /// **'s'**
  String get home_seconds;

  /// No description provided for @home_steps.
  ///
  /// In en, this message translates to:
  /// **'Steps'**
  String get home_steps;

  /// No description provided for @home_hydration.
  ///
  /// In en, this message translates to:
  /// **'Hydration'**
  String get home_hydration;

  /// No description provided for @home_waterDrank.
  ///
  /// In en, this message translates to:
  /// **'Water drank'**
  String get home_waterDrank;

  /// No description provided for @home_liters.
  ///
  /// In en, this message translates to:
  /// **'liters'**
  String get home_liters;

  /// No description provided for @home_weight.
  ///
  /// In en, this message translates to:
  /// **'Weight'**
  String get home_weight;

  /// No description provided for @home_weightGoal.
  ///
  /// In en, this message translates to:
  /// **'Weight Goal'**
  String get home_weightGoal;

  /// No description provided for @home_logWeight.
  ///
  /// In en, this message translates to:
  /// **'Log Weight'**
  String get home_logWeight;

  /// No description provided for @home_kg.
  ///
  /// In en, this message translates to:
  /// **'kg'**
  String get home_kg;

  /// No description provided for @home_missedWorkout.
  ///
  /// In en, this message translates to:
  /// **'⚠ Complete at least one exercise to finish your workout!'**
  String get home_missedWorkout;

  /// No description provided for @home_noExercises.
  ///
  /// In en, this message translates to:
  /// **'Great work! You\'ve completed all the exercises today.'**
  String get home_noExercises;

  /// No description provided for @home_letsGo.
  ///
  /// In en, this message translates to:
  /// **'Let\'s Go!'**
  String get home_letsGo;

  /// No description provided for @home_completeWorkout.
  ///
  /// In en, this message translates to:
  /// **'Finish Workout'**
  String get home_completeWorkout;

  /// No description provided for @home_startWorkout.
  ///
  /// In en, this message translates to:
  /// **'Start Workout'**
  String get home_startWorkout;

  /// No description provided for @home_restDay.
  ///
  /// In en, this message translates to:
  /// **'Rest Day'**
  String get home_restDay;

  /// No description provided for @home_restDayDesc.
  ///
  /// In en, this message translates to:
  /// **'Take the day off to recover. Your muscles repair and grow during rest.'**
  String get home_restDayDesc;

  /// No description provided for @home_restTimer.
  ///
  /// In en, this message translates to:
  /// **'Rest Timer'**
  String get home_restTimer;

  /// No description provided for @home_restBetweenSets.
  ///
  /// In en, this message translates to:
  /// **'Rest between sets'**
  String get home_restBetweenSets;

  /// No description provided for @home_skipRest.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get home_skipRest;

  /// No description provided for @home_startSet.
  ///
  /// In en, this message translates to:
  /// **'Start Set'**
  String get home_startSet;

  /// No description provided for @history_title.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get history_title;

  /// No description provided for @history_noWorkouts.
  ///
  /// In en, this message translates to:
  /// **'No workouts yet'**
  String get history_noWorkouts;

  /// No description provided for @history_week.
  ///
  /// In en, this message translates to:
  /// **'Week'**
  String get history_week;

  /// No description provided for @history_day.
  ///
  /// In en, this message translates to:
  /// **'Day'**
  String get history_day;

  /// No description provided for @history_sessions.
  ///
  /// In en, this message translates to:
  /// **'sessions'**
  String get history_sessions;

  /// No description provided for @history_session.
  ///
  /// In en, this message translates to:
  /// **'session'**
  String get history_session;

  /// No description provided for @history_exercises.
  ///
  /// In en, this message translates to:
  /// **'Exercises'**
  String get history_exercises;

  /// No description provided for @history_duration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get history_duration;

  /// No description provided for @history_minutes.
  ///
  /// In en, this message translates to:
  /// **'min'**
  String get history_minutes;

  /// No description provided for @history_weight.
  ///
  /// In en, this message translates to:
  /// **'Weight'**
  String get history_weight;

  /// No description provided for @history_resolution.
  ///
  /// In en, this message translates to:
  /// **'Resolution'**
  String get history_resolution;

  /// No description provided for @history_steps.
  ///
  /// In en, this message translates to:
  /// **'Steps'**
  String get history_steps;

  /// No description provided for @history_hydration.
  ///
  /// In en, this message translates to:
  /// **'Hydration'**
  String get history_hydration;

  /// No description provided for @history_thisWeek.
  ///
  /// In en, this message translates to:
  /// **'This Week'**
  String get history_thisWeek;

  /// No description provided for @history_prevWeek.
  ///
  /// In en, this message translates to:
  /// **'Prev Week'**
  String get history_prevWeek;

  /// No description provided for @history_nextWeek.
  ///
  /// In en, this message translates to:
  /// **'Next Week'**
  String get history_nextWeek;

  /// No description provided for @profile_title.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile_title;

  /// No description provided for @profile_editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get profile_editProfile;

  /// No description provided for @profile_exerciseLibrary.
  ///
  /// In en, this message translates to:
  /// **'Exercise Library'**
  String get profile_exerciseLibrary;

  /// No description provided for @profile_workoutPlan.
  ///
  /// In en, this message translates to:
  /// **'Workout Plan'**
  String get profile_workoutPlan;

  /// No description provided for @profile_notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get profile_notifications;

  /// No description provided for @profile_appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get profile_appearance;

  /// No description provided for @profile_languageUnits.
  ///
  /// In en, this message translates to:
  /// **'Language & Units'**
  String get profile_languageUnits;

  /// No description provided for @profile_english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get profile_english;

  /// No description provided for @profile_arabic.
  ///
  /// In en, this message translates to:
  /// **'العربية'**
  String get profile_arabic;

  /// No description provided for @profile_languageToggle.
  ///
  /// In en, this message translates to:
  /// **'English / العربية'**
  String get profile_languageToggle;

  /// No description provided for @profile_metricImperial.
  ///
  /// In en, this message translates to:
  /// **'Metric / Imperial'**
  String get profile_metricImperial;

  /// No description provided for @profile_metric.
  ///
  /// In en, this message translates to:
  /// **'Metric (kg, km)'**
  String get profile_metric;

  /// No description provided for @profile_imperial.
  ///
  /// In en, this message translates to:
  /// **'Imperial (lb, mi)'**
  String get profile_imperial;

  /// No description provided for @profile_restTimer.
  ///
  /// In en, this message translates to:
  /// **'Rest Timer'**
  String get profile_restTimer;

  /// No description provided for @profile_restTimerDesc.
  ///
  /// In en, this message translates to:
  /// **'Time between exercise sets'**
  String get profile_restTimerDesc;

  /// No description provided for @profile_done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get profile_done;

  /// No description provided for @profile_workouts.
  ///
  /// In en, this message translates to:
  /// **'Workouts'**
  String get profile_workouts;

  /// No description provided for @profile_dayStreak.
  ///
  /// In en, this message translates to:
  /// **'Day Streak'**
  String get profile_dayStreak;

  /// No description provided for @profile_goal.
  ///
  /// In en, this message translates to:
  /// **'goal'**
  String get profile_goal;

  /// No description provided for @profile_day.
  ///
  /// In en, this message translates to:
  /// **'day'**
  String get profile_day;

  /// No description provided for @profile_signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get profile_signOut;

  /// No description provided for @profile_reset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get profile_reset;

  /// No description provided for @profile_support.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get profile_support;

  /// No description provided for @profile_account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get profile_account;

  /// No description provided for @profile_preferences.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get profile_preferences;

  /// No description provided for @profile_memberSince.
  ///
  /// In en, this message translates to:
  /// **'Member since'**
  String get profile_memberSince;

  /// No description provided for @profile_soon.
  ///
  /// In en, this message translates to:
  /// **'Soon'**
  String get profile_soon;

  /// No description provided for @profile_comingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming soon!'**
  String get profile_comingSoon;

  /// No description provided for @profile_help.
  ///
  /// In en, this message translates to:
  /// **'Help & Feedback'**
  String get profile_help;

  /// No description provided for @profile_logUpdates.
  ///
  /// In en, this message translates to:
  /// **'Log & Updates'**
  String get profile_logUpdates;

  /// No description provided for @profile_tips.
  ///
  /// In en, this message translates to:
  /// **'Tips & Tricks'**
  String get profile_tips;

  /// No description provided for @profile_resetTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset Progress'**
  String get profile_resetTitle;

  /// No description provided for @profile_resetSelect.
  ///
  /// In en, this message translates to:
  /// **'Select what to reset:'**
  String get profile_resetSelect;

  /// No description provided for @profile_resetWorkout.
  ///
  /// In en, this message translates to:
  /// **'Daily workout progress'**
  String get profile_resetWorkout;

  /// No description provided for @profile_resetWater.
  ///
  /// In en, this message translates to:
  /// **'Water drank'**
  String get profile_resetWater;

  /// No description provided for @profile_resetSteps.
  ///
  /// In en, this message translates to:
  /// **'Steps count'**
  String get profile_resetSteps;

  /// No description provided for @profile_resetAllData.
  ///
  /// In en, this message translates to:
  /// **'Reset All Data'**
  String get profile_resetAllData;

  /// No description provided for @profile_resetCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get profile_resetCancel;

  /// No description provided for @profile_resetConfirm.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get profile_resetConfirm;

  /// No description provided for @profile_resetSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Reset: {items}'**
  String profile_resetSnackbar(String items);

  /// No description provided for @profile_resetAllTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset All Data'**
  String get profile_resetAllTitle;

  /// No description provided for @profile_resetAllBody.
  ///
  /// In en, this message translates to:
  /// **'This will permanently delete ALL your data:\n\n• Workout history\n• Weight logs\n• Profile info\n• Custom exercises\n• Progress & streaks\n• Settings & preferences\n\nThis action cannot be undone.'**
  String get profile_resetAllBody;

  /// No description provided for @profile_resetAllConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete Everything'**
  String get profile_resetAllConfirm;

  /// No description provided for @profile_resetAllSnackbar.
  ///
  /// In en, this message translates to:
  /// **'All data has been reset'**
  String get profile_resetAllSnackbar;

  /// No description provided for @profile_signOutTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get profile_signOutTitle;

  /// No description provided for @profile_signOutBody.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to sign out?'**
  String get profile_signOutBody;

  /// No description provided for @profile_signOutSuccess.
  ///
  /// In en, this message translates to:
  /// **'Signed out successfully'**
  String get profile_signOutSuccess;

  /// No description provided for @profile_goalDisplay.
  ///
  /// In en, this message translates to:
  /// **'Goal: {goal}'**
  String profile_goalDisplay(String goal);

  /// No description provided for @profile_ageYrs.
  ///
  /// In en, this message translates to:
  /// **'{name} · {age} yrs'**
  String profile_ageYrs(String name, int age);

  /// No description provided for @dialog_editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get dialog_editProfile;

  /// No description provided for @dialog_save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get dialog_save;

  /// No description provided for @dialog_cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get dialog_cancel;

  /// No description provided for @dialog_name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get dialog_name;

  /// No description provided for @dialog_email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get dialog_email;

  /// No description provided for @dialog_age.
  ///
  /// In en, this message translates to:
  /// **'Age'**
  String get dialog_age;

  /// No description provided for @dialog_goal.
  ///
  /// In en, this message translates to:
  /// **'Goal'**
  String get dialog_goal;

  /// No description provided for @dialog_generalFitness.
  ///
  /// In en, this message translates to:
  /// **'General Fitness'**
  String get dialog_generalFitness;

  /// No description provided for @dialog_weightLoss.
  ///
  /// In en, this message translates to:
  /// **'Weight Loss'**
  String get dialog_weightLoss;

  /// No description provided for @dialog_muscleGain.
  ///
  /// In en, this message translates to:
  /// **'Muscle Gain'**
  String get dialog_muscleGain;

  /// No description provided for @dialog_endurance.
  ///
  /// In en, this message translates to:
  /// **'Endurance'**
  String get dialog_endurance;

  /// No description provided for @dialog_flexibility.
  ///
  /// In en, this message translates to:
  /// **'Flexibility'**
  String get dialog_flexibility;

  /// No description provided for @dialog_weightLogTitle.
  ///
  /// In en, this message translates to:
  /// **'Log Weight'**
  String get dialog_weightLogTitle;

  /// No description provided for @dialog_weightLogKg.
  ///
  /// In en, this message translates to:
  /// **'Weight (kg)'**
  String get dialog_weightLogKg;

  /// No description provided for @dialog_weightLogLb.
  ///
  /// In en, this message translates to:
  /// **'Weight (lb)'**
  String get dialog_weightLogLb;

  /// No description provided for @dialog_workoutPlanTitle.
  ///
  /// In en, this message translates to:
  /// **'Workout Plan'**
  String get dialog_workoutPlanTitle;

  /// No description provided for @dialog_workoutWeek.
  ///
  /// In en, this message translates to:
  /// **'Week'**
  String get dialog_workoutWeek;

  /// No description provided for @dialog_workoutDay.
  ///
  /// In en, this message translates to:
  /// **'Day'**
  String get dialog_workoutDay;

  /// No description provided for @dialog_workoutFocus.
  ///
  /// In en, this message translates to:
  /// **'Focus'**
  String get dialog_workoutFocus;

  /// No description provided for @dialog_workoutRestDay.
  ///
  /// In en, this message translates to:
  /// **'Rest Day'**
  String get dialog_workoutRestDay;

  /// No description provided for @dialog_exerciseProgressTitle.
  ///
  /// In en, this message translates to:
  /// **'Exercise Progress'**
  String get dialog_exerciseProgressTitle;

  /// No description provided for @dialog_exerciseSets.
  ///
  /// In en, this message translates to:
  /// **'Sets'**
  String get dialog_exerciseSets;

  /// No description provided for @dialog_exerciseReps.
  ///
  /// In en, this message translates to:
  /// **'Reps'**
  String get dialog_exerciseReps;

  /// No description provided for @dialog_exerciseWeight.
  ///
  /// In en, this message translates to:
  /// **'Weight'**
  String get dialog_exerciseWeight;

  /// No description provided for @dialog_exerciseDuration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get dialog_exerciseDuration;

  /// No description provided for @dialog_achievementsTitle.
  ///
  /// In en, this message translates to:
  /// **'Achievements'**
  String get dialog_achievementsTitle;

  /// No description provided for @dialog_achievementsUnlocked.
  ///
  /// In en, this message translates to:
  /// **'Unlocked'**
  String get dialog_achievementsUnlocked;

  /// No description provided for @dialog_achievementsLocked.
  ///
  /// In en, this message translates to:
  /// **'Locked'**
  String get dialog_achievementsLocked;

  /// No description provided for @dialog_achievementsProgress.
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get dialog_achievementsProgress;

  /// No description provided for @dialog_achievementsCategory_workout.
  ///
  /// In en, this message translates to:
  /// **'Workout'**
  String get dialog_achievementsCategory_workout;

  /// No description provided for @dialog_achievementsCategory_consistency.
  ///
  /// In en, this message translates to:
  /// **'Consistency'**
  String get dialog_achievementsCategory_consistency;

  /// No description provided for @dialog_achievementsCategory_steps.
  ///
  /// In en, this message translates to:
  /// **'Steps'**
  String get dialog_achievementsCategory_steps;

  /// No description provided for @dialog_achievementsCategory_hydration.
  ///
  /// In en, this message translates to:
  /// **'Hydration'**
  String get dialog_achievementsCategory_hydration;

  /// No description provided for @dialog_achievementsCategory_weight.
  ///
  /// In en, this message translates to:
  /// **'Weight'**
  String get dialog_achievementsCategory_weight;

  /// No description provided for @dialog_achievementsCategory_special.
  ///
  /// In en, this message translates to:
  /// **'Special'**
  String get dialog_achievementsCategory_special;

  /// No description provided for @exercise_plank_name.
  ///
  /// In en, this message translates to:
  /// **'Plank'**
  String get exercise_plank_name;

  /// No description provided for @exercise_plank_desc.
  ///
  /// In en, this message translates to:
  /// **'Hold a straight line from head to heels, supported on forearms and toes.'**
  String get exercise_plank_desc;

  /// No description provided for @exercise_cocoons_name.
  ///
  /// In en, this message translates to:
  /// **'Cocoons'**
  String get exercise_cocoons_name;

  /// No description provided for @exercise_cocoons_desc.
  ///
  /// In en, this message translates to:
  /// **'From high plank, roll into a tight tuck and back out.'**
  String get exercise_cocoons_desc;

  /// No description provided for @exercise_pushups_name.
  ///
  /// In en, this message translates to:
  /// **'Push Ups'**
  String get exercise_pushups_name;

  /// No description provided for @exercise_pushups_desc.
  ///
  /// In en, this message translates to:
  /// **'Classic push-up from high plank position. Lower chest to floor and press back up.'**
  String get exercise_pushups_desc;

  /// No description provided for @exercise_squats_name.
  ///
  /// In en, this message translates to:
  /// **'Bodyweight Squats'**
  String get exercise_squats_name;

  /// No description provided for @exercise_squats_desc.
  ///
  /// In en, this message translates to:
  /// **'Stand with feet shoulder-width, lower hips back and down as if sitting, then stand.'**
  String get exercise_squats_desc;

  /// No description provided for @exercise_overheadpress_name.
  ///
  /// In en, this message translates to:
  /// **'Overhead Press'**
  String get exercise_overheadpress_name;

  /// No description provided for @exercise_overheadpress_desc.
  ///
  /// In en, this message translates to:
  /// **'Press dumbbells or bar from shoulder height straight overhead to full lockout.'**
  String get exercise_overheadpress_desc;

  /// No description provided for @exercise_jumpingjacks_name.
  ///
  /// In en, this message translates to:
  /// **'Jumping Jacks'**
  String get exercise_jumpingjacks_name;

  /// No description provided for @exercise_jumpingjacks_desc.
  ///
  /// In en, this message translates to:
  /// **'Jump while spreading legs and raising arms overhead, then return to start.'**
  String get exercise_jumpingjacks_desc;

  /// No description provided for @exercise_deadbug_name.
  ///
  /// In en, this message translates to:
  /// **'Dead Bug'**
  String get exercise_deadbug_name;

  /// No description provided for @exercise_deadbug_desc.
  ///
  /// In en, this message translates to:
  /// **'Lie on back, extend opposite arm and leg while keeping lower back pressed to floor.'**
  String get exercise_deadbug_desc;

  /// No description provided for @exercise_bicepcurls_name.
  ///
  /// In en, this message translates to:
  /// **'Bicep Curls'**
  String get exercise_bicepcurls_name;

  /// No description provided for @exercise_bicepcurls_desc.
  ///
  /// In en, this message translates to:
  /// **'Curl dumbbells from sides to shoulders while keeping elbows tucked.'**
  String get exercise_bicepcurls_desc;

  /// No description provided for @exercise_highkneemarch_name.
  ///
  /// In en, this message translates to:
  /// **'Gentle High-Knee March'**
  String get exercise_highkneemarch_name;

  /// No description provided for @exercise_highkneemarch_desc.
  ///
  /// In en, this message translates to:
  /// **'March in place lifting knees to hip height. Keep core engaged and back straight.'**
  String get exercise_highkneemarch_desc;

  /// No description provided for @exercise_glutebridge_name.
  ///
  /// In en, this message translates to:
  /// **'Glute Bridge'**
  String get exercise_glutebridge_name;

  /// No description provided for @exercise_glutebridge_desc.
  ///
  /// In en, this message translates to:
  /// **'Lie on back with knees bent, lift hips toward ceiling, squeeze glutes at the top.'**
  String get exercise_glutebridge_desc;

  /// No description provided for @exercise_birddog_name.
  ///
  /// In en, this message translates to:
  /// **'Bird Dog'**
  String get exercise_birddog_name;

  /// No description provided for @exercise_birddog_desc.
  ///
  /// In en, this message translates to:
  /// **'From all fours, extend opposite arm and leg, hold for 2 seconds, return. Alternate sides.'**
  String get exercise_birddog_desc;

  /// No description provided for @exercise_sidelyinglegraise_name.
  ///
  /// In en, this message translates to:
  /// **'Side-Lying Leg Raise'**
  String get exercise_sidelyinglegraise_name;

  /// No description provided for @exercise_sidelyinglegraise_desc.
  ///
  /// In en, this message translates to:
  /// **'Lie on side, lift top leg keeping hips stacked and core engaged. Lower slowly.'**
  String get exercise_sidelyinglegraise_desc;

  /// No description provided for @exercise_rest_name.
  ///
  /// In en, this message translates to:
  /// **'Rest Day'**
  String get exercise_rest_name;

  /// No description provided for @exercise_rest_desc.
  ///
  /// In en, this message translates to:
  /// **'Take the day off to recover. Your muscles repair and grow during rest.'**
  String get exercise_rest_desc;

  /// No description provided for @category_strength.
  ///
  /// In en, this message translates to:
  /// **'Strength'**
  String get category_strength;

  /// No description provided for @category_cardio.
  ///
  /// In en, this message translates to:
  /// **'Cardio'**
  String get category_cardio;

  /// No description provided for @category_core.
  ///
  /// In en, this message translates to:
  /// **'Core'**
  String get category_core;

  /// No description provided for @category_flexibility.
  ///
  /// In en, this message translates to:
  /// **'Flexibility'**
  String get category_flexibility;

  /// No description provided for @category_fullbody.
  ///
  /// In en, this message translates to:
  /// **'Full Body'**
  String get category_fullbody;

  /// No description provided for @category_upperbody.
  ///
  /// In en, this message translates to:
  /// **'Upper Body'**
  String get category_upperbody;

  /// No description provided for @category_lowerbody.
  ///
  /// In en, this message translates to:
  /// **'Lower Body'**
  String get category_lowerbody;

  /// No description provided for @muscle_chest.
  ///
  /// In en, this message translates to:
  /// **'Chest'**
  String get muscle_chest;

  /// No description provided for @muscle_back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get muscle_back;

  /// No description provided for @muscle_shoulders.
  ///
  /// In en, this message translates to:
  /// **'Shoulders'**
  String get muscle_shoulders;

  /// No description provided for @muscle_arms.
  ///
  /// In en, this message translates to:
  /// **'Arms'**
  String get muscle_arms;

  /// No description provided for @muscle_legs.
  ///
  /// In en, this message translates to:
  /// **'Legs'**
  String get muscle_legs;

  /// No description provided for @muscle_core.
  ///
  /// In en, this message translates to:
  /// **'Core'**
  String get muscle_core;

  /// No description provided for @muscle_fullbody.
  ///
  /// In en, this message translates to:
  /// **'Full Body'**
  String get muscle_fullbody;

  /// No description provided for @muscle_cardio.
  ///
  /// In en, this message translates to:
  /// **'Cardio'**
  String get muscle_cardio;

  /// No description provided for @level_beginner.
  ///
  /// In en, this message translates to:
  /// **'Beginner'**
  String get level_beginner;

  /// No description provided for @level_intermediate.
  ///
  /// In en, this message translates to:
  /// **'Intermediate'**
  String get level_intermediate;

  /// No description provided for @level_advanced.
  ///
  /// In en, this message translates to:
  /// **'Advanced'**
  String get level_advanced;

  /// No description provided for @level_custom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get level_custom;

  /// No description provided for @equipment_bodyweight.
  ///
  /// In en, this message translates to:
  /// **'Bodyweight'**
  String get equipment_bodyweight;

  /// No description provided for @equipment_dumbbells.
  ///
  /// In en, this message translates to:
  /// **'Dumbbells'**
  String get equipment_dumbbells;

  /// No description provided for @focus_core_foundation.
  ///
  /// In en, this message translates to:
  /// **'Core Foundation'**
  String get focus_core_foundation;

  /// No description provided for @focus_upper_body_basics.
  ///
  /// In en, this message translates to:
  /// **'Upper Body Basics'**
  String get focus_upper_body_basics;

  /// No description provided for @focus_lower_body_foundation.
  ///
  /// In en, this message translates to:
  /// **'Lower Body Foundation'**
  String get focus_lower_body_foundation;

  /// No description provided for @focus_full_body_foundation.
  ///
  /// In en, this message translates to:
  /// **'Full Body Foundation'**
  String get focus_full_body_foundation;

  /// No description provided for @focus_cardio_conditioning.
  ///
  /// In en, this message translates to:
  /// **'Cardio & Conditioning'**
  String get focus_cardio_conditioning;

  /// No description provided for @focus_dynamic_core.
  ///
  /// In en, this message translates to:
  /// **'Dynamic Core'**
  String get focus_dynamic_core;

  /// No description provided for @focus_upper_body_power.
  ///
  /// In en, this message translates to:
  /// **'Upper Body Power'**
  String get focus_upper_body_power;

  /// No description provided for @focus_lower_body_strength.
  ///
  /// In en, this message translates to:
  /// **'Lower Body Strength'**
  String get focus_lower_body_strength;

  /// No description provided for @focus_full_body_conditioning.
  ///
  /// In en, this message translates to:
  /// **'Full Body Conditioning'**
  String get focus_full_body_conditioning;

  /// No description provided for @focus_cardio_endurance.
  ///
  /// In en, this message translates to:
  /// **'Cardio Endurance'**
  String get focus_cardio_endurance;

  /// No description provided for @focus_advanced_core.
  ///
  /// In en, this message translates to:
  /// **'Advanced Core'**
  String get focus_advanced_core;

  /// No description provided for @focus_upper_body_peak.
  ///
  /// In en, this message translates to:
  /// **'Upper Body Peak'**
  String get focus_upper_body_peak;

  /// No description provided for @focus_lower_body_peak.
  ///
  /// In en, this message translates to:
  /// **'Lower Body Peak'**
  String get focus_lower_body_peak;

  /// No description provided for @focus_full_body_hiit.
  ///
  /// In en, this message translates to:
  /// **'Full Body HIIT'**
  String get focus_full_body_hiit;

  /// No description provided for @focus_peak_cardio.
  ///
  /// In en, this message translates to:
  /// **'Peak Cardio'**
  String get focus_peak_cardio;

  /// No description provided for @focus_rest_day.
  ///
  /// In en, this message translates to:
  /// **'Rest Day'**
  String get focus_rest_day;

  /// No description provided for @achievement_first_steps_title.
  ///
  /// In en, this message translates to:
  /// **'First Steps'**
  String get achievement_first_steps_title;

  /// No description provided for @achievement_first_steps_desc.
  ///
  /// In en, this message translates to:
  /// **'Complete your first workout'**
  String get achievement_first_steps_desc;

  /// No description provided for @achievement_first_steps_label.
  ///
  /// In en, this message translates to:
  /// **'Workouts'**
  String get achievement_first_steps_label;

  /// No description provided for @achievement_getting_started_title.
  ///
  /// In en, this message translates to:
  /// **'Getting Started'**
  String get achievement_getting_started_title;

  /// No description provided for @achievement_getting_started_desc.
  ///
  /// In en, this message translates to:
  /// **'Complete 10 workouts'**
  String get achievement_getting_started_desc;

  /// No description provided for @achievement_getting_started_label.
  ///
  /// In en, this message translates to:
  /// **'Workouts'**
  String get achievement_getting_started_label;

  /// No description provided for @achievement_quarter_century_title.
  ///
  /// In en, this message translates to:
  /// **'Quarter Century'**
  String get achievement_quarter_century_title;

  /// No description provided for @achievement_quarter_century_desc.
  ///
  /// In en, this message translates to:
  /// **'Complete 25 workouts'**
  String get achievement_quarter_century_desc;

  /// No description provided for @achievement_quarter_century_label.
  ///
  /// In en, this message translates to:
  /// **'Workouts'**
  String get achievement_quarter_century_label;

  /// No description provided for @achievement_half_century_title.
  ///
  /// In en, this message translates to:
  /// **'Half Century'**
  String get achievement_half_century_title;

  /// No description provided for @achievement_half_century_desc.
  ///
  /// In en, this message translates to:
  /// **'Complete 50 workouts'**
  String get achievement_half_century_desc;

  /// No description provided for @achievement_half_century_label.
  ///
  /// In en, this message translates to:
  /// **'Workouts'**
  String get achievement_half_century_label;

  /// No description provided for @achievement_century_club_title.
  ///
  /// In en, this message translates to:
  /// **'Century Club'**
  String get achievement_century_club_title;

  /// No description provided for @achievement_century_club_desc.
  ///
  /// In en, this message translates to:
  /// **'Complete 100 workouts'**
  String get achievement_century_club_desc;

  /// No description provided for @achievement_century_club_label.
  ///
  /// In en, this message translates to:
  /// **'Workouts'**
  String get achievement_century_club_label;

  /// No description provided for @achievement_core_crusher_title.
  ///
  /// In en, this message translates to:
  /// **'Core Crusher'**
  String get achievement_core_crusher_title;

  /// No description provided for @achievement_core_crusher_desc.
  ///
  /// In en, this message translates to:
  /// **'Complete 10 core-focused workouts'**
  String get achievement_core_crusher_desc;

  /// No description provided for @achievement_core_crusher_label.
  ///
  /// In en, this message translates to:
  /// **'Core workouts'**
  String get achievement_core_crusher_label;

  /// No description provided for @achievement_upper_champ_title.
  ///
  /// In en, this message translates to:
  /// **'Upper Body Champ'**
  String get achievement_upper_champ_title;

  /// No description provided for @achievement_upper_champ_desc.
  ///
  /// In en, this message translates to:
  /// **'Complete 10 upper body workouts'**
  String get achievement_upper_champ_desc;

  /// No description provided for @achievement_upper_champ_label.
  ///
  /// In en, this message translates to:
  /// **'Upper body workouts'**
  String get achievement_upper_champ_label;

  /// No description provided for @achievement_lower_legend_title.
  ///
  /// In en, this message translates to:
  /// **'Lower Body Legend'**
  String get achievement_lower_legend_title;

  /// No description provided for @achievement_lower_legend_desc.
  ///
  /// In en, this message translates to:
  /// **'Complete 10 lower body workouts'**
  String get achievement_lower_legend_desc;

  /// No description provided for @achievement_lower_legend_label.
  ///
  /// In en, this message translates to:
  /// **'Lower body workouts'**
  String get achievement_lower_legend_label;

  /// No description provided for @achievement_full_fusion_title.
  ///
  /// In en, this message translates to:
  /// **'Full Body Fusion'**
  String get achievement_full_fusion_title;

  /// No description provided for @achievement_full_fusion_desc.
  ///
  /// In en, this message translates to:
  /// **'Complete 10 full body workouts'**
  String get achievement_full_fusion_desc;

  /// No description provided for @achievement_full_fusion_label.
  ///
  /// In en, this message translates to:
  /// **'Full body workouts'**
  String get achievement_full_fusion_label;

  /// No description provided for @achievement_volume_100_title.
  ///
  /// In en, this message translates to:
  /// **'Volume 100'**
  String get achievement_volume_100_title;

  /// No description provided for @achievement_volume_100_desc.
  ///
  /// In en, this message translates to:
  /// **'Complete 100 total exercise sets'**
  String get achievement_volume_100_desc;

  /// No description provided for @achievement_volume_100_label.
  ///
  /// In en, this message translates to:
  /// **'Sets'**
  String get achievement_volume_100_label;

  /// No description provided for @achievement_volume_500_title.
  ///
  /// In en, this message translates to:
  /// **'Volume 500'**
  String get achievement_volume_500_title;

  /// No description provided for @achievement_volume_500_desc.
  ///
  /// In en, this message translates to:
  /// **'Complete 500 total exercise sets'**
  String get achievement_volume_500_desc;

  /// No description provided for @achievement_volume_500_label.
  ///
  /// In en, this message translates to:
  /// **'Sets'**
  String get achievement_volume_500_label;

  /// No description provided for @achievement_volume_1k_title.
  ///
  /// In en, this message translates to:
  /// **'Volume 1K'**
  String get achievement_volume_1k_title;

  /// No description provided for @achievement_volume_1k_desc.
  ///
  /// In en, this message translates to:
  /// **'Complete 1,000 total exercise sets'**
  String get achievement_volume_1k_desc;

  /// No description provided for @achievement_volume_1k_label.
  ///
  /// In en, this message translates to:
  /// **'Sets'**
  String get achievement_volume_1k_label;

  /// No description provided for @achievement_week_warrior_title.
  ///
  /// In en, this message translates to:
  /// **'Week Warrior'**
  String get achievement_week_warrior_title;

  /// No description provided for @achievement_week_warrior_desc.
  ///
  /// In en, this message translates to:
  /// **'Complete a full week (5 workouts)'**
  String get achievement_week_warrior_desc;

  /// No description provided for @achievement_week_warrior_label.
  ///
  /// In en, this message translates to:
  /// **'Week 1 workouts'**
  String get achievement_week_warrior_label;

  /// No description provided for @achievement_dedicated_title.
  ///
  /// In en, this message translates to:
  /// **'Dedicated'**
  String get achievement_dedicated_title;

  /// No description provided for @achievement_dedicated_desc.
  ///
  /// In en, this message translates to:
  /// **'Complete 4 consecutive weeks'**
  String get achievement_dedicated_desc;

  /// No description provided for @achievement_dedicated_label.
  ///
  /// In en, this message translates to:
  /// **'Consecutive weeks'**
  String get achievement_dedicated_label;

  /// No description provided for @achievement_halfway_there_title.
  ///
  /// In en, this message translates to:
  /// **'Halfway There'**
  String get achievement_halfway_there_title;

  /// No description provided for @achievement_halfway_there_desc.
  ///
  /// In en, this message translates to:
  /// **'Complete 6 weeks'**
  String get achievement_halfway_there_desc;

  /// No description provided for @achievement_halfway_there_label.
  ///
  /// In en, this message translates to:
  /// **'Weeks completed'**
  String get achievement_halfway_there_label;

  /// No description provided for @achievement_graduate_title.
  ///
  /// In en, this message translates to:
  /// **'Program Graduate'**
  String get achievement_graduate_title;

  /// No description provided for @achievement_graduate_desc.
  ///
  /// In en, this message translates to:
  /// **'Complete all 12 weeks'**
  String get achievement_graduate_desc;

  /// No description provided for @achievement_graduate_label.
  ///
  /// In en, this message translates to:
  /// **'Weeks completed'**
  String get achievement_graduate_label;

  /// No description provided for @achievement_streak_master_title.
  ///
  /// In en, this message translates to:
  /// **'Streak Master'**
  String get achievement_streak_master_title;

  /// No description provided for @achievement_streak_master_desc.
  ///
  /// In en, this message translates to:
  /// **'Complete 5 workouts in a row'**
  String get achievement_streak_master_desc;

  /// No description provided for @achievement_streak_master_label.
  ///
  /// In en, this message translates to:
  /// **'Day streak'**
  String get achievement_streak_master_label;

  /// No description provided for @achievement_ten_thousand_title.
  ///
  /// In en, this message translates to:
  /// **'Ten Thousand'**
  String get achievement_ten_thousand_title;

  /// No description provided for @achievement_ten_thousand_desc.
  ///
  /// In en, this message translates to:
  /// **'Accumulate 10,000 total steps'**
  String get achievement_ten_thousand_desc;

  /// No description provided for @achievement_ten_thousand_label.
  ///
  /// In en, this message translates to:
  /// **'Total steps'**
  String get achievement_ten_thousand_label;

  /// No description provided for @achievement_walker_title.
  ///
  /// In en, this message translates to:
  /// **'Walker'**
  String get achievement_walker_title;

  /// No description provided for @achievement_walker_desc.
  ///
  /// In en, this message translates to:
  /// **'Accumulate 50,000 total steps'**
  String get achievement_walker_desc;

  /// No description provided for @achievement_walker_label.
  ///
  /// In en, this message translates to:
  /// **'Total steps'**
  String get achievement_walker_label;

  /// No description provided for @achievement_explorer_title.
  ///
  /// In en, this message translates to:
  /// **'Explorer'**
  String get achievement_explorer_title;

  /// No description provided for @achievement_explorer_desc.
  ///
  /// In en, this message translates to:
  /// **'Accumulate 100,000 total steps'**
  String get achievement_explorer_desc;

  /// No description provided for @achievement_explorer_label.
  ///
  /// In en, this message translates to:
  /// **'Total steps'**
  String get achievement_explorer_label;

  /// No description provided for @achievement_marathoner_title.
  ///
  /// In en, this message translates to:
  /// **'Marathoner'**
  String get achievement_marathoner_title;

  /// No description provided for @achievement_marathoner_desc.
  ///
  /// In en, this message translates to:
  /// **'Accumulate 500,000 total steps'**
  String get achievement_marathoner_desc;

  /// No description provided for @achievement_marathoner_label.
  ///
  /// In en, this message translates to:
  /// **'Total steps'**
  String get achievement_marathoner_label;

  /// No description provided for @achievement_well_hydrated_title.
  ///
  /// In en, this message translates to:
  /// **'Well Hydrated'**
  String get achievement_well_hydrated_title;

  /// No description provided for @achievement_well_hydrated_desc.
  ///
  /// In en, this message translates to:
  /// **'Consume 10 liters of water total'**
  String get achievement_well_hydrated_desc;

  /// No description provided for @achievement_well_hydrated_label.
  ///
  /// In en, this message translates to:
  /// **'Total liters'**
  String get achievement_well_hydrated_label;

  /// No description provided for @achievement_aqua_master_title.
  ///
  /// In en, this message translates to:
  /// **'Aqua Master'**
  String get achievement_aqua_master_title;

  /// No description provided for @achievement_aqua_master_desc.
  ///
  /// In en, this message translates to:
  /// **'Consume 50 liters of water total'**
  String get achievement_aqua_master_desc;

  /// No description provided for @achievement_aqua_master_label.
  ///
  /// In en, this message translates to:
  /// **'Total liters'**
  String get achievement_aqua_master_label;

  /// No description provided for @achievement_hydro_homie_title.
  ///
  /// In en, this message translates to:
  /// **'Hydro Homie'**
  String get achievement_hydro_homie_title;

  /// No description provided for @achievement_hydro_homie_desc.
  ///
  /// In en, this message translates to:
  /// **'Consume 100 liters of water total'**
  String get achievement_hydro_homie_desc;

  /// No description provided for @achievement_hydro_homie_label.
  ///
  /// In en, this message translates to:
  /// **'Total liters'**
  String get achievement_hydro_homie_label;

  /// No description provided for @achievement_starting_point_title.
  ///
  /// In en, this message translates to:
  /// **'Starting Point'**
  String get achievement_starting_point_title;

  /// No description provided for @achievement_starting_point_desc.
  ///
  /// In en, this message translates to:
  /// **'Log your first weight entry'**
  String get achievement_starting_point_desc;

  /// No description provided for @achievement_starting_point_label.
  ///
  /// In en, this message translates to:
  /// **'Weight entries'**
  String get achievement_starting_point_label;

  /// No description provided for @achievement_consistent_logger_title.
  ///
  /// In en, this message translates to:
  /// **'Consistent Logger'**
  String get achievement_consistent_logger_title;

  /// No description provided for @achievement_consistent_logger_desc.
  ///
  /// In en, this message translates to:
  /// **'Log weight 7 times'**
  String get achievement_consistent_logger_desc;

  /// No description provided for @achievement_consistent_logger_label.
  ///
  /// In en, this message translates to:
  /// **'Weight logs'**
  String get achievement_consistent_logger_label;

  /// No description provided for @achievement_goal_setter_title.
  ///
  /// In en, this message translates to:
  /// **'Goal Setter'**
  String get achievement_goal_setter_title;

  /// No description provided for @achievement_goal_setter_desc.
  ///
  /// In en, this message translates to:
  /// **'Set a weight goal'**
  String get achievement_goal_setter_desc;

  /// No description provided for @achievement_goal_setter_label.
  ///
  /// In en, this message translates to:
  /// **'Goal set'**
  String get achievement_goal_setter_label;

  /// No description provided for @achievement_who_am_i_title.
  ///
  /// In en, this message translates to:
  /// **'Who Am I?'**
  String get achievement_who_am_i_title;

  /// No description provided for @achievement_who_am_i_desc.
  ///
  /// In en, this message translates to:
  /// **'Fill in all profile fields'**
  String get achievement_who_am_i_desc;

  /// No description provided for @achievement_who_am_i_label.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get achievement_who_am_i_label;

  /// No description provided for @achievement_early_bird_title.
  ///
  /// In en, this message translates to:
  /// **'Early Bird'**
  String get achievement_early_bird_title;

  /// No description provided for @achievement_early_bird_desc.
  ///
  /// In en, this message translates to:
  /// **'Complete 5 workouts before 8 AM'**
  String get achievement_early_bird_desc;

  /// No description provided for @achievement_early_bird_label.
  ///
  /// In en, this message translates to:
  /// **'Early workouts'**
  String get achievement_early_bird_label;

  /// No description provided for @achievement_night_owl_title.
  ///
  /// In en, this message translates to:
  /// **'Night Owl'**
  String get achievement_night_owl_title;

  /// No description provided for @achievement_night_owl_desc.
  ///
  /// In en, this message translates to:
  /// **'Complete 5 workouts after 9 PM'**
  String get achievement_night_owl_desc;

  /// No description provided for @achievement_night_owl_label.
  ///
  /// In en, this message translates to:
  /// **'Late workouts'**
  String get achievement_night_owl_label;

  /// No description provided for @notif_title.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notif_title;

  /// No description provided for @notif_on.
  ///
  /// In en, this message translates to:
  /// **'On'**
  String get notif_on;

  /// No description provided for @notif_off.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get notif_off;

  /// No description provided for @notif_done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get notif_done;

  /// No description provided for @notif_save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get notif_save;

  /// No description provided for @notif_cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get notif_cancel;

  /// No description provided for @notif_test.
  ///
  /// In en, this message translates to:
  /// **'Test Notification'**
  String get notif_test;

  /// No description provided for @notif_testSent.
  ///
  /// In en, this message translates to:
  /// **'Test notification sent. Check your notification tray.'**
  String get notif_testSent;

  /// No description provided for @notif_pause.
  ///
  /// In en, this message translates to:
  /// **'Pause Notifications'**
  String get notif_pause;

  /// No description provided for @notif_resume.
  ///
  /// In en, this message translates to:
  /// **'Resume Notifications'**
  String get notif_resume;

  /// No description provided for @notif_paused.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get notif_paused;

  /// No description provided for @notif_active.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get notif_active;

  /// No description provided for @notif_remaining.
  ///
  /// In en, this message translates to:
  /// **'remaining'**
  String get notif_remaining;

  /// No description provided for @notif_workoutReminders.
  ///
  /// In en, this message translates to:
  /// **'Workout Reminders'**
  String get notif_workoutReminders;

  /// No description provided for @notif_progressStats.
  ///
  /// In en, this message translates to:
  /// **'Progress & Stats'**
  String get notif_progressStats;

  /// No description provided for @notif_dailyReminder.
  ///
  /// In en, this message translates to:
  /// **'Daily Workout Reminder'**
  String get notif_dailyReminder;

  /// No description provided for @notif_dailyReminderSub.
  ///
  /// In en, this message translates to:
  /// **'Remind me to work out daily'**
  String get notif_dailyReminderSub;

  /// No description provided for @notif_dailyReminderConfigTitle.
  ///
  /// In en, this message translates to:
  /// **'Daily Reminder'**
  String get notif_dailyReminderConfigTitle;

  /// No description provided for @notif_dailyReminderConfigBody.
  ///
  /// In en, this message translates to:
  /// **'What time should I remind you\nto work out?'**
  String get notif_dailyReminderConfigBody;

  /// No description provided for @notif_tapToChange.
  ///
  /// In en, this message translates to:
  /// **'Tap to change'**
  String get notif_tapToChange;

  /// No description provided for @notif_missedWorkout.
  ///
  /// In en, this message translates to:
  /// **'Missed Workout Reminder'**
  String get notif_missedWorkout;

  /// No description provided for @notif_missedWorkoutSub.
  ///
  /// In en, this message translates to:
  /// **'Nudge me after a missed workout'**
  String get notif_missedWorkoutSub;

  /// No description provided for @notif_missedWorkoutConfigTitle.
  ///
  /// In en, this message translates to:
  /// **'Missed Workout'**
  String get notif_missedWorkoutConfigTitle;

  /// No description provided for @notif_missedWorkoutConfigHeader.
  ///
  /// In en, this message translates to:
  /// **'Get a gentle nudge when you miss a workout.'**
  String get notif_missedWorkoutConfigHeader;

  /// No description provided for @notif_waitTime.
  ///
  /// In en, this message translates to:
  /// **'Wait time after missed workout'**
  String get notif_waitTime;

  /// No description provided for @notif_waitTimeDesc.
  ///
  /// In en, this message translates to:
  /// **'How long to wait before sending a reminder'**
  String get notif_waitTimeDesc;

  /// No description provided for @notif_achievementNotif.
  ///
  /// In en, this message translates to:
  /// **'Achievement Notification'**
  String get notif_achievementNotif;

  /// No description provided for @notif_achievementNotifSub.
  ///
  /// In en, this message translates to:
  /// **'Celebrate my achievements'**
  String get notif_achievementNotifSub;

  /// No description provided for @notif_recovery.
  ///
  /// In en, this message translates to:
  /// **'Recovery Suggestion'**
  String get notif_recovery;

  /// No description provided for @notif_recoverySub.
  ///
  /// In en, this message translates to:
  /// **'Suggest rest after consecutive days'**
  String get notif_recoverySub;

  /// No description provided for @notif_weeklyProgress.
  ///
  /// In en, this message translates to:
  /// **'Weekly Progress'**
  String get notif_weeklyProgress;

  /// No description provided for @notif_weeklyProgressSub.
  ///
  /// In en, this message translates to:
  /// **'Weekly summary of my stats'**
  String get notif_weeklyProgressSub;

  /// No description provided for @notif_weeklyProgressConfigTitle.
  ///
  /// In en, this message translates to:
  /// **'Weekly Progress'**
  String get notif_weeklyProgressConfigTitle;

  /// No description provided for @notif_weeklyProgressConfigHeader.
  ///
  /// In en, this message translates to:
  /// **'Choose which day you\'d like to receive\nyour weekly progress summary.'**
  String get notif_weeklyProgressConfigHeader;

  /// No description provided for @notif_weightFollowUp.
  ///
  /// In en, this message translates to:
  /// **'Weight Follow-Up'**
  String get notif_weightFollowUp;

  /// No description provided for @notif_weightFollowUpSub.
  ///
  /// In en, this message translates to:
  /// **'Remind me to log my weight'**
  String get notif_weightFollowUpSub;

  /// No description provided for @notif_weightConfigTitle.
  ///
  /// In en, this message translates to:
  /// **'Weight Follow-Up'**
  String get notif_weightConfigTitle;

  /// No description provided for @notif_weightConfigHeader.
  ///
  /// In en, this message translates to:
  /// **'Remind yourself to log your weight regularly and track toward your goal.'**
  String get notif_weightConfigHeader;

  /// No description provided for @notif_targetWeight.
  ///
  /// In en, this message translates to:
  /// **'Target Weight'**
  String get notif_targetWeight;

  /// No description provided for @notif_remindEvery.
  ///
  /// In en, this message translates to:
  /// **'Remind me every…'**
  String get notif_remindEvery;

  /// No description provided for @notif_quietHours.
  ///
  /// In en, this message translates to:
  /// **'Quiet Hours'**
  String get notif_quietHours;

  /// No description provided for @notif_quietHoursSub.
  ///
  /// In en, this message translates to:
  /// **'Suppress notifications during specified hours'**
  String get notif_quietHoursSub;

  /// No description provided for @notif_quietHoursConfigTitle.
  ///
  /// In en, this message translates to:
  /// **'Quiet Hours'**
  String get notif_quietHoursConfigTitle;

  /// No description provided for @notif_quietHoursDesc.
  ///
  /// In en, this message translates to:
  /// **'Notifications will be suppressed between start and end time.'**
  String get notif_quietHoursDesc;

  /// No description provided for @notif_startTime.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get notif_startTime;

  /// No description provided for @notif_endTime.
  ///
  /// In en, this message translates to:
  /// **'End'**
  String get notif_endTime;

  /// No description provided for @notif_dailyBody.
  ///
  /// In en, this message translates to:
  /// **'Ready to crush it 💪'**
  String get notif_dailyBody;

  /// No description provided for @notif_missedBody.
  ///
  /// In en, this message translates to:
  /// **'You missed your workout today. Time to get back on track!'**
  String get notif_missedBody;

  /// No description provided for @notif_recoveryBody.
  ///
  /// In en, this message translates to:
  /// **'You may benefit from a recovery day.'**
  String get notif_recoveryBody;

  /// No description provided for @notif_restCompleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Rest Complete'**
  String get notif_restCompleteTitle;

  /// No description provided for @notif_restCompleteBody.
  ///
  /// In en, this message translates to:
  /// **'Rest complete. Start next set.'**
  String get notif_restCompleteBody;

  /// No description provided for @general_saveError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save workout. Please try again.'**
  String get general_saveError;

  /// No description provided for @general_saved.
  ///
  /// In en, this message translates to:
  /// **'Saved!'**
  String get general_saved;

  /// No description provided for @general_loading.
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get general_loading;

  /// No description provided for @celebration_workoutComplete.
  ///
  /// In en, this message translates to:
  /// **'Workout Complete!'**
  String get celebration_workoutComplete;

  /// No description provided for @weekday_monday_abbr.
  ///
  /// In en, this message translates to:
  /// **'Mo'**
  String get weekday_monday_abbr;

  /// No description provided for @weekday_tuesday_abbr.
  ///
  /// In en, this message translates to:
  /// **'Tu'**
  String get weekday_tuesday_abbr;

  /// No description provided for @weekday_wednesday_abbr.
  ///
  /// In en, this message translates to:
  /// **'We'**
  String get weekday_wednesday_abbr;

  /// No description provided for @weekday_thursday_abbr.
  ///
  /// In en, this message translates to:
  /// **'Th'**
  String get weekday_thursday_abbr;

  /// No description provided for @weekday_friday_abbr.
  ///
  /// In en, this message translates to:
  /// **'Fr'**
  String get weekday_friday_abbr;

  /// No description provided for @weekday_saturday_abbr.
  ///
  /// In en, this message translates to:
  /// **'Sa'**
  String get weekday_saturday_abbr;

  /// No description provided for @weekday_sunday_abbr.
  ///
  /// In en, this message translates to:
  /// **'Su'**
  String get weekday_sunday_abbr;

  /// No description provided for @dialog_changePhoto.
  ///
  /// In en, this message translates to:
  /// **'Change Photo'**
  String get dialog_changePhoto;

  /// No description provided for @dialog_camera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get dialog_camera;

  /// No description provided for @dialog_gallery.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get dialog_gallery;

  /// No description provided for @dialog_removePhoto.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get dialog_removePhoto;

  /// No description provided for @dialog_unsavedChanges.
  ///
  /// In en, this message translates to:
  /// **'Unsaved Changes'**
  String get dialog_unsavedChanges;

  /// No description provided for @dialog_unsavedChangesBody.
  ///
  /// In en, this message translates to:
  /// **'You have unsaved changes. Discard them?'**
  String get dialog_unsavedChangesBody;

  /// No description provided for @dialog_keepEditing.
  ///
  /// In en, this message translates to:
  /// **'Keep Editing'**
  String get dialog_keepEditing;

  /// No description provided for @dialog_discard.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get dialog_discard;

  /// No description provided for @dialog_fullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get dialog_fullName;

  /// No description provided for @dialog_enterNameHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your name'**
  String get dialog_enterNameHint;

  /// No description provided for @dialog_dateOfBirth.
  ///
  /// In en, this message translates to:
  /// **'Date of Birth'**
  String get dialog_dateOfBirth;

  /// No description provided for @dialog_tapToSelect.
  ///
  /// In en, this message translates to:
  /// **'Tap to select'**
  String get dialog_tapToSelect;

  /// No description provided for @dialog_ageDisplay.
  ///
  /// In en, this message translates to:
  /// **'Age: {age}'**
  String dialog_ageDisplay(int age);

  /// No description provided for @dialog_weight.
  ///
  /// In en, this message translates to:
  /// **'Weight'**
  String get dialog_weight;

  /// No description provided for @dialog_weightHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 70'**
  String get dialog_weightHint;

  /// No description provided for @dialog_weightRange.
  ///
  /// In en, this message translates to:
  /// **'Enter 20–300 kg'**
  String get dialog_weightRange;

  /// No description provided for @dialog_height.
  ///
  /// In en, this message translates to:
  /// **'Height'**
  String get dialog_height;

  /// No description provided for @dialog_heightHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 175'**
  String get dialog_heightHint;

  /// No description provided for @dialog_heightRange.
  ///
  /// In en, this message translates to:
  /// **'Enter 50–250 cm'**
  String get dialog_heightRange;

  /// No description provided for @dialog_bodyMassIndex.
  ///
  /// In en, this message translates to:
  /// **'Body Mass Index'**
  String get dialog_bodyMassIndex;

  /// No description provided for @dialog_underweight.
  ///
  /// In en, this message translates to:
  /// **'Underweight'**
  String get dialog_underweight;

  /// No description provided for @dialog_normal.
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get dialog_normal;

  /// No description provided for @dialog_overweight.
  ///
  /// In en, this message translates to:
  /// **'Overweight'**
  String get dialog_overweight;

  /// No description provided for @dialog_obese.
  ///
  /// In en, this message translates to:
  /// **'Obese'**
  String get dialog_obese;

  /// No description provided for @dialog_gender.
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get dialog_gender;

  /// No description provided for @dialog_male.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get dialog_male;

  /// No description provided for @dialog_female.
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get dialog_female;

  /// No description provided for @dialog_otherGender.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get dialog_otherGender;

  /// No description provided for @dialog_saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get dialog_saveChanges;

  /// No description provided for @dialog_required.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get dialog_required;

  /// No description provided for @dialog_enterValidName.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid name'**
  String get dialog_enterValidName;

  /// No description provided for @dialog_enterValidEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email'**
  String get dialog_enterValidEmail;

  /// No description provided for @dialog_enterNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter a number'**
  String get dialog_enterNumber;

  /// No description provided for @dialog_minAgeError.
  ///
  /// In en, this message translates to:
  /// **'You must be at least 10 years old'**
  String get dialog_minAgeError;

  /// No description provided for @dialog_verifyDob.
  ///
  /// In en, this message translates to:
  /// **'Please verify your date of birth'**
  String get dialog_verifyDob;

  /// No description provided for @dialog_failedToSave.
  ///
  /// In en, this message translates to:
  /// **'Failed to save: {error}'**
  String dialog_failedToSave(String error);

  /// No description provided for @dialog_setOfSemantics.
  ///
  /// In en, this message translates to:
  /// **'Set {current} of {total}'**
  String dialog_setOfSemantics(int current, int total);

  /// No description provided for @dialog_ofTotal.
  ///
  /// In en, this message translates to:
  /// **'of {total}'**
  String dialog_ofTotal(int total);

  /// No description provided for @dialog_setLabel.
  ///
  /// In en, this message translates to:
  /// **'Set {number}'**
  String dialog_setLabel(int number);

  /// No description provided for @dialog_secondsHold.
  ///
  /// In en, this message translates to:
  /// **'{seconds}s hold'**
  String dialog_secondsHold(int seconds);

  /// No description provided for @dialog_repsCount.
  ///
  /// In en, this message translates to:
  /// **'{reps} reps'**
  String dialog_repsCount(int reps);

  /// No description provided for @dialog_weightKgLabel.
  ///
  /// In en, this message translates to:
  /// **'{weight} kg'**
  String dialog_weightKgLabel(double weight);

  /// No description provided for @dialog_startSet.
  ///
  /// In en, this message translates to:
  /// **'Start Set {number}'**
  String dialog_startSet(int number);

  /// No description provided for @dialog_completeSet.
  ///
  /// In en, this message translates to:
  /// **'Complete Set'**
  String get dialog_completeSet;

  /// No description provided for @dialog_hold.
  ///
  /// In en, this message translates to:
  /// **'Hold'**
  String get dialog_hold;

  /// No description provided for @dialog_skipHold.
  ///
  /// In en, this message translates to:
  /// **'Skip Hold'**
  String get dialog_skipHold;

  /// No description provided for @dialog_rest.
  ///
  /// In en, this message translates to:
  /// **'Rest'**
  String get dialog_rest;

  /// No description provided for @dialog_allSetsDone.
  ///
  /// In en, this message translates to:
  /// **'All Sets Done!'**
  String get dialog_allSetsDone;

  /// No description provided for @dialog_greatWork.
  ///
  /// In en, this message translates to:
  /// **'Great work!'**
  String get dialog_greatWork;

  /// No description provided for @dialog_backToWorkout.
  ///
  /// In en, this message translates to:
  /// **'Back to Workout'**
  String get dialog_backToWorkout;

  /// No description provided for @dialog_endWorkout.
  ///
  /// In en, this message translates to:
  /// **'End Workout'**
  String get dialog_endWorkout;

  /// No description provided for @dialog_endWorkoutTitle.
  ///
  /// In en, this message translates to:
  /// **'End Workout?'**
  String get dialog_endWorkoutTitle;

  /// No description provided for @dialog_endWorkoutBody.
  ///
  /// In en, this message translates to:
  /// **'You’ve completed {current} of {total} sets.'**
  String dialog_endWorkoutBody(int current, int total);

  /// No description provided for @dialog_restTimerActive.
  ///
  /// In en, this message translates to:
  /// **'Rest timer is active.'**
  String get dialog_restTimerActive;

  /// No description provided for @dialog_equipment.
  ///
  /// In en, this message translates to:
  /// **'Equipment: {equipment}'**
  String dialog_equipment(String equipment);

  /// No description provided for @dialog_watchOnYoutube.
  ///
  /// In en, this message translates to:
  /// **'Watch on YouTube'**
  String get dialog_watchOnYoutube;

  /// No description provided for @dialog_setTargetWeight.
  ///
  /// In en, this message translates to:
  /// **'Set Target Weight'**
  String get dialog_setTargetWeight;

  /// No description provided for @dialog_setGoal.
  ///
  /// In en, this message translates to:
  /// **'Set Goal'**
  String get dialog_setGoal;

  /// No description provided for @dialog_saveWeight.
  ///
  /// In en, this message translates to:
  /// **'Save Weight'**
  String get dialog_saveWeight;

  /// No description provided for @dialog_saving.
  ///
  /// In en, this message translates to:
  /// **'Saving…'**
  String get dialog_saving;

  /// No description provided for @dialog_recordWeightSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Record your weight for today'**
  String get dialog_recordWeightSubtitle;

  /// No description provided for @dialog_today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get dialog_today;

  /// No description provided for @dialog_setTargetWeightLink.
  ///
  /// In en, this message translates to:
  /// **'Set target weight'**
  String get dialog_setTargetWeightLink;

  /// No description provided for @dialog_allFilter.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get dialog_allFilter;

  /// No description provided for @dialog_noAchievements.
  ///
  /// In en, this message translates to:
  /// **'No achievements in this category'**
  String get dialog_noAchievements;

  /// No description provided for @dialog_12WeekProgram.
  ///
  /// In en, this message translates to:
  /// **'12-Week Program'**
  String get dialog_12WeekProgram;

  /// No description provided for @dialog_weekDayDisplay.
  ///
  /// In en, this message translates to:
  /// **'Week {week} — Day {day}'**
  String dialog_weekDayDisplay(int week, int day);

  /// No description provided for @dialog_workoutsLabel.
  ///
  /// In en, this message translates to:
  /// **'workouts'**
  String get dialog_workoutsLabel;

  /// No description provided for @dialog_foundationPhase.
  ///
  /// In en, this message translates to:
  /// **'Foundation Phase'**
  String get dialog_foundationPhase;

  /// No description provided for @dialog_buildingPhase.
  ///
  /// In en, this message translates to:
  /// **'Building Phase'**
  String get dialog_buildingPhase;

  /// No description provided for @dialog_peakPhase.
  ///
  /// In en, this message translates to:
  /// **'Peak Phase'**
  String get dialog_peakPhase;

  /// No description provided for @dialog_foundation.
  ///
  /// In en, this message translates to:
  /// **'Foundation'**
  String get dialog_foundation;

  /// No description provided for @dialog_building.
  ///
  /// In en, this message translates to:
  /// **'Building'**
  String get dialog_building;

  /// No description provided for @dialog_peak.
  ///
  /// In en, this message translates to:
  /// **'Peak'**
  String get dialog_peak;

  /// No description provided for @dialog_weekLabel.
  ///
  /// In en, this message translates to:
  /// **'Week {week}'**
  String dialog_weekLabel(int week);

  /// No description provided for @dialog_current.
  ///
  /// In en, this message translates to:
  /// **'Current'**
  String get dialog_current;

  /// No description provided for @notif_hydrationReminder.
  ///
  /// In en, this message translates to:
  /// **'Hydration Reminder'**
  String get notif_hydrationReminder;

  /// No description provided for @notif_hydrationReminderSub.
  ///
  /// In en, this message translates to:
  /// **'Get reminded to drink water throughout the day'**
  String get notif_hydrationReminderSub;

  /// No description provided for @notif_hydrationReminderConfigTitle.
  ///
  /// In en, this message translates to:
  /// **'Hydration Reminder'**
  String get notif_hydrationReminderConfigTitle;

  /// No description provided for @notif_hydrationReminderConfigBody.
  ///
  /// In en, this message translates to:
  /// **'Configure your hydration reminder settings'**
  String get notif_hydrationReminderConfigBody;

  /// No description provided for @notif_hydrationEnable.
  ///
  /// In en, this message translates to:
  /// **'Enable Hydration Reminder'**
  String get notif_hydrationEnable;

  /// No description provided for @notif_hydrationEnableSub.
  ///
  /// In en, this message translates to:
  /// **'Receive periodic reminders to stay hydrated'**
  String get notif_hydrationEnableSub;

  /// No description provided for @notif_hydrationInterval.
  ///
  /// In en, this message translates to:
  /// **'Reminder Interval'**
  String get notif_hydrationInterval;

  /// No description provided for @notif_hydrationActiveHours.
  ///
  /// In en, this message translates to:
  /// **'Active Hours'**
  String get notif_hydrationActiveHours;

  /// No description provided for @notif_hydrationRemindersPerDay.
  ///
  /// In en, this message translates to:
  /// **'Reminders per day'**
  String get notif_hydrationRemindersPerDay;

  /// No description provided for @notif_hydrationAmountPerReminder.
  ///
  /// In en, this message translates to:
  /// **'Amount per reminder'**
  String get notif_hydrationAmountPerReminder;

  /// No description provided for @notif_hydrationBasedOnGoal.
  ///
  /// In en, this message translates to:
  /// **'Based on your {goal}L daily goal'**
  String notif_hydrationBasedOnGoal(String goal);

  /// No description provided for @notif_hydrationMessage.
  ///
  /// In en, this message translates to:
  /// **'Time to hydrate! Drink ~{amount}mL to stay on track 💧'**
  String notif_hydrationMessage(int amount);

  /// No description provided for @notif_enableAchievement.
  ///
  /// In en, this message translates to:
  /// **'Enable Achievement Notifications'**
  String get notif_enableAchievement;

  /// No description provided for @notif_enableAchievementSub.
  ///
  /// In en, this message translates to:
  /// **'Get notified when you unlock a new achievement'**
  String get notif_enableAchievementSub;

  /// No description provided for @notif_enableRecovery.
  ///
  /// In en, this message translates to:
  /// **'Enable Recovery Suggestions'**
  String get notif_enableRecovery;

  /// No description provided for @notif_enableRecoverySub.
  ///
  /// In en, this message translates to:
  /// **'Get reminded to take rest days after consecutive workouts'**
  String get notif_enableRecoverySub;

  /// No description provided for @notif_enableQuietHours.
  ///
  /// In en, this message translates to:
  /// **'Enable Quiet Hours'**
  String get notif_enableQuietHours;

  /// No description provided for @notif_chooseStartTime.
  ///
  /// In en, this message translates to:
  /// **'Choose start time'**
  String get notif_chooseStartTime;

  /// No description provided for @notif_chooseEndTime.
  ///
  /// In en, this message translates to:
  /// **'Choose end time'**
  String get notif_chooseEndTime;

  /// No description provided for @notif_enableDailyReminder.
  ///
  /// In en, this message translates to:
  /// **'Enable Daily Reminder'**
  String get notif_enableDailyReminder;

  /// No description provided for @notif_enableDailyReminderSub.
  ///
  /// In en, this message translates to:
  /// **'Receive a daily reminder to complete your workout'**
  String get notif_enableDailyReminderSub;

  /// No description provided for @notif_enableMissedWorkout.
  ///
  /// In en, this message translates to:
  /// **'Enable Missed Workout Reminder'**
  String get notif_enableMissedWorkout;

  /// No description provided for @notif_enableMissedWorkoutSub.
  ///
  /// In en, this message translates to:
  /// **'Get a nudge when you miss a workout'**
  String get notif_enableMissedWorkoutSub;

  /// No description provided for @notif_hour.
  ///
  /// In en, this message translates to:
  /// **'hour'**
  String get notif_hour;

  /// No description provided for @notif_hours.
  ///
  /// In en, this message translates to:
  /// **'hours'**
  String get notif_hours;

  /// No description provided for @notif_day.
  ///
  /// In en, this message translates to:
  /// **'day'**
  String get notif_day;

  /// No description provided for @notif_confirmTurnOff.
  ///
  /// In en, this message translates to:
  /// **'Turn off all notifications?'**
  String get notif_confirmTurnOff;

  /// No description provided for @notif_confirmTurnOffBody.
  ///
  /// In en, this message translates to:
  /// **'You won\'t receive any workout reminders, achievements, or progress updates.'**
  String get notif_confirmTurnOffBody;

  /// No description provided for @notif_keepEnabled.
  ///
  /// In en, this message translates to:
  /// **'Keep On'**
  String get notif_keepEnabled;

  /// No description provided for @notif_turnOff.
  ///
  /// In en, this message translates to:
  /// **'Turn Off'**
  String get notif_turnOff;

  /// No description provided for @notif_nextScheduled.
  ///
  /// In en, this message translates to:
  /// **'Next: {time}'**
  String notif_nextScheduled(String time);

  /// No description provided for @notif_weekdayMonday.
  ///
  /// In en, this message translates to:
  /// **'Monday'**
  String get notif_weekdayMonday;

  /// No description provided for @notif_weekdayTuesday.
  ///
  /// In en, this message translates to:
  /// **'Tuesday'**
  String get notif_weekdayTuesday;

  /// No description provided for @notif_weekdayWednesday.
  ///
  /// In en, this message translates to:
  /// **'Wednesday'**
  String get notif_weekdayWednesday;

  /// No description provided for @notif_weekdayThursday.
  ///
  /// In en, this message translates to:
  /// **'Thursday'**
  String get notif_weekdayThursday;

  /// No description provided for @notif_weekdayFriday.
  ///
  /// In en, this message translates to:
  /// **'Friday'**
  String get notif_weekdayFriday;

  /// No description provided for @notif_weekdaySaturday.
  ///
  /// In en, this message translates to:
  /// **'Saturday'**
  String get notif_weekdaySaturday;

  /// No description provided for @notif_weekdaySunday.
  ///
  /// In en, this message translates to:
  /// **'Sunday'**
  String get notif_weekdaySunday;

  /// No description provided for @notif_chooseDay.
  ///
  /// In en, this message translates to:
  /// **'Choose day'**
  String get notif_chooseDay;

  /// No description provided for @notif_notificationTime.
  ///
  /// In en, this message translates to:
  /// **'Notification time'**
  String get notif_notificationTime;

  /// No description provided for @notif_slideToSetWeight.
  ///
  /// In en, this message translates to:
  /// **'Slide to set your target weight'**
  String get notif_slideToSetWeight;

  /// No description provided for @notif_weightGoalQuestion.
  ///
  /// In en, this message translates to:
  /// **'What weight are you working toward?'**
  String get notif_weightGoalQuestion;

  /// No description provided for @notif_frequencyQuestion.
  ///
  /// In en, this message translates to:
  /// **'How often to ask you to log your weight'**
  String get notif_frequencyQuestion;

  /// No description provided for @notif_everyDay.
  ///
  /// In en, this message translates to:
  /// **'Every day'**
  String get notif_everyDay;

  /// No description provided for @notif_weekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get notif_weekly;

  /// No description provided for @notif_every2Weeks.
  ///
  /// In en, this message translates to:
  /// **'Every 2 weeks'**
  String get notif_every2Weeks;

  /// No description provided for @notif_everyNDays.
  ///
  /// In en, this message translates to:
  /// **'Every {days} days'**
  String notif_everyNDays(int days);

  /// No description provided for @notif_kilograms.
  ///
  /// In en, this message translates to:
  /// **'Kilograms'**
  String get notif_kilograms;

  /// No description provided for @notif_pounds.
  ///
  /// In en, this message translates to:
  /// **'Pounds'**
  String get notif_pounds;

  /// No description provided for @helpFeedback_title.
  ///
  /// In en, this message translates to:
  /// **'Help & Feedback'**
  String get helpFeedback_title;

  /// No description provided for @helpFeedback_helpTab.
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get helpFeedback_helpTab;

  /// No description provided for @helpFeedback_feedbackTab.
  ///
  /// In en, this message translates to:
  /// **'Feedback'**
  String get helpFeedback_feedbackTab;

  /// No description provided for @helpFeedback_faq.
  ///
  /// In en, this message translates to:
  /// **'Frequently Asked Questions'**
  String get helpFeedback_faq;

  /// No description provided for @helpFeedback_faqSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Quick answers to common questions'**
  String get helpFeedback_faqSubtitle;

  /// No description provided for @helpFeedback_quickLinks.
  ///
  /// In en, this message translates to:
  /// **'Quick Links'**
  String get helpFeedback_quickLinks;

  /// No description provided for @home_kGoal.
  ///
  /// In en, this message translates to:
  /// **'{count}k goal'**
  String home_kGoal(int count);

  /// No description provided for @home_kLabel.
  ///
  /// In en, this message translates to:
  /// **'{count}k'**
  String home_kLabel(int count);

  /// No description provided for @home_km.
  ///
  /// In en, this message translates to:
  /// **'{distance} km'**
  String home_km(String distance);

  /// No description provided for @home_kcal.
  ///
  /// In en, this message translates to:
  /// **'{calories} kcal'**
  String home_kcal(String calories);

  /// No description provided for @home_tapToAdd.
  ///
  /// In en, this message translates to:
  /// **'Tap to add'**
  String get home_tapToAdd;

  /// No description provided for @home_tapToRecord.
  ///
  /// In en, this message translates to:
  /// **'Tap to record'**
  String get home_tapToRecord;

  /// No description provided for @home_loggedToday.
  ///
  /// In en, this message translates to:
  /// **'Logged today'**
  String get home_loggedToday;

  /// No description provided for @home_loggedYesterday.
  ///
  /// In en, this message translates to:
  /// **'Logged yesterday'**
  String get home_loggedYesterday;

  /// No description provided for @home_loggedDaysAgo.
  ///
  /// In en, this message translates to:
  /// **'{count} days ago'**
  String home_loggedDaysAgo(int count);

  /// No description provided for @home_workoutsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} workouts'**
  String home_workoutsCount(int count);

  /// No description provided for @helpFeedback_exerciseGuide.
  ///
  /// In en, this message translates to:
  /// **'Exercise Guide'**
  String get helpFeedback_exerciseGuide;

  /// No description provided for @helpFeedback_exerciseGuideDesc.
  ///
  /// In en, this message translates to:
  /// **'Browse exercises with form tips and videos'**
  String get helpFeedback_exerciseGuideDesc;

  /// No description provided for @helpFeedback_changelog.
  ///
  /// In en, this message translates to:
  /// **'What\'s New'**
  String get helpFeedback_changelog;

  /// No description provided for @helpFeedback_changelogDesc.
  ///
  /// In en, this message translates to:
  /// **'See the latest updates and improvements'**
  String get helpFeedback_changelogDesc;

  /// No description provided for @helpFeedback_notificationTips.
  ///
  /// In en, this message translates to:
  /// **'Notification Tips'**
  String get helpFeedback_notificationTips;

  /// No description provided for @helpFeedback_notificationTipsDesc.
  ///
  /// In en, this message translates to:
  /// **'Configure reminders to stay on track'**
  String get helpFeedback_notificationTipsDesc;

  /// No description provided for @helpFeedback_tips.
  ///
  /// In en, this message translates to:
  /// **'Tips & Tricks'**
  String get helpFeedback_tips;

  /// No description provided for @helpFeedback_tipsDesc.
  ///
  /// In en, this message translates to:
  /// **'Science-backed advice for your fitness journey'**
  String get helpFeedback_tipsDesc;

  /// No description provided for @helpFeedback_category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get helpFeedback_category;

  /// No description provided for @helpFeedback_bugReport.
  ///
  /// In en, this message translates to:
  /// **'Bug Report'**
  String get helpFeedback_bugReport;

  /// No description provided for @helpFeedback_featureRequest.
  ///
  /// In en, this message translates to:
  /// **'Feature Request'**
  String get helpFeedback_featureRequest;

  /// No description provided for @helpFeedback_generalFeedback.
  ///
  /// In en, this message translates to:
  /// **'General Feedback'**
  String get helpFeedback_generalFeedback;

  /// No description provided for @helpFeedback_question.
  ///
  /// In en, this message translates to:
  /// **'Question'**
  String get helpFeedback_question;

  /// No description provided for @helpFeedback_name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get helpFeedback_name;

  /// No description provided for @helpFeedback_nameHint.
  ///
  /// In en, this message translates to:
  /// **'Your name'**
  String get helpFeedback_nameHint;

  /// No description provided for @helpFeedback_email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get helpFeedback_email;

  /// No description provided for @helpFeedback_emailHint.
  ///
  /// In en, this message translates to:
  /// **'your@email.com'**
  String get helpFeedback_emailHint;

  /// No description provided for @helpFeedback_subject.
  ///
  /// In en, this message translates to:
  /// **'Subject'**
  String get helpFeedback_subject;

  /// No description provided for @helpFeedback_subjectHint.
  ///
  /// In en, this message translates to:
  /// **'Brief summary'**
  String get helpFeedback_subjectHint;

  /// No description provided for @helpFeedback_message.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get helpFeedback_message;

  /// No description provided for @helpFeedback_messageHint.
  ///
  /// In en, this message translates to:
  /// **'Tell us what you think…'**
  String get helpFeedback_messageHint;

  /// No description provided for @helpFeedback_sendViaWhatsapp.
  ///
  /// In en, this message translates to:
  /// **'Send via WhatsApp'**
  String get helpFeedback_sendViaWhatsapp;

  /// No description provided for @helpFeedback_sending.
  ///
  /// In en, this message translates to:
  /// **'Opening WhatsApp…'**
  String get helpFeedback_sending;

  /// No description provided for @helpFeedback_success.
  ///
  /// In en, this message translates to:
  /// **'Draft opened in WhatsApp! Thanks for helping us improve.'**
  String get helpFeedback_success;

  /// No description provided for @helpFeedback_required.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get helpFeedback_required;

  /// No description provided for @helpFeedback_minLength.
  ///
  /// In en, this message translates to:
  /// **'Minimum {count} characters'**
  String helpFeedback_minLength(Object count);

  /// No description provided for @helpFeedback_enterValidEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email'**
  String get helpFeedback_enterValidEmail;

  /// No description provided for @helpFeedback_attachScreenshot.
  ///
  /// In en, this message translates to:
  /// **'Attach Screenshot'**
  String get helpFeedback_attachScreenshot;

  /// No description provided for @helpFeedback_removeScreenshot.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get helpFeedback_removeScreenshot;

  /// No description provided for @helpFeedback_openInWhatsapp.
  ///
  /// In en, this message translates to:
  /// **'Open in WhatsApp'**
  String get helpFeedback_openInWhatsapp;

  /// No description provided for @helpFeedback_whatsappFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not open WhatsApp. Please try again.'**
  String get helpFeedback_whatsappFailed;

  /// No description provided for @helpFeedback_openLink.
  ///
  /// In en, this message translates to:
  /// **'Open link'**
  String get helpFeedback_openLink;

  /// No description provided for @faq_howToLogWorkouts.
  ///
  /// In en, this message translates to:
  /// **'How do I log workouts?'**
  String get faq_howToLogWorkouts;

  /// No description provided for @faq_howToLogWorkoutsAnswer.
  ///
  /// In en, this message translates to:
  /// **'Go to the Home screen and tap \"Start Workout\" on today\'s workout card. Complete exercises by tapping each set, and finish with \"Complete Workout\".'**
  String get faq_howToLogWorkoutsAnswer;

  /// No description provided for @faq_howToTrackSteps.
  ///
  /// In en, this message translates to:
  /// **'How do I track my steps?'**
  String get faq_howToTrackSteps;

  /// No description provided for @faq_howToTrackStepsAnswer.
  ///
  /// In en, this message translates to:
  /// **'Steps are tracked automatically if your device has a sensor. You can also tap the Steps card on the Home screen to manually add steps.'**
  String get faq_howToTrackStepsAnswer;

  /// No description provided for @faq_howToLogWater.
  ///
  /// In en, this message translates to:
  /// **'How do I log water intake?'**
  String get faq_howToLogWater;

  /// No description provided for @faq_howToLogWaterAnswer.
  ///
  /// In en, this message translates to:
  /// **'Tap the Hydration card on the Home screen to add water. Each tap adds one glass (250 ml). You can also set a daily goal in Notifications.'**
  String get faq_howToLogWaterAnswer;

  /// No description provided for @faq_howAchievementsWork.
  ///
  /// In en, this message translates to:
  /// **'How do achievements work?'**
  String get faq_howAchievementsWork;

  /// No description provided for @faq_howAchievementsWorkAnswer.
  ///
  /// In en, this message translates to:
  /// **'Achievements unlock automatically as you hit milestones — completing workouts, logging steps, drinking water, etc. Check your progress on the Achievements card.'**
  String get faq_howAchievementsWorkAnswer;

  /// No description provided for @faq_howToChangePlan.
  ///
  /// In en, this message translates to:
  /// **'How do I change my workout plan?'**
  String get faq_howToChangePlan;

  /// No description provided for @faq_howToChangePlanAnswer.
  ///
  /// In en, this message translates to:
  /// **'Go to Profile → Workout Plan to choose a different week-day combination. Your progress will be preserved.'**
  String get faq_howToChangePlanAnswer;

  /// No description provided for @faq_howToSetGoals.
  ///
  /// In en, this message translates to:
  /// **'How do I set step and hydration goals?'**
  String get faq_howToSetGoals;

  /// No description provided for @faq_howToSetGoalsAnswer.
  ///
  /// In en, this message translates to:
  /// **'Tap the Steps or Hydration card on the Home screen, then long-press to adjust your daily targets.'**
  String get faq_howToSetGoalsAnswer;

  /// No description provided for @faq_howNotificationsWork.
  ///
  /// In en, this message translates to:
  /// **'How do notifications work?'**
  String get faq_howNotificationsWork;

  /// No description provided for @faq_howNotificationsWorkAnswer.
  ///
  /// In en, this message translates to:
  /// **'Go to Profile → Notifications to enable daily reminders, missed workout nudges, achievement alerts, and hydration reminders with custom schedules.'**
  String get faq_howNotificationsWorkAnswer;

  /// No description provided for @faq_howToLogWeight.
  ///
  /// In en, this message translates to:
  /// **'How do I log my weight?'**
  String get faq_howToLogWeight;

  /// No description provided for @faq_howToLogWeightAnswer.
  ///
  /// In en, this message translates to:
  /// **'On the Home screen, tap \"Log Weight\" in the Weight section to record your current weight and track progress toward your goal.'**
  String get faq_howToLogWeightAnswer;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
