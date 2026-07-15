import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/theme/app_theme.dart';
import '../../data/exercise.dart';
import '../../data/workout.dart';
import '../../services/workout_storage_service.dart';

/// Full-screen workout builder (create or edit a custom workout).
/// Shows name/focus fields, an exercise list with drag-to-reorder,
/// and an "Add Exercise" button that opens the exercise library picker.
class WorkoutBuilderScreen extends StatefulWidget {
  final Workout? initial; // null = create new, non-null = edit existing

  const WorkoutBuilderScreen({super.key, this.initial});

  @override
  State<WorkoutBuilderScreen> createState() => _WorkoutBuilderScreenState();
}

class _WorkoutBuilderScreenState extends State<WorkoutBuilderScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _estDurationCtrl;

  String _focus = 'fullbody';
  String _level = 'beginner';
  List<_WorkoutExercise> _exercises = [];
  bool _saving = false;

  bool get _isEdit => widget.initial != null;

  @override
  void initState() {
    super.initState();
    final init = widget.initial;
    _nameCtrl = TextEditingController(text: init?.name ?? '');
    _estDurationCtrl = TextEditingController(
      text: init?.estimatedDurationMinutes != null && init!.estimatedDurationMinutes > 0
          ? init.estimatedDurationMinutes.toString()
          : '',
    );
    _focus = init?.focus ?? 'fullbody';
    _level = init?.level ?? 'beginner';
    if (init != null) {
      _exercises = init.exercises.map((ref) => _WorkoutExercise.fromRef(ref)).toList();
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _estDurationCtrl.dispose();
    super.dispose();
  }

  // ── Save ──

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_exercises.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one exercise')),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      final now = DateTime.now();
      final workout = Workout(
        uuid: widget.initial?.uuid ?? 'workout-${now.millisecondsSinceEpoch}',
        name: _nameCtrl.text.trim(),
        isDefault: false,
        focus: _focus,
        level: _level,
        exercises: _exercises.map((we) => we.toRef()).toList(),
        estimatedDurationMinutes: int.tryParse(_estDurationCtrl.text.trim()) ?? 0,
        createdAt: widget.initial?.createdAt ?? now,
        createdByUserId: 'local',
      );

      final service = WorkoutStorageService();
      if (_isEdit) {
        await service.updateCustomWorkout(workout);
      } else {
        await service.addCustomWorkout(workout);
      }

      if (mounted) {
        Navigator.of(context).pop(workout);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEdit ? 'Workout updated' : 'Workout created'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ── Pick exercises from library ──

  Future<void> _openExercisePicker() async {
    HapticFeedback.lightImpact();
    final allExercises = [...defaultExercises];
    // Also load custom exercises from SharedPreferences
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString('custom_exercises');
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final decoded = (jsonDecode(jsonStr) as List<dynamic>)
            .map((j) => Exercise.fromJson(j as Map<String, dynamic>))
            .toList();
        allExercises.addAll(decoded);
      }
    } catch (_) {}

    final alreadySelected = _exercises.map((we) => we.exerciseId).toSet();

    final picked = await showModalBottomSheet<List<Exercise>>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _ExercisePickerSheet(
        exercises: allExercises,
        alreadySelected: alreadySelected,
      ),
    );

    if (picked != null && picked.isNotEmpty) {
      setState(() {
        for (final ex in picked) {
          final lvl = ex.getLevel(ex.recommendedLevel);
          _exercises.add(_WorkoutExercise(
            exerciseId: ex.uuid,
            exerciseName: ex.name,
            chosenLevel: ex.recommendedLevel,
            sets: lvl?.sets,
            reps: lvl?.reps,
            durationSeconds: lvl?.durationSeconds,
            weightKg: lvl?.weightKg,
          ));
        }
      });
    }
  }

  void _removeExercise(int index) {
    HapticFeedback.lightImpact();
    setState(() => _exercises.removeAt(index));
  }

  void _editExerciseValues(int index) async {
    HapticFeedback.lightImpact();
    final we = _exercises[index];
    final result = await showModalBottomSheet<_WorkoutExercise>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _EditExerciseSheet(exercise: we),
    );
    if (result != null) {
      setState(() => _exercises[index] = result);
    }
  }

  // ── Focus options ──

  static const _focusOptions = [
    ('fullbody', 'Full Body'),
    ('core', 'Core'),
    ('upperbody', 'Upper Body'),
    ('lowerbody', 'Lower Body'),
    ('cardio', 'Cardio'),
    ('strength', 'Strength'),
    ('flexibility', 'Flexibility'),
  ];

  static const _levelOptions = [
    ('beginner', 'Beginner'),
    ('intermediate', 'Intermediate'),
    ('advanced', 'Advanced'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Workout' : 'Create Workout'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          TextButton.icon(
            onPressed: _saving ? null : _save,
            icon: _saving
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.check),
            label: const Text('Save'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
          children: [
            // ── Workout Name ──
            TextFormField(
              controller: _nameCtrl,
              decoration: InputDecoration(
                labelText: 'Workout Name',
                hintText: 'e.g. Morning Core Blast',
                filled: true,
                fillColor: AppTheme.cardColor(context),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter a name' : null,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),

            // ── Focus Chips ──
            Text('Focus', style: TextStyle(color: AppTheme.textSecondary(context), fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _focusOptions.map((opt) {
                final selected = _focus == opt.$1;
                final cat = exerciseCategories[opt.$1];
                final color = cat?.color ?? AppTheme.textSecondary(context);
                return ChoiceChip(
                  label: Text(opt.$2),
                  selected: selected,
                  selectedColor: color.withValues(alpha: 0.25),
                  onSelected: (_) => HapticFeedback.selectionClick().then((_) => setState(() => _focus = opt.$1)),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // ── Level Chips ──
            Text('Difficulty', style: TextStyle(color: AppTheme.textSecondary(context), fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _levelOptions.map((opt) {
                final selected = _level == opt.$1;
                final lvl = Level.values.byName(opt.$1);
                return ChoiceChip(
                  label: Text(opt.$2),
                  selected: selected,
                  selectedColor: lvl.color.withValues(alpha: 0.25),
                  onSelected: (_) => HapticFeedback.selectionClick().then((_) => setState(() => _level = opt.$1)),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // ── Estimated Duration ──
            TextFormField(
              controller: _estDurationCtrl,
              decoration: InputDecoration(
                labelText: 'Estimated Duration (minutes)',
                hintText: 'e.g. 45',
                filled: true,
                fillColor: AppTheme.cardColor(context),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
            ),
            const SizedBox(height: 24),

            // ── Exercise List ──
            Row(
              children: [
                Icon(Icons.fitness_center, size: 18, color: AppTheme.textSecondary(context)),
                const SizedBox(width: 8),
                Text(
                  'Exercises (${_exercises.length})',
                  style: TextStyle(
                    color: AppTheme.textPrimary(context),
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                FilledButton.icon(
                  onPressed: _openExercisePicker,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    textStyle: const TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (_exercises.isEmpty)
              _buildEmptyState()
            else
              ...List.generate(_exercises.length, (i) {
                final we = _exercises[i];
                return _ExerciseTile(
                  key: ValueKey('${we.exerciseId}-$i'),
                  exercise: we,
                  index: i,
                  total: _exercises.length,
                  onRemove: () => _removeExercise(i),
                  onTap: () => _editExerciseValues(i),
                  onReorder: (oldIndex, newIndex) {
                    setState(() {
                      if (newIndex > oldIndex) newIndex -= 1;
                      final item = _exercises.removeAt(oldIndex);
                      _exercises.insert(newIndex, item);
                    });
                  },
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppTheme.subtleFill(context, 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.subtleFill(context, 0.1), width: 1),
      ),
      child: Column(
        children: [
          Icon(Icons.add_circle_outline, size: 48, color: AppTheme.textDisabled(context)),
          const SizedBox(height: 12),
          Text(
            'No exercises yet',
            style: TextStyle(color: AppTheme.textSecondary(context), fontSize: 15, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            'Tap "Add" to pick exercises from the library',
            style: TextStyle(color: AppTheme.textDisabled(context), fontSize: 13),
          ),
        ],
      ),
    );
  }
}

// ── Internal exercise model for the builder ──

class _WorkoutExercise {
  final String exerciseId;
  final String exerciseName;
  final Level chosenLevel;
  final int? sets;
  final int? reps;
  final int? durationSeconds;
  final double? weightKg;
  final String? notes;

  const _WorkoutExercise({
    required this.exerciseId,
    required this.exerciseName,
    required this.chosenLevel,
    this.sets,
    this.reps,
    this.durationSeconds,
    this.weightKg,
    this.notes,
  });

  factory _WorkoutExercise.fromRef(ExerciseRef ref) {
    // Look up exercise name from defaults or custom list
    String name = ref.exerciseId;
    for (final ex in defaultExercises) {
      if (ex.uuid == ref.exerciseId) {
        name = ex.name;
        break;
      }
    }
    // Try loading custom exercises for name lookup
    // (will be resolved at runtime if needed)

    return _WorkoutExercise(
      exerciseId: ref.exerciseId,
      exerciseName: name,
      chosenLevel: ref.chosenLevel ?? Level.beginner,
      sets: ref.sets,
      reps: ref.reps,
      durationSeconds: ref.durationSeconds,
      weightKg: ref.weightKg,
      notes: ref.notes,
    );
  }

  ExerciseRef toRef() {
    return ExerciseRef(
      exerciseId: exerciseId,
      chosenLevel: chosenLevel,
      sets: sets,
      reps: reps,
      durationSeconds: durationSeconds,
      weightKg: weightKg,
      notes: notes,
    );
  }

  String get display {
    final parts = <String>[];
    if (sets != null && reps != null) {
      parts.add('$sets × $reps');
    } else if (reps != null) {
      parts.add('$reps reps');
    } else if (durationSeconds != null) {
      parts.add('${durationSeconds}s');
    }
    if (weightKg != null) parts.add('${weightKg}kg');
    return parts.join(' • ');
  }

  _WorkoutExercise copyWith({
    String? exerciseId,
    String? exerciseName,
    Level? chosenLevel,
    int? sets,
    int? reps,
    int? durationSeconds,
    double? weightKg,
    String? notes,
  }) {
    return _WorkoutExercise(
      exerciseId: exerciseId ?? this.exerciseId,
      exerciseName: exerciseName ?? this.exerciseName,
      chosenLevel: chosenLevel ?? this.chosenLevel,
      sets: sets ?? this.sets,
      reps: reps ?? this.reps,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      weightKg: weightKg ?? this.weightKg,
      notes: notes ?? this.notes,
    );
  }
}

// ── Exercise Tile ──

class _ExerciseTile extends StatelessWidget {
  final _WorkoutExercise exercise;
  final int index;
  final int total;
  final VoidCallback onRemove;
  final VoidCallback onTap;
  final ReorderCallback onReorder;

  const _ExerciseTile({
    super.key,
    required this.exercise,
    required this.index,
    required this.total,
    required this.onRemove,
    required this.onTap,
    required this.onReorder,
  });

  @override
  Widget build(BuildContext context) {
    final lvlColor = exercise.chosenLevel.color;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Dismissible(
        key: ValueKey('dismiss-${exercise.exerciseId}-$index'),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          decoration: BoxDecoration(
            color: Colors.redAccent.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.delete_outline, color: Colors.redAccent),
        ),
        onDismissed: (_) => onRemove(),
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.cardColor(context),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.subtleFill(context, 0.1), width: 1),
            ),
            child: Row(
              children: [
                // Drag handle
                ReorderableDragStartListener(
                  index: index,
                  child: Icon(Icons.drag_handle, size: 20, color: AppTheme.textDisabled(context)),
                ),
                const SizedBox(width: 8),
                // Number badge
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: lvlColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(color: lvlColor, fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // Name + display
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        exercise.exerciseName,
                        style: TextStyle(
                          color: AppTheme.textPrimary(context),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (exercise.display.isNotEmpty)
                        Text(
                          exercise.display,
                          style: TextStyle(color: AppTheme.textTertiary(context), fontSize: 12),
                        ),
                    ],
                  ),
                ),
                // Level pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: lvlColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    exercise.chosenLevel.label,
                    style: TextStyle(color: lvlColor, fontSize: 10, fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(width: 4),
                Icon(Icons.chevron_right, size: 16, color: AppTheme.textDisabled(context)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Exercise Picker Sheet ──

class _ExercisePickerSheet extends StatefulWidget {
  final List<Exercise> exercises;
  final Set<String> alreadySelected;

  const _ExercisePickerSheet({
    required this.exercises,
    required this.alreadySelected,
  });

  @override
  State<_ExercisePickerSheet> createState() => _ExercisePickerSheetState();
}

class _ExercisePickerSheetState extends State<_ExercisePickerSheet> {
  String _search = '';
  String? _filter;
  final _selected = <String>{};

  List<Exercise> get _filtered {
    final q = _search.toLowerCase().trim();
    return widget.exercises.where((ex) {
      if (widget.alreadySelected.contains(ex.uuid)) return false;
      if (_filter != null && ex.categoryKey != _filter) return false;
      if (q.isEmpty) return true;
      return ex.name.toLowerCase().contains(q) ||
          (ex.description ?? '').toLowerCase().contains(q);
    }).toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;

    return DraggableScrollableSheet(
      initialChildSize: 0.8,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (ctx, scrollController) => Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.subtleFill(context, 0.30),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Pick Exercises',
                    style: TextStyle(
                      color: AppTheme.textPrimary(context),
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (_selected.isNotEmpty)
                  FilledButton(
                    onPressed: () => Navigator.of(context).pop(
                      widget.exercises.where((ex) => _selected.contains(ex.uuid)).toList(),
                    ),
                    child: Text('Add (${_selected.length})'),
                  ),
              ],
            ),
          ),
          // Search
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              onChanged: (v) => setState(() => _search = v),
              decoration: InputDecoration(
                hintText: 'Search exercises...',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _search.isNotEmpty
                    ? IconButton(icon: const Icon(Icons.clear, size: 18), onPressed: () => setState(() => _search = ''))
                    : null,
                filled: true,
                fillColor: AppTheme.cardColor(context),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
          // Category filters
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _filterChip('All', _filter == null, () => setState(() => _filter = null)),
                  const SizedBox(width: 6),
                  ...exerciseCategories.values.map((cat) => Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: _filterChip(cat.label, _filter == cat.key, () => setState(() => _filter = cat.key)),
                  )),
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),
          // List
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Text(
                      _search.isNotEmpty ? 'No matches for "$_search"' : 'No exercises available',
                      style: TextStyle(color: AppTheme.textTertiary(context)),
                    ),
                  )
                : ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: filtered.length,
                    itemBuilder: (ctx, i) {
                      final ex = filtered[i];
                      final isSel = _selected.contains(ex.uuid);
                      final cat = exerciseCategories[ex.categoryKey];
                      final color = cat?.color ?? AppTheme.textSecondary(context);
                      final display = ex.getRecommendedDisplay();

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Material(
                          color: isSel ? color.withValues(alpha: 0.08) : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () {
                              HapticFeedback.selectionClick();
                              setState(() {
                                if (isSel) {
                                  _selected.remove(ex.uuid);
                                } else {
                                  _selected.add(ex.uuid);
                                }
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSel
                                      ? color.withValues(alpha: 0.5)
                                      : AppTheme.subtleFill(context, 0.1),
                                  width: isSel ? 1.5 : 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: color.withValues(alpha: 0.10),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      exerciseCategoryIcons[ex.categoryKey] ?? Icons.fitness_center,
                                      size: 18,
                                      color: color,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          ex.name,
                                          style: TextStyle(
                                            color: AppTheme.textPrimary(context),
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        if (display.isNotEmpty)
                                          Text(
                                            display,
                                            style: TextStyle(color: AppTheme.textTertiary(context), fontSize: 12),
                                          ),
                                      ],
                                    ),
                                  ),
                                  if (isSel)
                                    Icon(Icons.check_circle, size: 20, color: color)
                                  else
                                    Icon(Icons.add_circle_outline, size: 20, color: AppTheme.textDisabled(context)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppTheme.textSecondary(context).withValues(alpha: 0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: AppTheme.subtleFill(context, 0.2), width: 1),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? AppTheme.textPrimary(context) : AppTheme.textTertiary(context),
            fontSize: 12,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

// ── Edit Exercise Values Sheet ──

class _EditExerciseSheet extends StatefulWidget {
  final _WorkoutExercise exercise;

  const _EditExerciseSheet({required this.exercise});

  @override
  State<_EditExerciseSheet> createState() => _EditExerciseSheetState();
}

class _EditExerciseSheetState extends State<_EditExerciseSheet> {
  late final TextEditingController _setsCtrl;
  late final TextEditingController _repsCtrl;
  late final TextEditingController _durCtrl;
  late final TextEditingController _weightCtrl;
  late Level _level;

  @override
  void initState() {
    super.initState();
    _setsCtrl = TextEditingController(text: widget.exercise.sets?.toString() ?? '');
    _repsCtrl = TextEditingController(text: widget.exercise.reps?.toString() ?? '');
    _durCtrl = TextEditingController(text: widget.exercise.durationSeconds?.toString() ?? '');
    _weightCtrl = TextEditingController(text: widget.exercise.weightKg?.toString() ?? '');
    _level = widget.exercise.chosenLevel;
  }

  @override
  void dispose() {
    _setsCtrl.dispose();
    _repsCtrl.dispose();
    _durCtrl.dispose();
    _weightCtrl.dispose();
    super.dispose();
  }

  void _apply() {
    Navigator.of(context).pop(
      widget.exercise.copyWith(
        chosenLevel: _level,
        sets: int.tryParse(_setsCtrl.text),
        reps: int.tryParse(_repsCtrl.text),
        durationSeconds: int.tryParse(_durCtrl.text),
        weightKg: double.tryParse(_weightCtrl.text),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(color: AppTheme.subtleFill(context, 0.30), borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 20),
          Text(
            widget.exercise.exerciseName,
            style: TextStyle(color: AppTheme.textPrimary(context), fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),

          // Level chips
          Text('Level', style: TextStyle(color: AppTheme.textSecondary(context), fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [Level.beginner, Level.intermediate, Level.advanced].map((lvl) {
              final selected = _level == lvl;
              return ChoiceChip(
                label: Text(lvl.label),
                selected: selected,
                selectedColor: lvl.color.withValues(alpha: 0.3),
                onSelected: (_) => setState(() => _level = lvl),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // Values
          _field('Sets', _setsCtrl, TextInputType.number),
          const SizedBox(height: 10),
          _field('Reps', _repsCtrl, TextInputType.number),
          const SizedBox(height: 10),
          _field('Duration (seconds)', _durCtrl, TextInputType.number),
          const SizedBox(height: 10),
          _field('Weight (kg)', _weightCtrl, const TextInputType.numberWithOptions(decimal: true)),

          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: FilledButton(onPressed: _apply, child: const Text('Apply')),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _field(String label, TextEditingController ctrl, TextInputType type) {
    return Row(
      children: [
        SizedBox(
          width: 140,
          child: Text(label, style: TextStyle(color: AppTheme.textSecondary(context), fontSize: 13)),
        ),
        Expanded(
          child: TextField(
            controller: ctrl,
            keyboardType: type,
            style: TextStyle(color: AppTheme.textPrimary(context)),
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ),
      ],
    );
  }
}
