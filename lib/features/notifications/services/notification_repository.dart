import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum NotificationType {
  dailyReminder,
  missedWorkout,
  achievement,
  recoverySuggestion,
  weeklyProgress,
  weightFollowUp,
  hydrationReminder,
}

class NotificationRepository {
  static final NotificationRepository _instance = NotificationRepository._();
  factory NotificationRepository() => _instance;
  NotificationRepository._();

  SharedPreferences? _prefsCache;

  Future<SharedPreferences> get _prefs async {
    _prefsCache ??= await SharedPreferences.getInstance();
    return _prefsCache!;
  }

  // ── Keys ──
  static const _masterKey = 'notif_master';
  static const _dailyReminderKey = 'notif_daily_reminder';
  static const _dailyHourKey = 'notif_daily_hour';
  static const _dailyMinuteKey = 'notif_daily_minute';
  static const _missedWorkoutKey = 'notif_missed_workout';
  static const _missedDelayKey = 'notif_missed_delay_hours';
  static const _achievementKey = 'notif_achievement';
  static const _recoveryKey = 'notif_recovery';
  static const _weeklyProgressKey = 'notif_weekly_progress';
  static const _weeklyDayKey = 'notif_weekly_day';
  static const _weeklyHourKey = 'notif_weekly_hour';
  static const _weeklyMinuteKey = 'notif_weekly_minute';
  static const _weightFollowUpKey = 'notif_weight_followup';
  static const _weightTargetKey = 'notif_weight_target';
  static const _weightIntervalDaysKey = 'notif_weight_interval_days';
  static const _weightReminderDaysKey = 'notif_weight_reminder_days';
  static const _quietHoursEnabledKey = 'notif_quiet_hours_enabled';
  static const _quietHoursStartHourKey = 'notif_quiet_start_hour';
  static const _quietHoursStartMinuteKey = 'notif_quiet_start_minute';
  static const _quietHoursEndHourKey = 'notif_quiet_end_hour';
  static const _quietHoursEndMinuteKey = 'notif_quiet_end_minute';
  static const _pauseUntilKey = 'notif_pause_until';
  static const _languageKey = 'notif_language';
  static const _useMetricKey = 'notif_use_metric';
  static const _hydrationReminderKey = 'notif_hydration_reminder';
  static const _hydrationIntervalMinutesKey = 'notif_hydration_interval_minutes';
  static const _hydrationStartHourKey = 'notif_hydration_start_hour';
  static const _hydrationEndHourKey = 'notif_hydration_end_hour';

  // ── Master ──
  Future<bool> get isMasterEnabled async {
    final prefs = await _prefs;
    return prefs.getBool(_masterKey) ?? true;
  }

  Future<void> setMasterEnabled(bool value) async {
    final prefs = await _prefs;
    await prefs.setBool(_masterKey, value);
  }

  // ── Daily Reminder ──
  Future<bool> get isDailyReminderEnabled async {
    final prefs = await _prefs;
    return prefs.getBool(_dailyReminderKey) ?? true;
  }

  Future<void> setDailyReminderEnabled(bool value) async {
    final prefs = await _prefs;
    await prefs.setBool(_dailyReminderKey, value);
  }

  Future<TimeOfDay> get dailyReminderTime async {
    final prefs = await _prefs;
    final hour = prefs.getInt(_dailyHourKey) ?? 8;
    final minute = prefs.getInt(_dailyMinuteKey) ?? 0;
    return TimeOfDay(hour: hour, minute: minute);
  }

  Future<void> setDailyReminderTime(TimeOfDay time) async {
    final prefs = await _prefs;
    await prefs.setInt(_dailyHourKey, time.hour);
    await prefs.setInt(_dailyMinuteKey, time.minute);
  }

  // ── Missed Workout ──
  Future<bool> get isMissedWorkoutEnabled async {
    final prefs = await _prefs;
    return prefs.getBool(_missedWorkoutKey) ?? false;
  }

  Future<void> setMissedWorkoutEnabled(bool value) async {
    final prefs = await _prefs;
    await prefs.setBool(_missedWorkoutKey, value);
  }

  Future<int> get missedWorkoutDelayHours async {
    final prefs = await _prefs;
    return prefs.getInt(_missedDelayKey) ?? 2;
  }

  Future<void> setMissedWorkoutDelayHours(int hours) async {
    final prefs = await _prefs;
    await prefs.setInt(_missedDelayKey, hours);
  }

  // ── Achievement ──
  Future<bool> get isAchievementEnabled async {
    final prefs = await _prefs;
    return prefs.getBool(_achievementKey) ?? true;
  }

  Future<void> setAchievementEnabled(bool value) async {
    final prefs = await _prefs;
    await prefs.setBool(_achievementKey, value);
  }

