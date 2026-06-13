# AIO Workout — Task Instructions for Big Pickle

## Critical Rules
- Read EVERY file you modify before editing it.
- Run `flutter analyze` after each task. Fix ALL issues before moving on.
- Do NOT rename files: `exersise_dialog.dart`, `achivment_dialog.dart` keep their typo names.
- No state management library — use `setState` + `SharedPreferences`.
- All new dialogs go in `lib/features/dialogs/`.
- Animation tokens: `AppTheme.kAnimFast` (180ms), `kAnimMedium` (350ms), `kAnimEntrance` (950ms), `kAnimProgress` (600ms), `kEaseOut` (easeOutCubic).
- Accent colors: `AppTheme.achievementGreen` #22C55E, `AppTheme.stepsOrange` #F97316, `AppTheme.hydrationBlue` #3B82F6.
- SharedPreferences keys are plain strings, no constants file.
- No comments in code. None. Zero.
- Add `intl: ^0.20.2` to `pubspec.yaml` dependencies before starting.

---

## Task 1 — Home Screen: Equalize Steps & Hydration Card Height

**File:** `lib/features/home/home_screen.dart`

**What:** The Steps card and Hydration card (`_buildStepsCard` and `_buildHydrationCard`) must be the same height, matching the Achievement card above them.

**How:**
1. Find the `Row` that holds `_buildStepsCard` and `_buildHydrationCard` (wrapped in `_buildStaggeredSection` with `index: 2`).
2. Wrap each `Expanded(child: _buildStepsCard(...))` and `Expanded(child: _buildHydrationCard(...))` so both children have a fixed height.
3. Way to do it: wrap each card's `InkWell` (or the entire `Semantics > InkWell > Card` chain) with a `ConstrainedBox` with a fixed height. Use `ConstrainedBox(constraints: BoxConstraints(minHeight: 130))` or whatever value makes them match the Achievement card height. Pick a value that looks balanced.
4. Verify on both dark and light themes that the three cards (Achievement, Steps, Hydration) have the same visual height.

---

## Task 2 — Profile: Stat Cards — Fix Overflow (CRITICAL — 2.7px overflow visible)

**File:** `lib/features/profile/profile_screen.dart` — `_buildStats()` and `_buildStatCard()` methods

**What:** The three stat cards ("Workouts", "Day Streak", "Total Time") overflow by ~2.7 pixels (red overflow annotation visible). The layout must be fully dynamic/responsive — no fixed widths that break on different screen sizes.

**How:**

### 2a — Reduce the gap between cards
In `_buildStats()`, change the `SizedBox(width: 12)` between each `Expanded` child to `SizedBox(width: 6)`.

### 2b — Make layout fully responsive
Replace the current `Row` with a `LayoutBuilder` + `Row` approach:
```dart
LayoutBuilder(
  builder: (context, constraints) {
    final cardWidth = (constraints.maxWidth - 12) / 3; // 12 = 2 gaps of 6
    return Row(
      children: [
        _buildStatCard(context, ..., width: cardWidth),
        const SizedBox(width: 6),
        _buildStatCard(context, ..., width: cardWidth),
        const SizedBox(width: 6),
        _buildStatCard(context, ..., width: cardWidth),
      ],
    );
  },
)
```
Pass `width` as a parameter to `_buildStatCard` and use it for the card's `Container` or `Card` width constraint.

### 2c — Shrink internal padding and elements
Inside `_buildStatCard()`:
- Change padding from `EdgeInsets.all(12)` to `EdgeInsets.symmetric(horizontal: 8, vertical: 10)`
- Reduce `ColoredIconBox` size from `36` to `28`
- Reduce `ProgressRing` size from `44` to `36`
- Reduce gap between icon row and number from `SizedBox(height: 10)` to `SizedBox(height: 4)`
- Reduce the stat value font from `fontSize: 24` to `fontSize: 18`
- Reduce the label font from `fontSize: 12` to `fontSize: 11`

### 2d — Ensure circular progress indicators scale properly
The `ProgressRing` widget already uses relative sizing. With size 36 it should work fine. Verify no fixed pixel widths in the card content.

---

## Task 3 — Edit Profile: DOB → Age, Gender Centering, BMI

**File:** `lib/features/dialogs/edit_profile_dialog.dart`

**What:** Redesign the Edit Profile form with three improvements: Gender centered properly, Age calculated from Date of Birth (no static age field), BMI shown conditionally.

### 3a — Add `intl` dependency
Add `intl: ^0.20.2` to `pubspec.yaml` before starting.

