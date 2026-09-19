# Page Brainstorming

Use this note to discuss each page before implementation. Ideas are proposals only; nothing here changes the app until approved.

## Decision language

- **Keep** — current page is good; only polish if needed.
- **Upgrade** — preserve the flow but improve clarity, hierarchy, accessibility, or feedback.
- **Remake** — redesign the flow or structure substantially.
- **Investigate** — we need evidence before choosing.

## Priority board

| Page | Decision | Why | Next question | Status |
|---|---|---|---|---|
| HomeScreen | Upgrade | Important daily overview; current density reduces clarity | What should be visible in the first viewport? | Open |
| ProfileScreen | Upgrade | Identity, stats, and settings compete for attention | What is the primary profile action? | Open |
| WorkoutPlanScreen | Upgrade / investigate | Long plan view can overwhelm users | Should users browse by week, phase, or day? | Open |
| WorkoutBuilderScreen | Investigate | Editing and selecting exercises are dense | Should building be a guided step-by-step flow? | Open |
| ExerciseProgressDialog | Upgrade | Active workout needs fast, glanceable controls | What must be reachable with one hand? | Open |
| ExerciseDialog | Upgrade | Library and custom exercise creation are mixed | Should browsing and creating be separate flows? | Open |

## HomeScreen

**Current assessment:** Good foundation, but metric cards are dense, exercise tiles lack hierarchy, the weekly chart is unclear, and metric empty states are missing.

### Ideas

- [ ] Show one primary daily goal above secondary metrics.
- [ ] Make the next workout the dominant action.
- [ ] Use clearer chart labels and a concise time summary.
- [ ] Add friendly empty states for steps, hydration, and weight.
- [ ] Consider a compact “Today” / “Progress” split.

**Decision:** Upgrade / Remake / Keep  
**Notes:**

## ProfileScreen

**Current assessment:** Functional, but the header is plain and settings, stats, and achievements compete.

### Ideas

- [ ] Add a stronger identity header with avatar and greeting.
- [ ] Group account, preferences, notifications, and support separately.
- [ ] Make progress stats scannable.
- [ ] Clarify the avatar upload action.

**Decision:** Upgrade / Remake / Keep  
**Notes:**

## WorkoutPlanScreen

**Current assessment:** The 12-week plan and custom-workout controls can feel overwhelming.

### Ideas

- [ ] Collapse weeks or phases by default.
- [ ] Add clear current-week and current-day emphasis.
- [ ] Color-code phases consistently.
- [ ] Simplify the custom-workout entry point.

**Decision:** Upgrade / Remake / Keep  
**Notes:**

## WorkoutBuilderScreen

**Current assessment:** Exercise selection, editing, and reordering need clearer interaction cues.

### Ideas

- [ ] Separate exercise selection from exercise editing.
- [ ] Add a visible drag handle and reorder feedback.
- [ ] Use a step-based builder: details → exercises → review.
- [ ] Add a preview before saving.

**Decision:** Upgrade / Remake / Keep  
**Notes:**

## ExerciseProgressDialog

**Current assessment:** Timer, sets, reps, and rest controls are dense during an active workout.

### Ideas

- [ ] Make the current set the visual focus.
- [ ] Keep timer and rest status always understandable.
- [ ] Support quick completion with large touch targets.
- [ ] Add clear recovery/rest feedback.

**Decision:** Upgrade / Remake / Keep  
**Notes:**

## ExerciseDialog

**Current assessment:** Filtering and custom exercise creation could be clearer; the source filename has a typo.

### Ideas

- [ ] Separate browse, filter, and create actions.
- [ ] Add an exercise preview card.
- [ ] Shorten the custom exercise form.
- [ ] Rename `exersise_dialog.dart` to `exercise_dialog.dart` in a dedicated cleanup task.

**Decision:** Upgrade / Remake / Keep  
**Notes:**

## Questions for the next session

1. Which page should we redesign first?
2. Which page feels most frustrating when you use the app?
3. Should the visual direction be calm/minimal, energetic, or data-focused?
4. Which actions should always be reachable with one hand?
5. Are any existing pages or flows no longer needed?
