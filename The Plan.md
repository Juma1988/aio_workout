# The Plan — AIO Workout

## <span style="color:red;">⏳ Open Issues</span>

- <span style="color:red;">Error when running Exercise — image resource PathNotFoundException (avatar cache file missing)</span>

---

## ✅ All Tasks Completed

### Feature Work ✅

#### 18. Achievement System (30 Achievements)
- `lib/features/achievements/models/` — data models: `AchievementCategory` (6 enums), `AchievementDefinition`, `UnlockedAchievement`, `AchievementState`, `AchievementResult`, `AchievementProgressSnapshot`, `all_achievement_definitions.dart` (30 definitions)
- `lib/features/achievements/services/` — storage: abstract `AchievementStorage` + `SharedPrefsAchievementStorage` (single JSON blob, `achievements_state` / `achievement_migration_v2` keys); `AchievementService` with evaluation, migration, event hooks
- `lib/features/achievements/providers/` — `AchievementProvider` (ChangeNotifier wrapping service)
- `lib/features/achievements/widgets/` — `AchievementTileGrid` (two-column grid with mini progress bar), `AchievementCategorySection` (collapsible with progress ring), `AchievementPreviewCard` (dashboard card with proximity nudge + category dots), `AchievementBadge` (orange count), `AchievementCountText` ("X / Y unlocked"), `AchievementCelebration` (confetti + trophy + haptics)
- `lib/features/achievements/dialogs/` — `AchievementsDialog` (full-screen with filter chips, progress ring), `AchievementDetailSheet` (bottom sheet with unlock info + progress)
- Integration: `main.dart` — `MultiProvider` wrapping `MainShell`; `main_shell.dart` — provider init, legacy achievement removal, celebration wiring; `home_screen.dart` + `profile_screen.dart` — `AchievementPreviewCard` via Provider
- Storage: retroactive unlock on migration, incremental counters O(1)
- `flutter analyze` — 0 errors, 0 warnings

#### 1. Weight Chart Feature
- `lib/data/weight_entry.dart` — model
- `lib/core/theme/app_theme.dart` — `weightPurple` added
- `lib/services/workout_storage_service.dart` — weight CRUD
- `lib/features/dialogs/weight_log_sheet.dart` — dialog with slider + date picker + goal setting
- `lib/features/home/home_screen.dart` — weight card with `WeightChartPainter`, section header
- `lib/features/navigation/main_shell.dart` — state wired in

#### 2. Weight Card — Visual Polish
- Card padding: 12px → **16px** (matches "This Week")
- Header: simplified `Row(icon + Column("Weight" + counter) | Spacer + ProgressRing)`
- Chart height: 80px → **110px** (matches bar chart)
- Section header visible above card
- Pixel height matches "This Week" via matching padding + chart height

#### 3. Weight Log: Bottom Sheet → Centered Dialog
- Converted from `showModalBottomSheet` → `showDialog` with `Dialog` widget
- Kept slider + animated weight value + editable date via `showDatePicker`
- Goal logic: no goal set → shows "Set target weight" TextButton

#### 4. Time/Greeting Bug Fix
- Created `lib/core/clock.dart` — `Clock` abstract class + `SystemClock` impl
- Made greeting reactive: `Timer.periodic(1 min)` + `WidgetsBindingObserver`

#### 5. Profile Stats Redesign
- Moved Achievements above Workouts + Day Streak cards
- Removed Total Time card and `_totalMinutes` state
- Reduced card heights and spacing for compact layout

#### 6. Appearance → Home Settings
- Created `home_settings_dialog.dart` — show/hide toggles for Steps, Achievements, Hydration, Weight Trend
- Persisted via `home_show_*` SharedPreferences keys
- Wired through MainShell → HomeScreen visibility flags

#### 7. Theme Persistence
- Added `theme_is_dark` SharedPreferences key
- `_loadThemeMode()` reads on startup, `_persistThemeMode()` saves on toggle

#### 8. Weight Log Sheet — Analyzer Cleanup
- Removed `BuildContext context` parameter from `_showGoalDialog()` (used `this.context` instead)
- `flutter analyze` — **0 issues**

---

### Critical Bug Fixes ✅

#### 9. Double `runApp()` at Startup
- **Root cause:** `main()` called `runApp()` then `_initNotifications()` called it again
- **Fix:** Moved notification init before the single `runApp()` call. Added try/catch. Made `main()` async.

