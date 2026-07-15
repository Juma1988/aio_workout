# Suggestions for Improving the Exercise Library Page (exersise_dialog.dart)

This file captures ideas and feedback for the "Exercises" page (the exercise browser / library in the Profile tab).

## What Works Well (from UI/UX review)
- Scannable cards with emoji icons, colored category/target pills, and "Custom" badges.
- Horizontal filter chips ("tags side by side") including the special "★ Custom" filter — exactly what was requested.
- The "1 difficulty" form with the switch that grays out irrelevant numeric fields is clever and respects the model.
- Haptics, offline persistence via shared_preferences, search + filter combination, edit/delete flows.
- Recent "in list" improvements:
  - Cards now show the actual prescription numbers (`getRecommendedDisplay()` e.g. "3×12", "45s", "4×10 12kg") directly in the list — big win for glanceability.
  - Live animated result count with `TweenAnimationBuilder`.
  - Smooth `AnimatedSwitcher` fade when filters or search change.
  - Unique auto-generated names (`custom_exercise_01`, etc.) + collision handling so saves never fail on name.

- Consistent use of `AppTheme` helpers, `Card(elevation: 0, r16)`, `InkWell`, existing animation tokens.

## Suggested Improvements (prioritized)

### 1. List / "inlist" Polish (already strong — next level)
- **Swipe actions** on custom cards (using `Dismissible` or a package if allowed): left swipe to edit, right to delete with confirmation.
- **Grid view toggle** (list vs 2-column grid) for the results, with a small icon button in the header. Cards would need to adapt (stack icon + text vertically in grid).
- **Drag to reorder** customs (if we decide to let users control display order).
- **Quick stats** on card: small colored bar or dot indicating how many times used in history (future data hook).
- **Better empty states**: Instead of plain text, show an icon + "No exercises in this category yet" + prominent "Add custom" button that opens the form filtered to that category.

### 2. Add/Edit Form UX (biggest current pain point)
- **Promote to Modal Bottom Sheet** (`showModalBottomSheet` with `isScrollControlled: true` and a `DraggableScrollableSheet` or just a tall sheet). Gives much more room than `AlertDialog` for the many fields.
- **Improved numeric inputs**:
  - Use `TextFormField` with `inputFormatters` for digits only.
  - Add small +/- stepper buttons next to Sets / Reps / Duration / Weight (common in fitness apps).
  - Or segmented controls for common values.
- **Live preview** at the top of the form: show a mini card preview of how the exercise will look in the list (including the generated name if blank).
- **Smart defaults**: When user picks "core" category, default the switch to duration-based. When "strength", default to reps/sets.
- **Validation improvements**: Real-time duplicate name check (show warning "Name already exists — will be uniquified on save" instead of hard block).
- **Tags as chips**: Instead of comma text field, have a row of quick-add chips for common tags + free text entry.

### 3. General UX & Polish
- **Result count + active filters summary** in the header (already partially done) — make the count tappable to clear filters.
- **Keyboard handling**: `keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag` on the list. Dismiss keyboard when tapping a filter chip.
- **Animations & delight**:
  - Staggered entrance for cards when the page first opens (reuse the pattern from `home_screen.dart` with `AnimationController` + `Interval`).
  - Subtle scale or color flash on a card when it is newly added or its filter matches.
  - Hero animation from list card to the detail dialog (possible with `Hero` widget on the icon or name).
- **AppBar consistency**: The pushed page uses a standard `AppBar`. Consider a custom header that matches the no-AppBar style of the main tabs (large title + back button styled like the theme toggle actions).
- **Accessibility**: Add `Semantics` labels on filter chips and cards (e.g. "Core exercise: Plank, beginner, 3 sets of 30 seconds"). Ensure sufficient contrast on all pills.
- **Performance**: The list is small, but if it grows, consider `SliverList` + `CustomScrollView` or pagination. Debounce the search input (already suggested in review).
- **Multi-select / bulk actions**: Long-press to enter selection mode for deleting multiple customs at once.
- **Import / export**: Button to import custom exercises from JSON or share them (future).
- **Integration hooks**: Make the page return a selected exercise + chosen level when used as a picker (add optional `onSelect` callback or `pop` with result). This makes it reusable from Home or workout creation flows.

### 4. Data & Model Tweaks (small)
- Add a `usageCount` or last-used timestamp to custom exercises (stored in prefs) so we can sort "most used" or show "Recently added".
- Helper to format the full level details nicely for detail screen and future workout views.
- Consider a `isFavorite` flag on Exercise (for customs and eventually defaults) with a star icon on cards.

### 5. Mobile Builder Best Practices
- **Thumb zone**: Ensure primary actions (add +, filter chips, card taps) are reachable with one thumb.
- **Offline-first**: Already excellent (everything works without network). Add a "Sync" placeholder if we ever add cloud.
- **Platform feel**: On iOS the `BouncingScrollPhysics` on the filter row is nice. Consider `Cupertino` style for some sheets if we want hybrid feel, but Material3 is fine for the app.
- **Battery / perf**: Keep animation durations short (already using `kAnimFast`). Avoid unnecessary rebuilds by extracting stable widgets.
- **Testing**: Add widget tests for the list filtering, name uniquification logic, and form switch behavior.
- **Metrics**: Track (locally) how often users add customs vs browse defaults.

## Quick Wins to Implement Next (suggested order)
1. Bottom sheet for the add/edit form + live preview + stepper inputs.
2. Swipe-to-delete/edit on custom cards.
3. Staggered card entrance animation on page load.
4. Result count made tappable to "Clear filters".
5. Pre-fill suggested name is already done — maybe also show a small "Auto-generated" chip next to the name field when using the default.

## Notes
- Keep the simple `StatefulWidget` + `setState` style unless the page grows much larger.
- All suggestions stay within the existing `AppTheme`, animation tokens, and no new heavy dependencies.
- The page is in `profile/` but acts as a general library — that's fine for now.

Feel free to pick any item above and I'll create a focused implementation plan + execute it (following the Mobile App Builder persona: platform-aware, performance-focused, delightful UX, offline-first).

Last updated: based on latest list + name uniqueness improvements.