  // ── Recovery Suggestion ──
  Future<bool> get isRecoveryEnabled async {
    final prefs = await _prefs;
    return prefs.getBool(_recoveryKey) ?? true;
  }

  Future<void> setRecoveryEnabled(bool value) async {
    final prefs = await _prefs;
    await prefs.setBool(_recoveryKey, value);
  }

  // ── Weekly Progress ──
  Future<bool> get isWeeklyProgressEnabled async {
    final prefs = await _prefs;
    return prefs.getBool(_weeklyProgressKey) ?? true;
  }

  Future<void> setWeeklyProgressEnabled(bool value) async {
    final prefs = await _prefs;
    await prefs.setBool(_weeklyProgressKey, value);
  }

  Future<int> get weeklyProgressDay async {
    final prefs = await _prefs;
    return prefs.getInt(_weeklyDayKey) ?? DateTime.monday;
  }

  Future<void> setWeeklyProgressDay(int day) async {
    final prefs = await _prefs;
    await prefs.setInt(_weeklyDayKey, day);
  }

  Future<TimeOfDay> get weeklyProgressTime async {
    final prefs = await _prefs;
    final hour = prefs.getInt(_weeklyHourKey) ?? 10;
    final minute = prefs.getInt(_weeklyMinuteKey) ?? 0;
    return TimeOfDay(hour: hour, minute: minute);
  }

  Future<void> setWeeklyProgressTime(TimeOfDay time) async {
    final prefs = await _prefs;
    await prefs.setInt(_weeklyHourKey, time.hour);
    await prefs.setInt(_weeklyMinuteKey, time.minute);
  }

  // ── Weight Follow-Up ──
  Future<bool> get isWeightFollowUpEnabled async {
    final prefs = await _prefs;
    return prefs.getBool(_weightFollowUpKey) ?? false;
  }

  Future<void> setWeightFollowUpEnabled(bool value) async {
    final prefs = await _prefs;
    await prefs.setBool(_weightFollowUpKey, value);
  }

  Future<double> get weightTarget async {
    final prefs = await _prefs;
    return prefs.getDouble(_weightTargetKey) ?? 75.0;
  }

  Future<void> setWeightTarget(double kg) async {
    final prefs = await _prefs;
    await prefs.setDouble(_weightTargetKey, kg);
  }

  Future<int> get weightIntervalDays async {
    final prefs = await _prefs;
    return prefs.getInt(_weightIntervalDaysKey) ?? 3;
  }

  Future<void> setWeightIntervalDays(int days) async {
    final prefs = await _prefs;
    await prefs.setInt(_weightIntervalDaysKey, days);
  }

  Future<List<int>> get weightReminderDays async {
    final prefs = await _prefs;
    final raw = prefs.getStringList(_weightReminderDaysKey);
    return raw?.map((e) => int.parse(e)).toList() ?? [DateTime.tuesday, DateTime.saturday];
  }

  Future<void> setWeightReminderDays(List<int> days) async {
    final prefs = await _prefs;
    await prefs.setStringList(
      _weightReminderDaysKey,
      days.map((e) => e.toString()).toList(),
    );
  }

  // ── Quiet Hours ──
  Future<bool> get isQuietHoursEnabled async {
    final prefs = await _prefs;
    return prefs.getBool(_quietHoursEnabledKey) ?? false;
  }

  Future<void> setQuietHoursEnabled(bool value) async {
    final prefs = await _prefs;
    await prefs.setBool(_quietHoursEnabledKey, value);
  }

  Future<TimeOfDay> get quietHoursStart async {
    final prefs = await _prefs;
    return TimeOfDay(
      hour: prefs.getInt(_quietHoursStartHourKey) ?? 22,
      minute: prefs.getInt(_quietHoursStartMinuteKey) ?? 0,
    );
  }

  Future<TimeOfDay> get quietHoursEnd async {
    final prefs = await _prefs;
    return TimeOfDay(
      hour: prefs.getInt(_quietHoursEndHourKey) ?? 7,
      minute: prefs.getInt(_quietHoursEndMinuteKey) ?? 0,
    );
  }

  Future<void> setQuietHours(TimeOfDay start, TimeOfDay end) async {
    final prefs = await _prefs;
    await prefs.setInt(_quietHoursStartHourKey, start.hour);
    await prefs.setInt(_quietHoursStartMinuteKey, start.minute);
    await prefs.setInt(_quietHoursEndHourKey, end.hour);
    await prefs.setInt(_quietHoursEndMinuteKey, end.minute);
  }

  // ── Pause ──
  Future<DateTime?> get pauseUntil async {
    final prefs = await _prefs;
    final raw = prefs.getString(_pauseUntilKey);
    return raw != null ? DateTime.parse(raw) : null;
  }