### 3b — Gender: center align
The Gender `SegmentedButton` section must be fully center-aligned:
- Wrap the "Gender" label and the SegmentedButton in a `Center` widget
- OR set `alignment: WrapAlignment.center` if using Wrap
- The button group itself should be centered horizontally in the page

### 3c — Age: calculate dynamically from DOB (remove static age field)
- Add state: `DateTime? _dateOfBirth`
- SharedPreferences key: `'profile_dob'` stored as ISO date string (e.g. `"1997-06-15"`)
- **Add a new DOB field:**
  - A read-only `TextFormField` that displays the DOB in "Jun 15, 1997" format using `DateFormat.yMMMd()` from `intl`
  - Prefix icon: `Icons.calendar_today_outlined`
  - On tap: show `showDatePicker()` with `initialDatePickerMode: DatePickerMode.day`, max date: `DateTime.now()`, first date: `DateTime(1900, 1, 1)`
  - After user picks a date, store it in `_dateOfBirth` and update the controller
- **Remove the Age field entirely** — delete the `_age` state, `_ageController`, `_ageKey`, and the Age `TextFormField` from the UI
- **Calculate age from DOB on the fly:**
  - Add a getter: `int get _calculatedAge` that computes age from `_dateOfBirth` vs today:
  ```dart
  int get _calculatedAge {
    if (_dateOfBirth == null) return 0;
    final now = DateTime.now();
    int age = now.year - _dateOfBirth!.year;
    if (now.month < _dateOfBirth!.month ||
        (now.month == _dateOfBirth!.month && now.day < _dateOfBirth!.day)) {
      age--;
    }
    return age;
  }
  ```
  - Display the calculated age somewhere informative (e.g. as subtitle text below the DOB field: "Age: 28")

### 3d — BMI: conditional display
- Add a getter for BMI:
```dart
double? get _bmi {
  if (_weightKg <= 0 || _heightCm <= 0) return null;
  final heightM = _heightCm / 100;
  return _weightKg / (heightM * heightM);
}
```
- **Display logic:**
  - If both weight and height have values (both > 0), show BMI card below the Weight/Height row:
  ```dart
  if (_bmi != null)
    Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.subtleFill(context, 0.06),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.monitor_heart_outlined, color: AppTheme.textSecondary(context), size: 20),
          const SizedBox(width: 10),
          Text('BMI', style: TextStyle(color: AppTheme.textSecondary(context))),
          const Spacer(),
          Text(_bmi!.toStringAsFixed(1), style: TextStyle(
            color: AppTheme.textPrimary(context),
            fontWeight: FontWeight.w700,
            fontSize: 18,
          )),
          const SizedBox(width: 8),
          Text(_bmiCategory, style: TextStyle(
            color: _bmiColor,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          )),
        ],
      ),
    )
  ```
  - If weight or height is missing/null/0, show nothing (no placeholder, no "0", no "—", no "Calculate")
- **BMI category helper:**
```dart
String get _bmiCategory {
  final b = _bmi;
  if (b == null) return '';
  if (b < 18.5) return 'Underweight';
  if (b < 25) return 'Normal';
  if (b < 30) return 'Overweight';
  return 'Obese';
}
```
- **BMI color helper:**
```dart
Color get _bmiColor {
  final b = _bmi;
  if (b == null) return AppTheme.textSecondary(context);
  if (b < 18.5) return AppTheme.hydrationBlue;
  if (b < 25) return AppTheme.achievementGreen;
  if (b < 30) return AppTheme.stepsOrange;
  return Colors.red;
}
```

### 3e — Save/Load DOB
- In `_loadProfile()`: load `'profile_dob'` string, parse with `DateTime.tryParse()`, store in `_dateOfBirth`
- In `_saveProfile()`: save `_dateOfBirth?.toIso8601String().substring(0, 10)` to `'profile_dob'`
- Remove saving/loading of `_ageKey` since age is now calculated

### 3f — UI Order (top to bottom)
1. Avatar (Camera icon overlay, centered)
2. Full Name
3. Email
4. DOB (tap → date picker, shows age below as "Age: 28")
5. Weight & Height (side by side row)
6. BMI card (only if both weight+height have values)
7. Gender (centered)

---

## Task 4 — Profile: Fix Edit Profile Navigation

**File:** `lib/features/profile/profile_screen.dart`

**What:** `EditProfileDialog` is now a full-screen Scaffold page (Task 1 of previous session already converted it). Ensure `_openEditProfile()` uses `Navigator.push` (it already does) and reloads on return.

