/// A single update entry shown in Profile → Support → Log & Updates.
///
/// Every time a feature, bug fix, or improvement is shipped, add an entry
/// here *and* append it to `The Plan.md` so the two stay in sync.
class UpdateEntry {
  final DateTime date;
  final String title;
  final String description;

  const UpdateEntry({
    required this.date,
    required this.title,
    required this.description,
  });
}

/// The full changelog — newest entries first.
///
/// Source of truth: `The Plan.md` file at the project root.
/// Whenever you add here, add the same entry to The Plan.md too.
final changelog = <UpdateEntry>[
  // ── 2026-07-15: Multi-Plan Hub + Planning Mode ──
  UpdateEntry(
    date: DateTime(2026, 7, 15),
    title: 'Workout Plan Hub + Custom Plans',
    description:
        'Profile → Workout Plan now opens a plan hub: the built-in 12-week '
        'program as default, your custom multi-week plans, and a + card to '
        'create new ones. Planning mode lets you add weeks, expand days, and '
        'multi-select default + custom exercises per day. Home still uses the '
        'built-in program for now.',
  ),

  // ── 2026-06-16: Day-Rollover & Exercise Tracking Overhaul ──
  UpdateEntry(
    date: DateTime(2026, 6, 16),
    title: 'Day-Rollover Fix + Exercise Tracking Overhaul',
    description:
        'Fixed the day-rollover bug where progress advanced on workout completion '
        'instead of midnight. Program progress now advances at 00:00 using a new '
        'lastAdvanceDate field — multi-day catch-up on cold start works correctly. '
        'Partial workouts are now saved to History at midnight instead of being lost. '
        'History always shows your current week with today highlighted in your '
        'theme color. Exercise checkboxes auto-complete the workout (600ms delay). '
        'This Week chart now scales bar height by exercise completion ratio — '
        'partial workouts show proportional progress, rest days show 100%. '
        'Added duplicate-exercise guard to prevent off-by-one count errors.',
  ),

  // ── 2026-06-16: Help & Feedback, Home Layout Fix, Full Audit ──
  UpdateEntry(
    date: DateTime(2026, 6, 16),
    title: 'Help & Feedback + Home Fix + Audit Sweep',
    description:
        'New Help & Feedback screen (FAQ + WhatsApp feedback form) wired from '
        'Profile. Fixed home layout: CrossAxisAlignment.stretch for full-width '
        'cards, SizedBox(height:130) for Steps/Hydration, consistent 14px padding. '
        'Audit fixes: localized focus names, celebration dialog, fake weekly data '
        'replaced with zeros, white CircularProgressIndicator for light theme, '
        'Stack alignment on metric cards, localized rest-day label, max-width '
        'constraints on Profile/Help screens, keyboard dismiss + TextInputAction.next '
        'in feedback form, WhatsApp fallback link, removed unused isSoon param, '
        'cached CurvedAnimation instances in This Week chart, empty profile defaults, '
        'and 10+ new l10n strings (EN + AR).',
  ),

  // ── 2026-06-15: Tips & Tricks + Splash Screen ──
  UpdateEntry(
    date: DateTime(2026, 6, 15),
    title: 'Tips & Tricks + Splash Screen',
    description:
        'Added a Tips & Tricks section under Profile → Support with 30 '
        'science-backed tips across 6 categories (Water, Steps, Rest, Workouts, '
        'Nutrition, Motivation) in a collapsible accordion dialog. A new splash '
        'screen now greets you on app launch, showing a random tip under the '
        'app icon — learn something new every time you open the app.',
  ),

  // ── 2026-06-15: Hydration System ──
  UpdateEntry(
    date: DateTime(2026, 6, 15),
    title: 'Hydration Tracking System',
    description:
        'A complete hydration system on the home screen, matching the steps UX: '
        'long-press to open Hydration History screen with week/month chart views, '
        'quick-add buttons (+0.25L, +0.5L, +1.0L) on the card, streak indicator '
        'showing consecutive goal-met days, trend vs yesterday, and multi-entry '
        'per-day tracking with drink source types (Water, Tea, Coffee, Juice, etc.). '
        'Every drink is persisted individually with timestamps for accurate history.',
  ),

  // ── 2026-06-14: Notification Settings Overhaul ──
  UpdateEntry(
    date: DateTime(2026, 6, 14),
    title: 'Notification Settings Overhaul',
    description:
        'Major cleanup of Profile → Notifications: (1) Full localization — all 50+ '
        'hardcoded English strings replaced with ARB keys (EN + AR). (2) Deleted 4 '
        'dead widget files (844 lines). (3) Added loading spinner while settings load. '
        '(4) Error handling with try-catch on all async operations. (5) "Send Test '
        'Notification" button to verify setup. (6) Achievement & Recovery converted '
        'from full bottom sheets to inline switches. (7) Fixed hydration math bug '
        '(was calculating sleeping hours instead of active hours). (8) Master toggle '
        'OFF now shows confirmation dialog. (9) SharedPreferences calls cached '
        '(60+ reads → 1). (10) Quiet hours sheet header standardized to match '
        'other sheets.',
  ),
  UpdateEntry(
    date: DateTime(2026, 6, 14),
    title: 'Notification Cards: Toggle + Settings Pattern',
    description:
        'Redesigned notification card interaction: toggle switch for quick on/off, '
        'chevron indicator (>) on cards that have settings, tap card body to open '
        'settings sheet. Toggle no longer auto-opens settings — users choose when '
        'to configure. Matches iOS/Android Settings app mental model.',
  ),
  UpdateEntry(
    date: DateTime(2026, 6, 14),
    title: 'Notification Settings: Bottom Sheets → Dialogs',
    description:
        'Converted all 6 notification settings bottom sheets to centered Dialog '
        'widgets with ScrollView to prevent overflow on smaller screens. Removed '
        'toggle switches from cards — cards now show ON badge + chevron, tap opens '
        'settings dialog. Toggle lives only inside the dialog.',
  ),

  // ── 2026-06-14: Profile > Appearance Feature ──
  UpdateEntry(
    date: DateTime(2026, 6, 14),
    title: 'Profile > Appearance: Steps & Hydration Goals',
    description:
        'Three new features under Profile → Appearance: (1) Steps target — edit your '
        'daily step goal via long-press on the gear icon. (2) Hydration target — '
        'auto-calculate from body weight (weight × 0.035) or set manually. '
        '(3) Hydration reminder — configurable periodic reminders with dynamic '
        'amount calculation based on your daily goal and reminder interval.',
  ),

  // ── 2026-06-14: Steps Sensor ──
  UpdateEntry(
    date: DateTime(2026, 6, 14),
    title: 'Steps Sensor Integration',
    description:
        'Step counting now reads directly from the device hardware sensor via '
        'platform channels. Tracks a baseline on start and calculates daily steps '
        'automatically. Includes manual mode fallback for devices without a sensor. '
        'Special thanks to Okasha Saber for contributing this feature!',
  ),

  // ── 2026-06-11: Exercise Library Premium Redesign ──
  UpdateEntry(
    date: DateTime(2026, 6, 11),
    title: 'Exercise Library Premium Redesign',
    description:
        'Complete overhaul of the exercise library: category-specific Material Icons '
        'as leading icons, dual subtitles (prescription + description), premium card '
        'styling with subtle colored borders, modal bottom sheets for exercise detail '
        'and add/edit forms (replacing AlertDialogs), and usage stats showing "Completed '
        'X×" badge on every card derived from workout session history.',
  ),
  UpdateEntry(
    date: DateTime(2026, 6, 11),
    title: 'Exercise Usage Stats',
    description:
        'Every exercise card now shows how many times it has been completed across '
        'all workout sessions. Counts are computed from saved session history and '
        'displayed as a concise "X×" badge in the card header.',
  ),

  // ── 2026-06-10: Achievements System ──
  UpdateEntry(
    date: DateTime(2026, 6, 10),
    title: '30 Achievements + Celebration',
    description:
        'A full achievement system with 30 goals across 6 categories (Workout, '
        'Consistency, Steps, Hydration, Weight, Special). Two-column grid with '
        'progress bars, collapsible category sections, filter chips, and a '
        'closest-progress nudge on the dashboard. Unlock celebrations include '
        'confetti particles, trophy bounce, and haptics. Achievements persist '
        'across restarts via SharedPreferences with retroactive unlock on migration.',
  ),
  UpdateEntry(
    date: DateTime(2026, 6, 10),
    title: 'State Management Migration',
    description:
        'Added Provider for state management. AchievementProvider wraps the new '
        'AchievementService and is consumed by HomeScreen and ProfileScreen via '
        'context.watch, eliminating prop-drilling for achievement state.',
  ),

  // ── Easter eggs ──
  UpdateEntry(
    date: DateTime(2026, 6, 10),
    title: '🥚 Easter Egg — Gender Option',
    description:
        'The gender selector in Profile → Edit Profile now lists '
        '"Mentally Unstable" as the third option. Because sometimes '
        'we all need a label that fits.',
  ),

  // ── 2026-06-10 ──
  UpdateEntry(
    date: DateTime(2026, 6, 10),
    title: 'Rest Timer',
    description:
        'A countdown timer appears after each completed exercise (checkbox or dialog). '
        'Circular progress + seconds display + tap-to-skip. Haptic on expiry, '
        'red color in last 3 seconds. Duration from Profile → Rest Timer setting.',
  ),
  UpdateEntry(
    date: DateTime(2026, 6, 10),
    title: 'Pull-to-Refresh',
    description:
        'Pull down on Home or History to reload all data from storage. '
        'Works even when content is short (AlwaysScrollableScrollPhysics).',
  ),
  UpdateEntry(
    date: DateTime(2026, 6, 10),
    title: 'Error Handling for Storage',
    description:
        'Every SharedPreferences read/write is now wrapped in try/catch with '
        'sensible fallback defaults. Errors logged via debugPrint.',
  ),
  UpdateEntry(
    date: DateTime(2026, 6, 10),
    title: 'Atomic Workout Completion',
    description:
        'The "Complete Workout" flow is wrapped in try/catch with rollback — '
        'if saving fails, program progress is restored and a snackbar explains '
        'the error. State only commits after all writes succeed.',
  ),
  UpdateEntry(
    date: DateTime(2026, 6, 10),
    title: 'UTC/Local Date Consistency',
    description:
        'Replaced all `toIso8601String().substring(0, 10)` with a dedicated '
        '`dateKey()` helper that explicitly formats YYYY-MM-DD from '
        'year/month/day fields, avoiding any timezone ambiguity.',
  ),
  UpdateEntry(
    date: DateTime(2026, 6, 10),
    title: 'Sorted Weight Entries',
    description:
        'The "current weight" value shown in the weight log dialog now picks '
        'the entry with the most recent date instead of assuming list order.',
  ),
  UpdateEntry(
    date: DateTime(2026, 6, 10),
    title: 'History Screen Auto-Refresh',
    description:
        'History reloads whenever a workout completes, even if the week number '
        'hasn\'t changed. Previously it only refreshed on week boundaries.',
  ),
  UpdateEntry(
    date: DateTime(2026, 6, 10),
    title: 'Weight Persistence Fix',
    description:
        'Weight saves are now awaited instead of fire-and-forget. Previously '
        'the app could be killed before the async write finished, losing the entry.',
  ),
  UpdateEntry(
    date: DateTime(2026, 6, 10),
    title: 'End Workout Now Saves Progress',
    description:
        'Tapping "End Workout" inside an exercise dialog now records the '
        'completed exercise before closing. Previously it gave zero credit.',
  ),
  UpdateEntry(
    date: DateTime(2026, 6, 10),
    title: 'Checkbox Completion Detection',
    description:
        'Marking all exercises via checkboxes now correctly triggers workout '
        'completion (previously only the play-button dialog triggered it). '
        'A "Complete Workout" button appears when all exercises are done.',
  ),
  UpdateEntry(
    date: DateTime(2026, 6, 10),
    title: 'Startup Flash Fixed',
    description:
        'Eliminated the double `runApp()` that destroyed state and caused a '
        'visible flash on cold start. Theme persistence now works reliably.',
  ),
  UpdateEntry(
    date: DateTime(2026, 6, 10),
    title: 'Home Section Visibility',
    description:
        'New Profile → Appearance → Home Settings lets you show/hide '
        'Steps, Achievements, Hydration, and Weight Trend on the dashboard. '
        'Settings persist across restarts.',
  ),
  UpdateEntry(
    date: DateTime(2026, 6, 10),
    title: 'Theme Persistence',
    description:
        'Dark/light theme preference is now saved to SharedPreferences and '
        'restored on next launch.',
  ),
  UpdateEntry(
    date: DateTime(2026, 6, 10),
    title: 'Greeting & Clock Fix',
    description:
        'The time-of-day greeting is now reactive (updates every minute). '
        'Added `Clock` abstraction for testable time handling.',
  ),

  // ── Earlier (bulk from initial development) ──
  UpdateEntry(
    date: DateTime(2026, 6, 9),
    title: 'Profile Stats Redesign',
    description:
        'Achievements moved above Workouts + Day Streak. Removed Total Time '
        'card. Compact card heights and reduced spacing.',
  ),
  UpdateEntry(
    date: DateTime(2026, 6, 9),
    title: 'Weight Chart & Log',
    description:
        'Full weight tracking: log dialog with slider + date picker, goal '
        'setting, trend chart on home dashboard, all persisted to storage.',
  ),
];
