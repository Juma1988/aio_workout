import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/exercise_visuals.dart';
import '../../../data/exercise.dart';
import '../../../data/workout.dart';

/// Bottom sheet for managing custom workouts with template plans.
class CustomWorkoutsBottomSheet extends StatefulWidget {
  final List<Workout> customWorkouts;
  final void Function(Workout) onEdit;
  final void Function(Workout) onDelete;
  final VoidCallback onCreateNew;
  final void Function(Workout) onCreateFromTemplate;

  const CustomWorkoutsBottomSheet({
    super.key,
    required this.customWorkouts,
    required this.onEdit,
    required this.onDelete,
    required this.onCreateNew,
    required this.onCreateFromTemplate,
  });

  @override
  State<CustomWorkoutsBottomSheet> createState() => _CustomWorkoutsBottomSheetState();
}

class _CustomWorkoutsBottomSheetState extends State<CustomWorkoutsBottomSheet> {
  static const _accent = Color(0xFF00E676);
  static const _bg = Color(0xFF0D1117);
  static const _cardBg = Color(0xFF161B22);
  static const _cardBorder = Color(0xFF21262D);

  static final _templates = [
    _TemplatePlan(
      name: 'Core Foundation',
      focus: 'core',
      level: 'beginner',
      exercises: ['ex-birddog-001', 'ex-cocoons-001'],
      tag: 'FOUNDATION',
      color: Color(0xFF2196F3),
    ),
    _TemplatePlan(
      name: 'Upper Blast',
      focus: 'upperbody',
      level: 'intermediate',
      exercises: ['ex-pushups-001', 'ex-overheadpress-001', 'ex-bicepcurls-001'],
      tag: 'BUILDING',
      color: Color(0xFFFF9800),
    ),
    _TemplatePlan(
      name: 'Leg Day Power',
      focus: 'lowerbody',
      level: 'intermediate',
      exercises: ['ex-squats-001', 'ex-glutebridge-001', 'ex-sidelyinglegraise-001'],
      tag: 'BUILDING',
      color: Color(0xFF00BCD4),
    ),
    _TemplatePlan(
      name: 'Cardio Burn',
      focus: 'cardio',
      level: 'beginner',
      exercises: ['ex-jumpingjacks-001'],
      tag: 'CARDIO',
      color: Color(0xFFE91E63),
    ),
    _TemplatePlan(
      name: 'Full Body Shred',
      focus: 'fullbody',
      level: 'advanced',
      exercises: ['ex-pushups-001', 'ex-squats-001', 'ex-overheadpress-001', 'ex-glutebridge-001'],
      tag: 'PEAK',
      color: Color(0xFFF44336),
    ),
    _TemplatePlan(
      name: 'Strength Base',
      focus: 'strength',
      level: 'beginner',
      exercises: ['ex-pushups-001', 'ex-squats-001', 'ex-bicepcurls-001'],
      tag: 'FOUNDATION',
      color: Color(0xFFFF5722),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dateStr = '${now.day}/${now.month}/${now.year}';

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: _accent.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          _buildHeroCard(context, dateStr),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Row(
              children: [
                Container(
                  width: 3,
                  height: 14,
                  decoration: BoxDecoration(
                    color: _accent,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'CUSTOM WORKOUTS',
                  style: TextStyle(
                    color: _accent,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                  ),
                ),
                const Spacer(),
                if (widget.customWorkouts.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '${widget.customWorkouts.length}',
                      style: TextStyle(color: _accent, fontSize: 11, fontWeight: FontWeight.w700),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                if (widget.customWorkouts.isNotEmpty) ...[
                  _buildWorkoutGrid(context, widget.customWorkouts, isCustom: true),
                  const SizedBox(height: 20),
                ],
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Container(
                        width: 3,
                        height: 14,
                        decoration: BoxDecoration(
                          color: _accent.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'STARTER PLANS',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildWorkoutGrid(context, [], isCustom: false),
                const SizedBox(height: 20),
                _buildCreateFromScratchCard(context),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroCard(BuildContext context, String dateStr) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _accent.withValues(alpha: 0.15),
            _accent.withValues(alpha: 0.05),
          ],
        ),
        border: Border.all(color: _accent.withValues(alpha: 0.3), width: 1),
        boxShadow: [
          BoxShadow(
            color: _accent.withValues(alpha: 0.1),
            blurRadius: 20,
            spreadRadius: -5,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _accent.withValues(alpha: 0.15),
              boxShadow: [
                BoxShadow(
                  color: _accent.withValues(alpha: 0.3),
                  blurRadius: 16,
                  spreadRadius: -2,
                ),
              ],
            ),
            child: Icon(Icons.bolt, size: 28, color: _accent),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'My Custom Plan',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$dateStr  •  ${widget.customWorkouts.length} plans',
                  style: TextStyle(
                    color: _accent.withValues(alpha: 0.7),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: _accent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${widget.customWorkouts.length}',
              style: TextStyle(
                color: _accent,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkoutGrid(BuildContext context, List<Workout> workouts, {required bool isCustom}) {
    if (isCustom && workouts.isEmpty) return const SizedBox.shrink();
    final items = isCustom ? workouts : _templates;

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: items.map((item) {
        if (isCustom) {
          return _buildExistingWorkoutCard(context, item as Workout);
        } else {
          return _buildTemplateCard(context, item as _TemplatePlan);
        }
      }).toList(),
    );
  }

  Widget _buildExistingWorkoutCard(BuildContext context, Workout workout) {
    final color = ExerciseVisuals.categoryColor(workout.focus);

    return GestureDetector(
      onTap: () => widget.onEdit(workout),
      onLongPress: () => _showDeleteDialog(context, workout),
      child: Container(
        width: (MediaQuery.of(context).size.width - 42) / 2,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _accent.withValues(alpha: 0.3), width: 1),
          boxShadow: [
            BoxShadow(
              color: _accent.withValues(alpha: 0.08),
              blurRadius: 12,
              spreadRadius: -3,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: _accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.bolt, size: 18, color: _accent),
                ),
                const Spacer(),
                Icon(Icons.edit_outlined, size: 16, color: Colors.white.withValues(alpha: 0.3)),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              workout.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                _tag('${workout.exercises.length} ex', _accent),
                const SizedBox(width: 6),
                _tag(workout.level, color),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTemplateCard(BuildContext context, _TemplatePlan template) {
    return GestureDetector(
      onTap: () {
        final workout = Workout(
          uuid: 'template-${template.name.toLowerCase().replaceAll(' ', '-')}',
          name: template.name,
          isDefault: false,
          focus: template.focus,
          level: template.level,
          exercises: template.exercises.map((id) => ExerciseRef(exerciseId: id)).toList(),
          estimatedDurationMinutes: template.exercises.length * 5,
          createdAt: DateTime.now(),
        );
        widget.onCreateFromTemplate(workout);
      },
      child: Container(
        width: (MediaQuery.of(context).size.width - 42) / 2,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _cardBorder, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: template.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.add, size: 20, color: template.color),
                ),
                const Spacer(),
                Icon(Icons.arrow_forward_ios, size: 12, color: Colors.white.withValues(alpha: 0.2)),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              template.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                _tag('${template.exercises.length} ex', template.color),
                const SizedBox(width: 6),
                _tag(template.tag, template.color),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCreateFromScratchCard(BuildContext context) {
    return GestureDetector(
      onTap: widget.onCreateNew,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _accent.withValues(alpha: 0.2), width: 1),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_accent.withValues(alpha: 0.06), Colors.transparent],
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(Icons.add_circle_outline, size: 24, color: _accent),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Create From Scratch',
                    style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Build your own custom workout routine',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 12),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 14, color: _accent.withValues(alpha: 0.5)),
          ],
        ),
      ),
    );
  }

  Widget _tag(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.3),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, Workout workout) {
    HapticFeedback.mediumImpact();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Delete "${workout.name}"?', style: const TextStyle(color: Colors.white)),
        content: Text(
          'This will permanently remove this custom workout.',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cancel', style: TextStyle(color: Colors.white.withValues(alpha: 0.5))),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              widget.onDelete(workout);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }
}

class _TemplatePlan {
  final String name;
  final String focus;
  final String level;
  final List<String> exercises;
  final String tag;
  final Color color;

  const _TemplatePlan({
    required this.name,
    required this.focus,
    required this.level,
    required this.exercises,
    required this.tag,
    required this.color,
  });
}