**Verify:**
```dart
void _openEditProfile() {
  HapticFeedback.lightImpact();
  Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => const EditProfileDialog()),
  ).then((_) => _loadAll());
}
```
Change `.then((result) { if (result == true) _loadAll(); })` to `.then((_) => _loadAll())` so it always reloads when returning from the edit page (even if back was pressed without saving).

---

## Task 5 — Profile: Add Home Screen Settings Card

**File:** `lib/features/profile/profile_screen.dart`

**What:** Add a new card under the "Preferences" section for "Home Screen Settings" with three toggles: Achievement, Steps, Hydration.

### 5a — SharedPreferences keys and default values
Add these as inline strings in `_loadAll`:
- `'home_show_achievement'` (bool, default `true`)
- `'home_show_steps'` (bool, default `true`)
- `'home_show_hydration'` (bool, default `true`)

### 5b — State
Add three bool fields: `_showAchievement = true;`, `_showSteps = true;`, `_showHydration = true;`

### 5c — Load/save
- In `_loadAll()`, load these three from SharedPreferences
- Create setters that save to prefs and call `setState`

### 5d — UI (in `_buildSettings`)
After the existing Preferences Card closes, add a new Card block:
```dart
const SizedBox(height: 20),
_buildSectionHeader(context, Icons.home_outlined, 'Home Screen'),
const SizedBox(height: 8),
Card(
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(16),
    side: BorderSide(
      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
      width: 1,
    ),
  ),
  elevation: 0,
  child: Column(
    children: [
      _buildSettingsTile(context,
        icon: Icons.emoji_events,
        title: 'Achievement',
        color: AppTheme.achievementGreen,
        subtitle: _showAchievement ? 'Visible' : 'Hidden',
        onTap: () => _toggleHomeCard('achievement'),
      ),
      _divider(context),
      _buildSettingsTile(context,
        icon: Icons.directions_run,
        title: 'Steps',
        color: AppTheme.stepsOrange,
        subtitle: _showSteps ? 'Visible' : 'Hidden',
        onTap: () => _toggleHomeCard('steps'),
      ),
      _divider(context),
      _buildSettingsTile(context,
        icon: Icons.water_drop,
        title: 'Hydration',
        color: AppTheme.hydrationBlue,
        subtitle: _showHydration ? 'Visible' : 'Hidden',
        onTap: () => _toggleHomeCard('hydration'),
      ),
    ],
  ),
),
```

### 5e — Toggle method
```dart
void _toggleHomeCard(String card) async {
  HapticFeedback.lightImpact();
  final prefs = await SharedPreferences.getInstance();
  setState(() {
    switch (card) {
      case 'achievement':
        _showAchievement = !_showAchievement;
        prefs.setBool('home_show_achievement', _showAchievement);
      case 'steps':
        _showSteps = !_showSteps;
        prefs.setBool('home_show_steps', _showSteps);
      case 'hydration':
        _showHydration = !_showHydration;
        prefs.setBool('home_show_hydration', _showHydration);
    }
  });
  widget.onHomeSettingsChanged?.call();
}
```

### 5f — ProfileScreen widget: add callback
Add to the `ProfileScreen` widget class:
```dart
final VoidCallback? onHomeSettingsChanged;
```
Pass through constructor. In `main_shell.dart`, wire it to a method that reloads home screen prefs and calls `setState`.

### 5g — Home Screen: Read settings
**File:** `lib/features/home/home_screen.dart`

Add props:
```dart
final bool showAchievementCard;
final bool showStepsCard;
final bool showHydrationCard;
```

In `build()`:
- Wrap `_buildAchievementCard` with `if (widget.showAchievementCard)`
- Wrap the Steps+Hydration Row: if neither shown, skip; if only one, show single full-width; if both, show Row

**File:** `lib/features/navigation/main_shell.dart`

- Add state fields: `_showAchievement`, `_showSteps`, `_showHydration`
- In `_loadAll()`: load from SharedPreferences
- Add `_loadHomeSettings()` method:
```dart
Future<void> _loadHomeSettings() async {
  final prefs = await SharedPreferences.getInstance();
  setState(() {
    _showAchievement = prefs.getBool('home_show_achievement') ?? true;
    _showSteps = prefs.getBool('home_show_steps') ?? true;
    _showHydration = prefs.getBool('home_show_hydration') ?? true;
  });
}
```
- Pass as callback to ProfileScreen: `onHomeSettingsChanged: _loadHomeSettings`
- Pass the bools to HomeScreen

---

## Task 6 — History: Move Subtitle into Card Header

**File:** `lib/features/history/history_screen.dart`

**What:** Remove "Week X • Day Y" as a standalone page subtitle. Instead, show it inside the current week's card header as a subtitle.

