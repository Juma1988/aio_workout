import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'notification_repository.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  final NotificationRepository _repo = NotificationRepository();
  bool _initialized = false;

  // ── Notification channel IDs ──
  static const _defaultChannel = 'workout_reminders';
  static const _restTimerChannel = 'rest_timer';
  static const _achievementChannel = 'achievements';
  static const _testChannel = 'test';

  // ── Notification IDs ──
  static const _dailyReminderId = 1000;
  static const _missedWorkoutId = 1001;
  static const _achievementId = 1002;
  static const _recoveryId = 1003;
  static const _weeklyProgressId = 1004;
  static const _weightFollowUpId = 1005;
  static const _restTimerCompleteId = 2000;
  static const _testNotificationId = 9999;

  Future<void> initialize() async {
    if (_initialized) return;

    tz_data.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    _initialized = true;
  }

  void _onNotificationTap(NotificationResponse response) {
    // Handle notification tap — navigate to relevant screen
    // Currently no-op; could navigate to settings or history
  }

  Future<bool> requestPermissions() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      await android.requestNotificationsPermission();
    }
    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) {
      await ios.requestPermissions(alert: true, badge: true, sound: true);
    }
    return true;
  }

  // ── Channel creation ──
  Future<void> _ensureChannels() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      await android.createNotificationChannel(
        const AndroidNotificationChannel(
          _defaultChannel,
          'Workout Reminders',
          description: 'Daily reminders and workout notifications',
          importance: Importance.high,
        ),
      );
      await android.createNotificationChannel(
        const AndroidNotificationChannel(
          _restTimerChannel,
          'Rest Timer',
          description: 'Rest timer notifications',
          importance: Importance.high,
          enableVibration: false,
        ),
      );
      await android.createNotificationChannel(
        const AndroidNotificationChannel(
          _achievementChannel,
          'Achievements',
          description: 'Achievement unlocked notifications',
          importance: Importance.high,
        ),
      );
      await android.createNotificationChannel(
        const AndroidNotificationChannel(
          _testChannel,
          'Test',
          description: 'Test notifications',
          importance: Importance.defaultImportance,
          playSound: false,
        ),
      );
    }
  }

  // ── Helpers ──
  bool _isInQuietHours(TimeOfDay now, TimeOfDay qStart, TimeOfDay qEnd) {
    final nowMinutes = now.hour * 60 + now.minute;
    final startMinutes = qStart.hour * 60 + qStart.minute;
    final endMinutes = qEnd.hour * 60 + qEnd.minute;
    if (startMinutes <= endMinutes) {
      return nowMinutes >= startMinutes && nowMinutes < endMinutes;
    }
    return nowMinutes >= startMinutes || nowMinutes < endMinutes;
  }

  Future<bool> _shouldSuppress() async {
    final pauseUntil = await _repo.pauseUntil;
    if (pauseUntil != null && DateTime.now().isBefore(pauseUntil)) return true;
    if (!await _repo.isMasterEnabled) return true;
    return false;
  }

  Future<bool> _shouldSuppressDueToQuietHours() async {
    if (!await _repo.isQuietHoursEnabled) return false;
    final now = TimeOfDay.now();
    final qStart = await _repo.quietHoursStart;
    final qEnd = await _repo.quietHoursEnd;
    return _isInQuietHours(now, qStart, qEnd);
  }

  // ── Schedule: Daily Reminder ──
  Future<void> scheduleDailyReminder() async {
    if (await _shouldSuppress()) return;
    if (!await _repo.isDailyReminderEnabled) return;

    await _ensureChannels();
    await _cancelNotificationById(_dailyReminderId);

    final time = await _repo.dailyReminderTime;
    final now = DateTime.now();
    var scheduledDate = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      _dailyReminderId,
      'Daily Workout Reminder',
      'Ready to crush it \u{1F4AA}',
      tz.TZDateTime.from(scheduledDate, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _defaultChannel,
          'Workout Reminders',
          importance: Importance.high,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  // ── Schedule: Missed Workout ──
  Future<void> scheduleMissedWorkoutReminder() async {
    if (!await _repo.isMissedWorkoutEnabled) return;
    if (await _shouldSuppress()) return;
    if (await _shouldSuppressDueToQuietHours()) return;

    await _ensureChannels();
    await _cancelNotificationById(_missedWorkoutId);

    final delayHours = await _repo.missedWorkoutDelayHours;
    final fireTime = DateTime.now().add(Duration(hours: delayHours));

    await _plugin.zonedSchedule(
      _missedWorkoutId,
      'Missed Workout Reminder',
      'You missed your workout today. Time to get back on track!',
      tz.TZDateTime.from(fireTime, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _defaultChannel,
          'Workout Reminders',
          importance: Importance.high,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  // ── Schedule: Achievement ──
  Future<void> showAchievementNotification(String title, String description) async {
    if (!await _repo.isAchievementEnabled) return;
    if (await _shouldSuppress()) return;

    await _ensureChannels();

    await _plugin.show(
      _achievementId + title.hashCode,
      title,
      description,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _achievementChannel,
          'Achievements',
          importance: Importance.high,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
    );
  }

  // ── Schedule: Recovery Suggestion ──
  Future<void> scheduleRecoverySuggestion() async {
    if (!await _repo.isRecoveryEnabled) return;
    if (await _shouldSuppress()) return;
    if (await _shouldSuppressDueToQuietHours()) return;

    await _ensureChannels();
    await _cancelNotificationById(_recoveryId);

    final now = DateTime.now();
    final fireTime = DateTime(now.year, now.month, now.day, 20, 0);
    if (fireTime.isBefore(now)) return;

    await _plugin.zonedSchedule(
      _recoveryId,
      'Recovery Suggestion',
      'You may benefit from a recovery day.',
      tz.TZDateTime.from(fireTime, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _defaultChannel,
          'Workout Reminders',
          importance: Importance.high,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  // ── Schedule: Weekly Progress ──
  Future<void> scheduleWeeklyProgress() async {
    if (!await _repo.isWeeklyProgressEnabled) return;
    if (await _shouldSuppress()) return;

    await _ensureChannels();
    await _cancelNotificationById(_weeklyProgressId);

    final day = await _repo.weeklyProgressDay;
    final time = await _repo.weeklyProgressTime;
    final now = DateTime.now();

    var scheduledDate = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    while (scheduledDate.weekday != day || scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      _weeklyProgressId,
      'Weekly Progress',
      _buildWeeklySummary(),
      tz.TZDateTime.from(scheduledDate, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _defaultChannel,
          'Workout Reminders',
          importance: Importance.high,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
    );
  }

  String _buildWeeklySummary() {
    // Placeholder — in production, compute from stored sessions
    return 'Check your weekly progress in the app.';
  }

  // ── Schedule: Weight Follow-Up ──
  Future<void> scheduleWeightFollowUp() async {
    if (!await _repo.isWeightFollowUpEnabled) return;
    if (await _shouldSuppress()) return;
    if (await _shouldSuppressDueToQuietHours()) return;

    await _ensureChannels();
    await _cancelNotificationById(_weightFollowUpId);

    final interval = await _repo.weightIntervalDays;
    final now = DateTime.now();
    final fireTime = now.add(Duration(days: interval));

    await _plugin.zonedSchedule(
      _weightFollowUpId,
      'Weight Follow-Up',
      'Time to log your weight!',
      tz.TZDateTime.from(fireTime, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _defaultChannel,
          'Workout Reminders',
          importance: Importance.high,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  // ── Rest Timer (single completion notification) ──
  Future<void> scheduleRestTimerComplete(int secondsRemaining) async {
    await _ensureChannels();

    final fireTime = DateTime.now().add(Duration(seconds: secondsRemaining));

    await _plugin.zonedSchedule(
      _restTimerCompleteId,
      'Rest Complete',
      'Rest complete. Start next set.',
      tz.TZDateTime.from(fireTime, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _restTimerChannel,
          'Rest Timer',
          importance: Importance.high,
          enableVibration: true,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: false,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> cancelRestTimerNotification() async {
    await _cancelNotificationById(_restTimerCompleteId);
  }

  // ── Test Notification ──
  Future<void> sendTestNotification() async {
    await _ensureChannels();

    await _plugin.show(
      _testNotificationId,
      'Test Notification',
      'Test Notification sent',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _testChannel,
          'Test',
          importance: Importance.defaultImportance,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: false,
          presentSound: false,
        ),
      ),
    );
  }

  // ── Cancel all ──
  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  Future<void> _cancelNotificationById(int id) async {
    await _plugin.cancel(id);
  }

  // ── Reschedule all (called on master toggle, language change, etc.) ──
  Future<void> rescheduleAll() async {
    await cancelAll();
    if (!await _repo.isMasterEnabled) return;
    await scheduleDailyReminder();
    await scheduleWeeklyProgress();
  }
}