  Future<void> setPauseUntil(DateTime? value) async {
    final prefs = await _prefs;
    if (value != null) {
      await prefs.setString(_pauseUntilKey, value.toIso8601String());
    } else {
      await prefs.remove(_pauseUntilKey);
    }
  }

  // ── Language ──
  Future<String> get languageCode async {
    final prefs = await _prefs;
    return prefs.getString(_languageKey) ?? 'en';
  }

  Future<void> setLanguageCode(String code) async {
    final prefs = await _prefs;
    await prefs.setString(_languageKey, code);
  }

  // ── Units ──
  Future<bool> get isMetric async {
    final prefs = await _prefs;
    return prefs.getBool(_useMetricKey) ?? true;
  }

  Future<void> setMetric(bool value) async {
    final prefs = await _prefs;
    await prefs.setBool(_useMetricKey, value);
  }

  // ── Hydration Reminder ──
  Future<bool> get isHydrationReminderEnabled async {
    final prefs = await _prefs;
    return prefs.getBool(_hydrationReminderKey) ?? true;
  }

  Future<void> setHydrationReminderEnabled(bool value) async {
    final prefs = await _prefs;
    await prefs.setBool(_hydrationReminderKey, value);
  }

  Future<int> get hydrationIntervalMinutes async {
    final prefs = await _prefs;
    return prefs.getInt(_hydrationIntervalMinutesKey) ?? 60;
  }

  Future<void> setHydrationIntervalMinutes(int minutes) async {
    final prefs = await _prefs;
    await prefs.setInt(_hydrationIntervalMinutesKey, minutes);
  }

  Future<int> get hydrationStartHour async {
    final prefs = await _prefs;
    return prefs.getInt(_hydrationStartHourKey) ?? 8;
  }

  Future<void> setHydrationStartHour(int hour) async {
    final prefs = await _prefs;
    await prefs.setInt(_hydrationStartHourKey, hour);
  }

  Future<int> get hydrationEndHour async {
    final prefs = await _prefs;
    return prefs.getInt(_hydrationEndHourKey) ?? 22;
  }

  Future<void> setHydrationEndHour(int hour) async {
    final prefs = await _prefs;
    await prefs.setInt(_hydrationEndHourKey, hour);
  }

  // ── Bulk load ──
  Future<Map<String, dynamic>> loadAll() async {
    final prefs = await _prefs;
    return {
      'master': prefs.getBool(_masterKey) ?? true,
      'dailyReminder': prefs.getBool(_dailyReminderKey) ?? true,
      'dailyHour': prefs.getInt(_dailyHourKey) ?? 8,
      'dailyMinute': prefs.getInt(_dailyMinuteKey) ?? 0,
      'missedWorkout': prefs.getBool(_missedWorkoutKey) ?? false,
      'missedDelay': prefs.getInt(_missedDelayKey) ?? 2,
      'achievement': prefs.getBool(_achievementKey) ?? true,
      'recovery': prefs.getBool(_recoveryKey) ?? true,
      'weeklyProgress': prefs.getBool(_weeklyProgressKey) ?? true,
      'weeklyDay': prefs.getInt(_weeklyDayKey) ?? DateTime.monday,
      'weeklyHour': prefs.getInt(_weeklyHourKey) ?? 10,
      'weeklyMinute': prefs.getInt(_weeklyMinuteKey) ?? 0,
      'weightFollowUp': prefs.getBool(_weightFollowUpKey) ?? false,
      'weightTarget': prefs.getDouble(_weightTargetKey) ?? 75.0,
      'weightInterval': prefs.getInt(_weightIntervalDaysKey) ?? 3,
      'weightReminderDays': prefs.getStringList(_weightReminderDaysKey)
              ?.map((e) => int.parse(e))
              .toList() ??
          [DateTime.tuesday, DateTime.saturday],
      'quietHoursEnabled': prefs.getBool(_quietHoursEnabledKey) ?? false,
      'quietStartHour': prefs.getInt(_quietHoursStartHourKey) ?? 22,
      'quietStartMinute': prefs.getInt(_quietHoursStartMinuteKey) ?? 0,
      'quietEndHour': prefs.getInt(_quietHoursEndHourKey) ?? 7,
      'quietEndMinute': prefs.getInt(_quietHoursEndMinuteKey) ?? 0,
      'pauseUntil': prefs.getString(_pauseUntilKey),
      'language': prefs.getString(_languageKey) ?? 'en',
      'isMetric': prefs.getBool(_useMetricKey) ?? true,
      'hydrationReminder': prefs.getBool(_hydrationReminderKey) ?? true,
      'hydrationIntervalMinutes': prefs.getInt(_hydrationIntervalMinutesKey) ?? 60,
      'hydrationStartHour': prefs.getInt(_hydrationStartHourKey) ?? 8,
      'hydrationEndHour': prefs.getInt(_hydrationEndHourKey) ?? 22,
    };
  }
}