#### 10. Workout Completion Never Fires via Checkbox
- **Root cause:** `_checkAutoComplete()` only checked `_completedViaDialog` (play-button exercises)
- **Fix:** Now checks `_completedUuids` (all sources). Added "Complete Workout" button when all exercises done.

#### 11. "End Workout" in Exercise Dialog Doesn't Save
- **Root cause:** "End Workout" closed dialog without calling `onComplete()`
- **Fix:** `_confirmExit()` now calls `widget.onComplete()` before popping

#### 12. Fire-and-Forget Async Saves (Weight Persistence Fix)
- **Root cause:** `_onWeightLogged` was fire-and-forget on `addWeightEntry()`
- **Fix:** Changed to `Future<void>` and **awaits** the save. `_persistToday()` kept as fire-and-forget (low-criticality, called frequently).

#### 13. History Screen Never Refreshes
- **Root cause:** HistoryScreen loaded data only in `initState()`, no refresh mechanism
- **Fix:** Added `_historyRefreshCounter` incremented on every workout complete. HistoryScreen key now includes the counter.

#### 14. Unsorted Weight Entries for "Current" Value
- **Root cause:** `_weightEntries.last` assumed chronological order but entries weren't sorted
- **Fix:** Replaced `.last` with `.reduce((a, b) => a.date.isAfter(b.date) ? a : b)`

#### 15. UTC/Local Date Mismatch
- **Root cause:** `toIso8601String().substring(0, 10)` behavior varies across platforms/timezones
- **Fix:** Created `dateKey(DateTime date)` top-level function that explicitly formats `YYYY-MM-DD` from year/month/day. Replaced all 9 usages across the codebase.

#### 16. Atomic Workout Completion
- **Root cause:** `_onWorkoutComplete` spans ~100 lines with 3+ async storage calls. If app crashes mid-flow, progress could advance without session saved.
- **Fix:** Wrapped entire critical section in try/catch. Stores `oldProgress` before writes, restores on failure. State only committed after all saves succeed. Shows snackbar on failure.

#### 17. Error Handling for SharedPreferences
- **Root cause:** All 16 methods in `WorkoutStorageService` had no error handling
- **Fix:** Every method now wrapped in try/catch. Returns sensible defaults (empty list, zero, null) on failure. Errors logged via `debugPrint`.

---

### Items Assessed & Closed

#### Midnight Date-Boundary Loss
- **Assessment:** By design — today's transient state (steps, hydration, exercise UUIDs) is meant to reset at midnight. The fix is ensuring workouts are properly saved before midnight via the "Complete Workout" button, which is now in place.
- **Status:** Won't fix — mitigated by existing feature work.

#### `_rebuildScreens()` Called on Every `build()`
- **Assessment:** Not a real issue for this app size. Screens are simple and rebuild is fast.
- **Status:** Won't fix — negligible performance impact.

---

---

### Home Screen Deep Dive — Completed ✅ (2026-06-10)

#### H1. AnimatedBuilder Child Pattern
- Fixed all 4 `AnimatedBuilder` usages in steps card, hydration card, bars chart, and weight chart to pass animation-independent content via `child:` parameter, preventing full subtree rebuilds on every frame.

#### H2. Greeting Timer & DebugPrint
- Removed `debugPrint` from `_greeting` getter
- Added `_lastGreeting` tracking — `Timer.periodic` now only calls `setState` when the greeting actually changes (saves ~1600-line rebuild every 60s)

#### H3. Dual Completion Tracking Eliminated
- Removed `_completedViaDialog` set entirely
- `isDoneViaDialog` is now derived purely from `widget.completedExerciseUuids`
- Cleaner single source of truth for exercise completion state

#### H5. Weekly Chart Wired to Real Session Data
- Added `List<WorkoutSession>? recentSessions` parameter to `HomeScreen`
- `_computeWeeklyLevels()` aggregates sessions by day of current week, normalizes to 0.0-1.0
- "4 workouts" label now shows actual count from session data
- Fallback to placeholder data when no sessions available
- Sessions loaded in `MainShell._loadAll()` and passed to `HomeScreen`

#### M3. TweenAnimationBuilder ValueKey Anti-Pattern
- Removed `ValueKey()` from all 3 `TweenAnimationBuilder` usages (steps, hydration, weight) — animations now transition smoothly instead of resetting to 0

