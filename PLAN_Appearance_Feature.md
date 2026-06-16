# Implementation Plan: Profile > Appearance Feature

## Date: 2026-06-14

---

## Feature Overview

### 1. Steps Target (Long-press gear icon)
**What:** Edit daily step goal from Appearance dialog
- Long-press gear icon on Steps row → opens StepGoalDialog
- Range: 1,000 – 50,000 steps (step by 500)
- Default: 10,000 steps

### 2. Hydration Target (Long-press gear icon)
**What:** Set daily water intake goal with smart auto-calculation
- Long-press gear icon on Hydration row → opens HydrationGoalDialog
- **Auto mode:** weight_kg × 0.035 (rounded to 0.25L)
- **Manual mode:** Slider + text input (1.0L – 5.0L)
- **Fallback:** If no weight set → default 70kg (2.45L) with hint "Set weight in Profile"

### 3. Hydration Reminder (Notification Settings)
**What:** Periodic reminders to drink water with dynamic calculation
- Location: Notification Settings → Hydration Reminder card
- **Intervals:** 30 min, 1 hour, 2 hours, 3 hours
- **Active hours:** Configurable start/end (default 8 AM – 10 PM)
- **Dynamic calculation:**
  ```
  Waking hours = 24h - Quiet hours
  Reminders = Waking hours / Interval
  Amount per reminder = Target / Reminders
  ```
- **Behavior:** Suppresses when daily target is met
- **Message:** "Time to hydrate! Drink ~{amount}mL to stay on track 💧"

---

## Files to Modify/Create

### New Files
| File | Purpose |
|------|---------|
| `lib/features/dialogs/hydration_goal_dialog.dart` | Hydration goal picker (auto/manual) |
| `lib/features/notifications/widgets/hydration_reminder_sheet.dart` | Reminder config UI |

### Modified Files
| File | Changes |
|------|---------|
| `lib/features/profile/home_settings_dialog.dart` | Add long-press handlers + storage functions |
| `lib/features/home/home_screen.dart` | Replace hardcoded 2.5L with dynamic goal |
| `lib/features/navigation/main_shell.dart` | Add hydration goal state + reload |
| `lib/features/notifications/notification_settings_screen.dart` | Add hydration reminder card |
| `lib/features/notifications/services/notification_service.dart` | Add hydration scheduling |
| `lib/features/notifications/services/notification_repository.dart` | Add hydration prefs |
| `lib/l10n/app_en.arb` | Add English strings |
| `lib/l10n/app_ar.arb` | Add Arabic strings |
| `lib/data/changelog.dart` | Add feature entry |
| `The Plan.md` | Add feature documentation |

---

## User Decisions (from Q&A)

| Question | Answer |
|----------|--------|
| Steps target access | Long-press gear icon |
| Auto-calc fallback | Default 70kg with "Set weight in Profile" hint |
| Rounding | 0.25L for cleaner display |
| Goal range | 1.0L – 5.0L |
| Reminder message | Predefined dynamic message |
| Suppress when met | YES - don't remind if target reached |
| Reminder location | Notification Settings |
| Frequency options | 30m, 1h, 2h, 3h, Custom |
| Localization | English + Arabic simultaneously |
| Backend sync | Local-only for now |

---

## Implementation Status

- [x] Steps target (long-press gear)
- [x] Hydration target (auto/manual)
- [x] Hydration reminder (notification settings)
- [x] Dynamic goal in home screen
- [x] Localization (EN + AR)
- [x] Changelog updated
- [x] The Plan.md updated
- [x] Fixed: Goal recalculates when weight changes
- [x] Fixed: Reminder uses dynamic goal (not hardcoded 2.5L)

---

## Testing Checklist

- [ ] Long-press Steps gear → opens StepGoalDialog
- [ ] Long-press Hydration gear → opens HydrationGoalDialog
- [ ] Auto-calc shows correct value based on weight
- [ ] Changing weight updates hydration goal
- [ ] Manual mode saves custom goal
- [ ] Hydration reminder appears in Notification Settings
- [ ] Reminder shows correct amount per interval
- [ ] Reminder suppresses when target met
- [ ] Arabic strings display correctly