**How:**
1. Remove the `Padding` block containing "Week ${_progress.currentWeek} • Day ${_progress.currentDay}" from the page's build method.
2. Add two new fields to `_WeekCard`: `int currentWeek` and `int currentDay`.
3. In `_WeekCard.build()`, after the existing subtitle, add:
```dart
if (widget.week == widget.currentWeek)
  Text(
    'Day ${widget.currentDay}',
    style: TextStyle(
      color: AppTheme.textTertiary(context),
      fontSize: 12,
    ),
  ),
```
4. Pass the values when building `_WeekCard` instances.

---

## Task 7 — Exercise Timer: Complete Redesign (Fitness Tracker Bold)

**File:** `lib/features/dialogs/exercise_progress_dialog.dart`

**What:** Complete visual redesign. Go "fitness tracker bold" — gamified, energetic, large numbers, celebration effects.

### Requirements (in priority order):

#### 7a — Header
- Exercise name at top: `fontSize: 28`, `fontWeight: FontWeight.w800`
- Below: category pill + target muscle pill + level pill in a `Wrap`
- No app bar — use a close button (X) floating top-right and an info button (i) top-right

#### 7b — Progress section
- BIG centered number showing current set: e.g. `1` in font size 72, FontWeight.w900
- Below: "of 3" in smaller text
- Below that: a thick circular progress ring (stroke 10) showing fractional progress (e.g. 1/3 = 0.33)
- The ring should `TweenAnimationBuilder` from 0 to current progress
- Between the number and ring, a small green pill with "SET 1" text

#### 7c — "Complete Set" button (when NOT resting/holding)
- VERY large, prominent button: full width, height 72
- Icon: `Icons.fitness_center` or `Icons.check_circle` depending on state
- Text: "Complete Set" or "Start"
- Background: `colorScheme.primary` or `AppTheme.achievementGreen`
- Rounded corners: `BorderRadius.circular(20)`
- On first set, text is "START" with play icon. After that, text is "COMPLETE SET" with check icon.
- Add `TweenAnimationBuilder` scale bounce on press (scale 0.95 on tap down)

#### 7d — Rest timer (when resting)
- Full-width colored container (blue `AppTheme.hydrationBlue` tinted bg)
- Large timer number: `fontSize: 64`, monospace, centered
- Small "REST" label above the number
- Circular countdown ring around the number (sweeping, like a clock)
- Below: Pause/Play button and Skip button (small, circular, icon-only)
- When remaining ≤ 5s: color shifts to orange (`AppTheme.stepsOrange`)

#### 7e — Hold timer (for time-based exercises like plank)
- Same full-width colored container (blue tint)
- Large timer number: 64px
- "HOLD" label above
- Countdown ring around it (same circular sweep style)
- Skip button below: smaller text button "Skip Hold"

#### 7f — End Workout button
- Below the main action area
- Outlined style, red text/icon: `Icons.stop_circle_outlined`
- Height 48, standard styling

#### 7g — Celebration on completion
- When all sets complete (`_isComplete == true`):
  - Animated checkmark icon grows from 0 to 1 scale (use `TweenAnimationBuilder`)
  - Green ring fills from 0 to 1
  - "ALL SETS DONE!" in bold green 28px
  - "Great work!" in secondary 16px
  - "Back to Workout" button below (green filled)

---

## Task 8 — Profile: Avatar Reload on Return

**File:** `lib/features/profile/profile_screen.dart`

**What:** Ensure profile avatar and data reload when returning from Edit Profile page (even if back was pressed without saving).

**How:**
In `_openEditProfile()`, change the `.then` callback:
```dart
void _openEditProfile() {
  HapticFeedback.lightImpact();
  Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => const EditProfileDialog()),
  ).then((_) => _loadAll());
}
```
This always reloads after the edit page closes, regardless of whether changes were saved.

---

## Verification

After completing ALL tasks:
1. `flutter pub get` — must succeed
2. `flutter analyze` — must be zero issues
3. `flutter build apk --debug` — must succeed
4. Test on device:
   - **Home:** Steps/Hydration cards same height as Achievement
   - **Profile stats:** No overflow on any screen size — 3 cards fit cleanly
   - **Edit Profile:** Opens as full-screen page with AppBar, Gender centered, DOB picker works, Age shows dynamically from DOB, BMI appears when weight+height set, disappears when either is empty
   - **Timer:** fitness-tracker bold style, big numbers, celebration
   - **History:** "Day X" inside week card, not on page header
   - **Home Screen Settings:** Toggles in Profile → Preferences hide/show cards on Home