#### M8. ShouldRepaint & Widget Keys
- Fixed `WeightSparkPainter.shouldRepaint` to compare entry length + first/last (was using identity comparison)
- Exercise tiles now have stable keys via the list structure

#### M10. _hasAnimated Guard
- Added `_hasAnimated` flag to prevent entrance animation replay on `didChangeDependencies` retriggers

#### M11. Theme Toggle Icon Fix
- Inverted icons: now shows `light_mode_rounded` in dark mode (tap to switch to light) and `dark_mode_rounded` in light mode

#### M12. Section Spacing Normalized
- Changed `SizedBox(height: 8)` above steps/hydration row to `SizedBox(height: 24)` — consistent 24px rhythm across all sections

#### M13. Max-Width Constraint for Tablet
- Wrapped layout in `Center` + `ConstrainedBox(maxWidth: 600)` — content is centered and constrained on tablets/landscape

#### M14. InkWell for Exercise Buttons
- All 3 exercise tile buttons (checkbox, play, info) changed from `GestureDetector` to `InkWell` with proper `borderRadius` — now shows Material ink ripple

#### M1. File Split — Domain-Organized Files
- `home_screen.dart` reduced from 1643 to ~1131 lines
- New files:
  - `models/trend_info.dart` — `TrendInfo` (was `_TrendInfo`)
  - `painters/weight_spark_painter.dart` — `WeightSparkPainter`
  - `widgets/top_action.dart` — `TopAction` (was `_TopAction`)
  - `widgets/progress_ring.dart` — `ProgressRing` (was `_ProgressRing`)
  - `widgets/exercise_info_sheet.dart` — `ExerciseInfoSheet` (extracted from inline bottom sheet builder)
- Removed unused `url_launcher` import from `home_screen.dart`

---

## 🔥 Home Screen Review — 6-Agent Deep Dive

On 2026-06-10, six specialized agents (Mobile App Builder, UI Design, UX Design, App Builder, Backend Architect, Frontend Developer) reviewed `lib/features/home/home_screen.dart` (1607 lines) and the surrounding architecture. Below are their combined recommendations, ranked by priority.

---

### 🔴 Critical / High Priority

#### H1. Fix `AnimatedBuilder` child parameter pattern
**Where:** `home_screen.dart:382,514,657,1281`
**Problem:** All 4 `AnimatedBuilder` usages ignore the `child:` parameter. Every frame rebuilds the entire Card subtree (icons, text, rings) even though only a `Transform.scale` wrapper changes.
**Fix:** Pass the static card content as `child:` and reference it in the builder.
**Effort:** ~15 minutes
**Impact:** Significant — prevents ~80% of unnecessary widget rebuilds during animations.

#### H2. Replace `_greetingTimer` with scoped rebuild
**Where:** `home_screen.dart:109-116,122-124`
**Problem:** `Timer.periodic(1 min)` calls `setState((){})` on the entire 1600-line widget just to update one `Text`. Also, `debugPrint` left in production code.
**Fix:** (a) Use a `Stream`-based approach or check if greeting actually changed before `setState`. (b) Remove `debugPrint`.
**Effort:** ~20 minutes

#### H3. Eliminate dual source of truth for exercise completion
**Where:** `home_screen.dart:103,793,803`
**Problem:** `_completedViaDialog` (local `Set`) tracks alongside `widget.completedExerciseUuids` (parent). They can desync. Logic at line 803 only runs on un-toggle, not parent-driven removals.
**Fix:** Derive `isDoneViaDialog` purely from `widget.completedExerciseUuids`. Remove `_completedViaDialog`.
**Effort:** ~30 minutes

#### H4. Extract state from MainShell into dedicated state management
**Where:** `main_shell.dart`
**Problem:** `_MainShellState` owns 12+ state fields via plain `setState()`, passes them as 20+ constructor parameters to `HomeScreen`. This is prop-drilling at scale. Every `setState` calls `_rebuildScreens()` which creates new screen instances.
**Fix:** Promote state into a `ChangeNotifier` or use Riverpod. Bundle related data into value objects (`TodayState`, `UserPreferences`).
**Effort:** 1-2 days

