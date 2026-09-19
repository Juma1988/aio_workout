# Project Progress

## Current goal

Support user-created exercises and workout plans, including quick week cloning in the plan editor.

## Current state

- Built-in workout exercises and the default plan are removed from code paths.
- User-created exercise and workout-plan flows remain available.
- Debug-only `Copy path` body buttons are controlled by `isDebugMode` in `lib/main.dart`.
- Plan Editor now offers a 3:1 Add week / Clone a week split action.

## Next action

Continue the Add Exercise Wizard design and implementation.

## Verification

Focused workout tests pass. Flutter analyze reports no errors; existing informational lints remain.
