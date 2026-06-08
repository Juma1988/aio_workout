import 'dart:ui' as ui;

class NotificationStrings {
  static String? _overrideLanguageCode;

  static void setOverride(String code) {
    _overrideLanguageCode = code;
  }

  static String get currentLanguage =>
      _overrideLanguageCode ?? ui.PlatformDispatcher.instance.locale.languageCode;

  static bool get isArabic => currentLanguage == 'ar';

  static String get(String en, String ar) => isArabic ? ar : en;

  // ── Titles ──
  static String get dailyReminderTitle => get(
    'Daily Workout Reminder',
    'تذكير التمرين اليومي',
  );
  static String get missedWorkoutTitle => get(
    'Missed Workout Reminder',
    'تذكير التمرين الفائت',
  );
  static String get achievementTitle => get(
    'Achievement Notification',
    'إشعار الإنجاز',
  );
  static String get recoveryTitle => get(
    'Recovery Suggestion',
    'اقتراح التعافي',
  );
  static String get weeklyProgressTitle => get(
    'Weekly Progress',
    'التقدم الأسبوعي',
  );
  static String get weightFollowUpTitle => get(
    'Weight Follow-Up',
    'متابعة الوزن',
  );

  // ── Subtitles ──
  static String get dailyReminderSubtitle => get(
    'Remind me to work out daily',
    'ذكرني بممارسة التمرين يومياً',
  );
  static String get missedWorkoutSubtitle => get(
    'Nudge me after a missed workout',
    'ذكرني بعد التمرين الفائت',
  );
  static String get achievementSubtitle => get(
    'Celebrate my achievements',
    'احتفل بإنجازاتي',
  );
  static String get recoverySubtitle => get(
    'Suggest rest after consecutive days',
    'اقترح الراحة بعد أيام متتالية',
  );
  static String get weeklyProgressSubtitle => get(
    'Weekly summary of my stats',
    'ملخص أسبوعي لإحصائياتي',
  );
  static String get weightFollowUpSubtitle => get(
    'Remind me to log my weight',
    'ذكرني بتسجيل وزني',
  );

  // ── General ──
  static String get notifications => get('Notifications', 'الإشعارات');
  static String get on_ => get('On', 'مفعل');
  static String get off => get('Off', 'معطل');
  static String get done => get('Done', 'تم');
  static String get save => get('Save', 'حفظ');
  static String get cancel => get('Cancel', 'إلغاء');
  static String get testNotification => get(
    'Test Notification',
    'إشعار اختباري',
  );
  static String get testNotificationSent => get(
    'Test notification sent. Check your notification tray.',
    'تم إرسال إشعار اختباري. تحقق من لوحة الإشعارات.',
  );
  static String get pauseNotifications => get(
    'Pause Notifications',
    'إيقاف الإشعارات مؤقتاً',
  );
  static String get resumeNotifications => get(
    'Resume Notifications',
    'استئناف الإشعارات',
  );
  static String get paused => get('Paused', 'متوقف مؤقتاً');
  static String get quietHours => get('Quiet Hours', 'ساعات الهدوء');
  static String get quietHoursSubtitle => get(
    'Suppress notifications during specified hours',
    'إخفاء الإشعارات خلال ساعات محددة',
  );
  static String get active => get('Active', 'نشط');
  static String get remaining => get('remaining', 'متبقي');

  // ── Section headers ──
  static String get workoutReminders => get(
    'Workout Reminders',
    'تذكيرات التمرين',
  );
  static String get progressStats => get(
    'Progress & Stats',
    'التقدم والإحصائيات',
  );

  // ── Daily reminder config ──
  static String get dailyReminderConfigTitle => get(
    'Daily Reminder',
    'التذكير اليومي',
  );
  static String get dailyReminderConfigBody => get(
    'What time should I remind you\nto work out?',
    'في أي وقت أذكرك\nبممارسة التمرين؟',
  );
  static String get tapToChange => get('Tap to change', 'اضغط للتغيير');

  // ── Missed workout config ──
  static String get missedWorkoutConfigTitle => get(
    'Missed Workout',
    'التمرين الفائت',
  );
  static String get missedWorkoutConfigHeader => get(
    'Get a gentle nudge when you miss a workout.',
    'احصل على تذكير لطيف عندما تفوت تمريناً.',
  );
  static String get waitTimeLabel => get(
    'Wait time after missed workout',
    'وقت الانتظار بعد التمرين الفائت',
  );
  static String get waitTimeDesc => get(
    'How long to wait before sending a reminder',
    'المدة التي تنتظرها قبل إرسال التذكير',
  );

  // ── Weekly progress config ──
  static String get weeklyProgressConfigTitle => get(
    'Weekly Progress',
    'التقدم الأسبوعي',
  );
  static String get weeklyProgressConfigHeader => get(
    'Choose which day you\'d like to receive\nyour weekly progress summary.',
    'اختر اليوم الذي تريد استلام\nملخص التقدم الأسبوعي فيه.',
  );

  // ── Weight follow-up config ──
  static String get weightConfigTitle => get(
    'Weight Follow-Up',
    'متابعة الوزن',
  );
  static String get weightConfigHeader => get(
    'Remind yourself to log your weight regularly and track toward your goal.',
    'ذكر نفسك بتسجيل وزنك بانتظام وتتبع هدفك.',
  );
  static String get targetWeight => get('Target Weight', 'الوزن المستهدف');
  static String get remindEvery => get('Remind me every…', 'ذكرني كل…');

  // ── Quiet hours ──
  static String get quietHoursConfigTitle => get(
    'Quiet Hours',
    'ساعات الهدوء',
  );
  static String get quietHoursDesc => get(
    'Notifications will be suppressed between start and end time.',
    'سيتم إخفاء الإشعارات بين وقت البداية ووقت النهاية.',
  );
  static String get startTime => get('Start', 'البداية');
  static String get endTime => get('End', 'النهاية');

  // ── Notification content ──
  static String get dailyReminderNotificationBody => get(
    'Ready to crush it 💪',
    'مستعد للتمرين 💪',
  );
  static String get missedWorkoutNotificationBody => get(
    'You missed your workout today. Time to get back on track!',
    'لقد فاتك تمرينك اليوم. حان وقت العودة للمسار!',
  );
  static String get recoveryNotificationBody => get(
    'You may benefit from a recovery day.',
    'قد تستفيد من يوم تعافي.',
  );
  static String get restCompleteTitle => get(
    'Rest Complete',
    'اكتملت الراحة',
  );
  static String get restCompleteBody => get(
    'Rest complete. Start next set.',
    'اكتملت الراحة. ابدأ المجموعة التالية.',
  );
}