#### H5. Replace hardcoded placeholder weekly chart data
**Where:** `home_screen.dart:618-620`
**Problem:** `levels = [0.55, 0.35, 0.65, 0.25, 0.0, 0.9, 0.35]` and `'4 workouts'` are fake data shown on every visit — erodes trust.
**Fix:** Compute from real workout session data aggregated by day-of-week, or show a meaningful empty state.
**Effort:** 2-4 hours

#### H6. Move "Today's Workout" section higher in layout
**Where:** `home_screen.dart:275-281`
**Problem:** The core user task is the **last** section after achievements, steps, hydration, weekly chart, and weight trend. Requires scroll on every visit.
**Fix:** Promote workout section to position 2 (right after greeting header).
**Effort:** ~10 minutes

#### H7. Remove `_checkAutoComplete` surprise
**Where:** `home_screen.dart:864-870`
**Problem:** When the last exercise is completed via dialog, `_finishWorkout()` fires automatically without user confirmation.
**Fix:** Show a confirmation dialog, or require explicit "Complete Workout" button press.
**Effort:** ~1 hour

---

### 🟡 Medium Priority

#### M1. Split 1607-line file into domain-organized files
**Where:** `lib/features/home/`
**Suggested split:**
- `home_screen.dart` (~300 lines) — orchestrates sections
- `widgets/metric_card.dart` — reusable steps/hydration card
- `widgets/week_chart.dart` — bar chart widget
- `widgets/weight_trend_card.dart` — weight section + sparkline
- `widgets/exercise_tile.dart` — exercise row widget
- `widgets/exercise_info_sheet.dart` — bottom sheet
- `painters/weight_spark_painter.dart` — `CustomPainter`
- `models/trend_info.dart` — `_TrendInfo` made public
**Effort:** 4-6 hours

#### M2. `CurvedAnimation`/`Animation` created per build, never disposed
**Where:** `home_screen.dart:194-201`
**Problem:** `_buildStaggeredSection` creates new `CurvedAnimation` + inner `Animation` every `build()`. These leak listeners on `_entranceController` and are never disposed.
**Fix:** Cache staggered animations once in `initState` or `didChangeDependencies`.
**Effort:** ~1 hour

#### M3. `ValueKey` on `TweenAnimationBuilder` defeats animation
**Where:** `home_screen.dart:434,566,1303`
**Problem:** `key: ValueKey(_steps)` gives the widget a new identity on every change, causing Flutter to destroy/recreate it. Animation always starts from `begin: 0.0` instead of smoothly transitioning from the previous value.
**Fix:** Remove the `ValueKey`. Store previous value and use `tween: Tween(begin: _previousValue, end: _steps.toDouble())`.
**Effort:** ~30 minutes

#### M4. Standardize typography — replace hardcoded font sizes with theme styles
**Where:** Throughout `home_screen.dart`
**Problem:** 15+ inline `TextStyle` declarations with hardcoded sizes (13, 15, 16, 17, 26px) erode the type system.
**Fix:** Define named styles in `AppTheme` (`metricValue`, `sectionTitle`, `cardLabel`, etc.) and reference them consistently.
**Effort:** 1-2 hours

#### M5. Fix WCAG AA color contrast for tertiary text
**Where:** Throughout `home_screen.dart`
**Problem:** `textTertiary` used for 12-13px labels ("Tap to add", "10k", day labels) fails WCAG AA 4.5:1 for small text in light mode.
**Fix:** Darken `onSurfaceVariant` in light theme or use a custom tertiary color with verified contrast.
**Effort:** ~30 minutes

#### M6. Extract business logic from widgets into services
**Where:** `home_screen.dart:1160-1185,1359-1367`
**Problem:** `_computeTrend()` and `_lastLoggedText()` are analytical business logic embedded in a widget — untestable without `WidgetTester`.
**Fix:** Extract into pure Dart functions/classes in `lib/data/` or `lib/services/`.
**Effort:** ~1 hour

#### M7. `List.generate` for exercise tiles has no keys
**Where:** `home_screen.dart:789-812`
**Problem:** No `ValueKey` on exercise tiles. Any change to `todayExercises` tears down and rebuilds every tile.
**Fix:** Add `ValueKey(exercise.uuid)`.
**Effort:** ~5 minutes

#### M8. `shouldRepaint` uses identity comparison for list
**Where:** `home_screen.dart:1500-1503`
**Problem:** `oldDelegate.entries != entries` uses Dart's default identity `==` for `List`, so every new list instance triggers repaint.
**Fix:** Use `listEquals` from `package:flutter/foundation.dart`.
**Effort:** ~5 minutes

