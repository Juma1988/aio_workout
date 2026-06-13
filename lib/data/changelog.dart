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