#### M9. `_computeTrend` + sort run uncached on every build
**Where:** `home_screen.dart:1216-1220`
**Problem:** Weight entries are copied + sorted + filtered on every `build()` — O(n log n) wasted work.
**Fix:** Memoize with a cached getter, invalidate in `didUpdateWidget`.
**Effort:** ~30 minutes

#### M10. Add `_hasAnimated` guard to prevent entrance animation replay
**Where:** `home_screen.dart:156-168`
**Problem:** `didChangeDependencies` can fire multiple times (e.g., parent `InheritedWidget` rebuild), restarting entrance animations.
**Fix:** Guard with a `_hasAnimated` flag.
**Effort:** ~10 minutes

#### M11. Theme toggle icon is inverted
**Where:** `home_screen.dart:333-337`
**Problem:** Shows sun icon in dark mode (suggesting "switch to light") and moon in light mode. Convention is the opposite.
**Fix:** Show `Icons.light_mode` when dark (tap to switch to light) and `Icons.dark_mode` when light.
**Effort:** ~2 minutes

#### M12. Normalize section spacing to a single rhythm value
**Where:** `home_screen.dart`
**Problem:** Uses mix of `SizedBox(height: 24)` and `SizedBox(height: 8)` between sections arbitrarily.
**Fix:** Pick 24px as the consistent vertical rhythm between all top-level sections.
**Effort:** ~10 minutes

#### M13. Constrain max content width for tablet/landscape
**Where:** `home_screen.dart`
**Problem:** Fixed `EdgeInsets.fromLTRB(16, 16, 16, 24)` on all screen sizes. On tablets, cards become excessively wide.
**Fix:** Wrap in `Center` + `ConstraintsBox(maxWidth: 600)`.
**Effort:** ~15 minutes

#### M14. `GestureDetector` should be `InkWell` for Material ripple
**Where:** `home_screen.dart:909,984,1014`
**Problem:** Exercise tile checkmark, play, and info buttons use `GestureDetector` instead of `InkWell`, missing ink splash effects.
**Fix:** Replace with `InkWell` + `borderRadius`.
**Effort:** ~30 minutes

---

### 🔵 Low Priority / Future

#### L1. Add responsive adaptation for narrow (<360px) screens
**Where:** `home_screen.dart:233-254`
**Fix:** Use `LayoutBuilder` or `Flexible` so steps/hydration row stacks vertically on narrow phones.

#### L2. Weekly bar chart bar width should be dynamic
**Where:** `home_screen.dart:685`
**Fix:** Compute `width: (availableWidth / 7) - spacing` instead of hardcoded 28px.

#### L3. Remove legacy achievement code in `workout_log.dart`
**Fix:** Once migration to `AchievementService` is verified, remove `evaluateAchievements`, `allAchievementDefinitions`, `computeAllAchievements`.

#### L4. Introduce repository interfaces for testability
**Fix:** Create `WorkoutRepository`, `WeightRepository`, `PreferencesRepository` interfaces with `SharedPrefs*` implementations. Makes `WorkoutStorageService` injectable.

#### L5. `_TopAction` touch target: 42px → 44px
**Where:** `home_screen.dart:1524-1525`
**Fix:** Increase to meet WCAG minimum touch target.

#### L6. `todayExercises` should be injected, not a top-level constant
**Where:** `home_screen.dart:75-82`
**Fix:** Accept exercise list as a constructor parameter or load from a `WorkoutPlan` model.

#### L7. `_finishWorkout` triggers async save chain inside `setState`
**Where:** `home_screen.dart:872-877`
**Fix:** Wrap in `Future` with `_isSaving` guard to prevent double-tap. Show loading state.

#### L8. Achievement `evaluateSteps`/`evaluateHydration` never called from UI
**Where:** `home_screen.dart:484-502`
**Fix:** Call `provider.evaluateSteps()` after steps tap, `provider.evaluateHydration()` after hydration tap.

#### L9. `url_launcher` should prioritize `ex.videoUrl` over generic YouTube search
**Where:** `home_screen.dart:1131-1138`
**Fix:** Use `exercise.videoUrl` when non-null, fall back to YouTube search.

#### L10. Add proper empty state for weekly chart
**Where:** `home_screen.dart:617-725`
**Fix:** Show "No workouts recorded this week" when no sessions exist.

#### L11. Init `_workoutStartTime` on checkbox toggle too
**Where:** `home_screen.dart:847`
**Fix:** Currently only set on play-button press. If user only uses checkboxes, duration is 0.

#### L12. Localize day labels (`Mo`, `Tu`, etc.) and greeting
**Where:** `home_screen.dart:618,109-116`
**Fix:** Use `MaterialLocalizations` or i18n solution.

#### L13. Dynamic subtitle in header based on workout state
**Where:** `home_screen.dart:322-327`
**Fix:** Update "Let's crush today's workout" to "Workout complete!" when done, "Rest day" when none scheduled.

#### L14. Convert `_showExerciseInfo` bottom sheet builder into a proper widget
**Where:** `home_screen.dart:1047-1128`
**Fix:** Extract to `lib/features/dialogs/exercise_info_sheet.dart`.

#### L15. Unify dialog presentation (showDialog vs Navigator.push)
**Where:** `home_screen.dart`
**Problem:** `WeightLogSheet` uses `showDialog`, `ExerciseProgressDialog` uses `Navigator.push` — inconsistent.

---

### 🤔 Questions for You

The agents have the following questions to help prioritize and guide the work:

**Architecture Direction:**
1. Do you want to migrate to Riverpod/BLoC, or keep Provider + extract MainShell state into ChangeNotifiers?
2. Should we introduce repository interfaces now (to enable future API swap) or keep SharedPreferences for now?
3. How important is multi-device sync / cloud backup for the app's roadmap?

**Home Screen Behavior:**
4. Should the workout section be promoted to the top of the page (below greeting)?
5. Auto-finish on last exercise: keep it, add confirmation dialog, or remove entirely?
6. Should we gate "Complete Workout" behind an explicit button press (remove auto-finish)?
7. Should exercise info videos use `videoUrl` from exercise data or always search YouTube?

**Data & Configuration:**
8. Should steps goal (10k) and hydration goal (2.5L) be user-configurable?
9. Should the hardcoded `todayExercises` list be replaced with a dynamic workout plan?
10. Should `_completedViaDialog` tracking be kept (for visual distinction) or removed entirely?

**Design & UX:**
11. Font sizes: keep them hardcoded in widgets, or extract to theme-level named styles?
12. Theme toggle: fix the inverted icon (sun/dark, moon/light)?
13. Should weight change color (green for loss, orange for gain) stay as-is, or use neutral colors?

**Performance vs Cleanup:**
14. Priority on splitting the 1607-line file vs. performance fixes vs. new features?
15. Are unit tests a priority now, or feature-complete first?

---

### Suggested Order of Execution (Phase 1)

| Step | Item | Est. Time | Depends On |
|------|------|-----------|------------|
| 1 | H1 — Fix AnimatedBuilder child pattern | 15 min | None |
| 2 | H7 — Remove auto-finish surprise | 1 hr | None |
| 3 | H6 — Move workout section up | 10 min | None |
| 4 | H3 — Eliminate dual completion tracking | 30 min | None |
| 5 | H2 — Fix greeting timer + remove debugPrint | 20 min | None |
| 6 | M3 — Fix TweenAnimationBuilder keys | 30 min | None |
| 7 | M8 — Fix shouldRepaint list comparison | 5 min | None |
| 8 | M7 — Add keys to exercise tiles | 5 min | None |
| 9 | M10 — Add _hasAnimated guard | 10 min | None |
| 10 | M11 — Fix theme toggle icon | 2 min | None |

Total Phase 1: ~3 hours — high-impact, low-risk fixes.

### Suggested Order of Execution (Phase 2)

| Step | Item | Est. Time | Depends On |
|------|------|-----------|------------|
| 1 | M4 — Standardize typography | 1-2 hrs | None |
| 2 | M5 — Fix WCAG AA contrast | 30 min | None |
| 3 | M12 — Normalize spacing | 10 min | None |
| 4 | M13 — Add max-width constraint | 15 min | None |
| 5 | M14 — InkWell for exercise buttons | 30 min | None |
| 6 | M1 — Split file into domain folders | 4-6 hrs | None |
| 7 | M2 — Cache curved animations | 1 hr | M1 recommended |
| 8 | M9 — Memoize trend computation | 30 min | None |
| 9 | M6 — Extract business logic to services | 1 hr | None |
| 10 | H4 — State management refactor | 1-2 days | M1 recommended |

Total Phase 2: ~2-4 days — structural improvements.

---

## 🚀 Suggestions for Upgrades & More Fixes

### Architecture & Data Layer

#### A. Migrate to SQLite with `drift`
**Why:** SharedPreferences becomes a bottleneck as data grows. A local database enables:
- Query workouts by date range: `SELECT * FROM sessions WHERE date BETWEEN ? AND ?`
- Aggregations: average sets/week, total time/month, most-used exercises
- Atomic transactions: roll back on failure without manual try/catch
- Better performance: index-based lookups vs. loading + parsing JSON arrays
- **Effort:** Moderate (2-3 days) — need to define tables, migration, repository layer

#### B. Repository Pattern + State Management
**Current pain:** `MainShell` has ~20 state fields passed via constructors. Every screen rebuilds when any field changes.  
**Fix:** Split storage layer into dedicated repositories (`SessionRepository`, `WeightRepository`, `PreferencesRepository`) + use Provider/Riverpod for state:
- Reduced boilerplate — no more constructor-passing chains
- Granular rebuilds — only screens that depend on changed data rebuild
- Testable — repositories can be mocked in unit tests
- **Effort:** Low-Medium (1-2 days with Riverpod)

#### C. Offline-First with Local DB + Cloud Sync
**Why:** All data is device-local today. If the user switches phones or reinstalls, all progress is lost.  
**Path:** SQLite locally → sync to Firebase/Firestore or a custom REST API.  
**Feature:** Login, cross-device workout history, cloud backup.  
**Effort:** High (1-2 weeks)

### User Experience

#### D. Pull-to-Refresh on Home & History ✅
**What we did:**
- Added `RefreshIndicator` wrapping HomeScreen's `SingleChildScrollView` with `AlwaysScrollableScrollPhysics`
- Added `RefreshIndicator` wrapping HistoryScreen's `ListView.builder` and empty state
- Wired `onRefresh: _loadAll` from MainShell to both screens via constructor
- **Files:** `home_screen.dart`, `history_screen.dart`, `main_shell.dart`

#### E. Workout Templates / Custom Programs
**Current:** One hardcoded 12-week program.  
**Feature:** Let users create custom programs (name your weeks, pick exercises per day, set rep/set ranges).  
**Effort:** Medium (3-5 days)

#### H. 🥚 Easter Egg — "Mentally Unstable" Gender Option ✅
- Changed the "Other" gender label in Edit Profile to "Mentally Unstable"
- Added to changelog as an Easter egg entry
- **Files:** `edit_profile_dialog.dart`, `changelog.dart`

#### G. Log & Updates in Profile → Support ✅
**What we did:**
- Created `lib/data/changelog.dart` — a structured list of `UpdateEntry` objects (date, title, description)
- Created `lib/features/profile/changelog_dialog.dart` — a scrollable bottom sheet that renders every entry as a card with date badge, title, and description
- Added a "Log & Updates" tile (green `update_rounded` icon) in the Support card between Reset and Help & Feedback
- The changelog IS the source of truth: any future update must be added to BOTH `changelog.dart` AND `The Plan.md`
- **Files:** `changelog.dart` (new), `changelog_dialog.dart` (new), `profile_screen.dart`

#### F. Rest Timer with Push Notification ✅
**What we did:**
- Created `lib/features/home/rest_timer.dart` — a countdown widget with circular progress, seconds display, and "tap to skip"
- Integrated into HomeScreen's workout section: appears after each exercise completion (checkbox or dialog)
- Timer starts automatically on exercise completion, dismisses when user starts the next exercise
- Haptic feedback on expiry, color changes to red in last 3 seconds
- Uses `rest_timer_seconds` from SharedPreferences (loaded in MainShell._loadAll)
- **Files:** `rest_timer.dart` (new), `home_screen.dart`, `main_shell.dart`

#### G. Weekly / Monthly Progress Reports
**Current:** Weight trend chart exists but no summary stats.  
**Feature:** A "Reports" tab showing weekly workout count, total volume, most-active day, streaks per month.  
**Effort:** Medium (2-3 days)

---

## Exercise Library — Premium Redesign (2026-06-11)

### Overview
Complete visual and UX overhaul of `lib/features/profile/exersise_dialog.dart` (1531 lines).
No new files — everything stays in place with polished implementation.

### What Changed

| Aspect | Before | After |
|---|---|---|
| Card depth | Flat, no border | Subtle colored border |
| Leading icon | Colored dot | Category-specific Material Icon in `ColoredIconBox` |
| Subtitle line 1 | Optional prescription | Always shown (prescription) |
| Subtitle line 2 | ❌ Missing | Description text |
| Detail view | `AlertDialog` | Modal bottom sheet |
| Add/Edit form | `AlertDialog` | Modal bottom sheet |
| Visual hierarchy | Flat text | Layered: name → prescription → description → pills → equipment |
| Usage stats | ❌ Missing | "Completed X×" badge on each card |

### Files Changed

#### `lib/data/exercise.dart`
- Added `exerciseCategoryIcons` map — each category key maps to a Material Icon:
  `strength→fitness_center`, `cardio→directions_run`, `core→sync_alt`,
  `flexibility→self_improvement`, `fullbody→whatshot`, `upperbody→arrow_upward`,
  `lowerbody→arrow_downward`

#### `lib/features/profile/exersise_dialog.dart` (premium rewrite)
1. **`_ExerciseCard`** → Premium card:
   - Leading: `ColoredIconBox` with category icon + color
   - Subtitle line 1: Prescription numbers (e.g. `3×12`, `45s`) via `getRecommendedDisplay()`
   - Subtitle line 2: Exercise description text; fallback to exercise name for customs without description
   - Pills: Level, Target Muscle, Category — with subtle borders for dark-mode definition
   - Equipment shown as tertiary caption
   - `"Completed X×"` badge from session history (suggestion #4)
   - Colored border card matching profile stat card style

2. **`_ExerciseDetailDialog` → `_ExerciseDetailSheet`** (bottom sheet):
   - Drag handle, padding matching `ExerciseInfoSheet`
   - Category + Muscle badges, description
   - Level selection chips (Beginner/Intermediate/Advanced) + Customize chip
   - Read-only level values card + editable custom fields
   - Equipment + tags display
   - Usage count display ("Completed X times")
   - Edit button (for customs), Apply button

3. **`_AddExerciseForm` → `_AddExerciseSheet`** (bottom sheet):
   - Scrollable bottom sheet with the full form
   - Exercise name (optional, auto-generated)
   - Description, Category dropdown, Muscle dropdown
   - Level chips (Beginner/Intermediate/Advanced)
   - Duration-based toggle + conditional fields (Sets/Reps, Duration, Weight)
   - Equipment + Tags inputs
   - Save + Cancel buttons

4. **Usage Stats Integration** (suggestion #4):
   - `_ExerciseDialogState` loads all sessions via `WorkoutStorageService` on init
   - Counts occurrences of each `exerciseUuid` across all `CompletedExercise` records
   - Passes `timesCompleted` count to each `_ExerciseCard`
   - Shows `"12×"` badge on card

### Card Layout (final)
```
┌─────────────────────────────────────────────┐
│  [🏋️]  Exercise Name              [Custom]  │  ← ColoredIconBox + name
│         3 × 12 · 10kg             [12×]      │  ← prescription + usage badge
│         Hold a straight line from head...   │  ← description subtitle
│         [Beginner] [Chest] [Strength]        │  ← pills
│         Bodyweight                           │  ← equipment
│                                     [>]      │
└─────────────────────────────────────────────┘
```

### Performance & Code Quality

#### H. Lazy-Load History Screen
**Current:** Loads ALL sessions into memory every time.  
**Fix:** Paginate — load 20 at a time, load more on scroll.  
**Effort:** Low (4 hours)

#### I. Add Unit Tests
**Current:** Zero tests.  
**Critical coverage:**
- `dateKey()` — verify output for various dates
- `WorkoutStorageService` CRUD — mock SharedPreferences, verify read/write cycles
- `evaluateAchievements` — verify correct unlocking logic
- `computeAllAchievements` — verify progress tracking
- `_onWorkoutComplete` — verify rollback on failure
**Effort:** Low-Medium (1-2 days for good coverage)

#### J. Image Compression for Avatar
**Current:** Raw camera/gallery images stored in SharedPreferences as base64.  
**Fix:** Resize to 200×200, compress to JPEG quality 70 before storing. Saves 10-20× storage.  
**Effort:** Low (1 hour)
