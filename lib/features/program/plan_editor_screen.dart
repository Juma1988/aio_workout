import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/directional_icon.dart';
import '../../data/workout_plan.dart';
import '../../l10n/app_localizations.dart';
import '../../services/workout_storage_service.dart';
import 'day_exercise_picker_screen.dart';

/// Planning mode: name a plan, expand weeks, assign exercises per day.
class PlanEditorScreen extends StatefulWidget {
  final WorkoutPlan? initial;

  const PlanEditorScreen({super.key, this.initial});

  @override
  State<PlanEditorScreen> createState() => _PlanEditorScreenState();
}

class _PlanEditorScreenState extends State<PlanEditorScreen> {
  late final TextEditingController _nameCtrl;
  late List<PlanWeek> _weeks;
  late String _planId;
  late DateTime _createdAt;
  late String _initialSnapshot;
  int _expandedWeek = 1;
  bool _saving = false;

  bool get _isEdit => widget.initial != null;

  @override
  void initState() {
    super.initState();
    final init = widget.initial;
    if (init != null) {
      _planId = init.id;
      _createdAt = init.createdAt;
      _nameCtrl = TextEditingController(text: init.name);
      _weeks = _cloneWeeks(init.weeks);
      if (_weeks.isEmpty) _weeks = [PlanWeek.empty(1)];
      _expandedWeek = _weeks.first.weekNumber;
    } else {
      final blank = WorkoutPlan.create(name: '');
      _planId = blank.id;
      _createdAt = blank.createdAt;
      _nameCtrl = TextEditingController();
      _weeks = blank.weeks;
      _expandedWeek = 1;
    }
    _initialSnapshot = _snapshot();
    _nameCtrl.addListener(_onNameChanged);
  }

  List<PlanWeek> _cloneWeeks(List<PlanWeek> source) {
    return source
        .map(
          (w) => PlanWeek(
            weekNumber: w.weekNumber,
            days: w.days
                .map(
                  (d) => PlanDay(
                    dayNumber: d.dayNumber,
                    exercises: List<PlanExerciseSlot>.from(d.exercises),
                  ),
                )
                .toList(),
          ),
        )
        .toList();
  }

  String _snapshot() {
    final plan = WorkoutPlan(
      id: _planId,
      name: _nameCtrl.text.trim(),
      isDefault: false,
      weeks: _weeks,
      createdAt: _createdAt,
      updatedAt: _createdAt,
    );
    return jsonEncode(plan.toJson());
  }

  bool get _isDirty => _snapshot() != _initialSnapshot;

  @override
  void dispose() {
    _nameCtrl.removeListener(_onNameChanged);
    _nameCtrl.dispose();
    super.dispose();
  }

  void _onNameChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _handleBack() async {
    if (!_isDirty) {
      if (mounted) Navigator.of(context).pop(false);
      return;
    }
    final discard = await _confirmDiscard();
    if (discard && mounted) Navigator.of(context).pop(false);
  }

  void _toggleWeek(int weekNumber) {
    HapticFeedback.selectionClick();
    setState(() {
      _expandedWeek = _expandedWeek == weekNumber ? -1 : weekNumber;
    });
  }

  void _addWeek() {
    HapticFeedback.lightImpact();
    setState(() {
      final next = _weeks.length + 1;
      _weeks = [..._weeks, PlanWeek.empty(next)];
      _expandedWeek = next;
    });
  }

  void _removeLastWeek() {
    if (_weeks.length <= 1) return;
    HapticFeedback.mediumImpact();
    setState(() {
      _weeks = _weeks.sublist(0, _weeks.length - 1);
      if (_expandedWeek > _weeks.length) {
        _expandedWeek = _weeks.isEmpty ? -1 : _weeks.last.weekNumber;
      }
    });
  }

  Future<void> _editDay(int weekIndex, int dayIndex) async {
    HapticFeedback.lightImpact();
    final day = _weeks[weekIndex].days[dayIndex];
    final result = await Navigator.of(context).push<List<PlanExerciseSlot>>(
      MaterialPageRoute(
        builder: (_) => DayExercisePickerScreen(
          initiallySelected: day.exercises,
        ),
      ),
    );
    if (result == null || !mounted) return;
    setState(() {
      final week = _weeks[weekIndex];
      final days = List<PlanDay>.from(week.days);
      days[dayIndex] = day.copyWith(exercises: result);
      final weeks = List<PlanWeek>.from(_weeks);
      weeks[weekIndex] = week.copyWith(days: days);
      _weeks = weeks;
    });
  }

  Future<bool> _confirmDiscard() async {
    if (!_isDirty) return true;
    final l10n = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.plan_discardTitle),
        content: Text(l10n.plan_discardMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.plan_cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            child: Text(l10n.plan_discard),
          ),
        ],
      ),
    );
    return ok == true;
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.plan_nameRequired)),
      );
      return;
    }
    if (_weeks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.plan_needOneWeek)),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final plan = WorkoutPlan(
        id: _planId,
        name: name,
        isDefault: false,
        weeks: _weeks,
        createdAt: _createdAt,
        updatedAt: DateTime.now(),
      );
      await WorkoutStorageService().upsertUserPlan(plan);
      if (!mounted) return;
      _initialSnapshot = _snapshot();
      HapticFeedback.mediumImpact();
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${l10n.plan_saveError}: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return PopScope(
      canPop: !_isDirty,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _handleBack();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            _isEdit ? l10n.plan_editPlan : l10n.plan_newPlan,
          ),
          leading: IconButton(
            icon: DirectionalIcon(
              icon: Icons.arrow_back,
              color: AppTheme.textSecondary(context),
            ),
            onPressed: _saving ? null : _handleBack,
          ),
          actions: [
            TextButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(l10n.plan_save),
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            TextField(
              controller: _nameCtrl,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                labelText: l10n.plan_planName,
                hintText: l10n.plan_planNameHint,
                filled: true,
                fillColor: AppTheme.cardColor(context),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.plan_editorHint,
              style: TextStyle(
                color: AppTheme.textTertiary(context),
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Text(
                  l10n.plan_weeksSection,
                  style: TextStyle(
                    color: AppTheme.textPrimary(context),
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                if (_weeks.length > 1)
                  TextButton.icon(
                    onPressed: _removeLastWeek,
                    icon: const Icon(Icons.remove_circle_outline, size: 18),
                    label: Text(l10n.plan_removeWeek),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.redAccent,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            ..._weeks.asMap().entries.map((entry) {
              final wi = entry.key;
              final week = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _WeekCard(
                  week: week,
                  isExpanded: _expandedWeek == week.weekNumber,
                  onHeaderTap: () => _toggleWeek(week.weekNumber),
                  onDayTap: (di) => _editDay(wi, di),
                ),
              );
            }),
            _AddWeekCard(onTap: _addWeek, label: l10n.plan_addWeek),
          ],
        ),
      ),
    );
  }
}

class _WeekCard extends StatelessWidget {
  final PlanWeek week;
  final bool isExpanded;
  final VoidCallback onHeaderTap;
  final void Function(int dayIndex) onDayTap;

  const _WeekCard({
    required this.week,
    required this.isExpanded,
    required this.onHeaderTap,
    required this.onDayTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final accent = AppTheme.hydrationBlue;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: onHeaderTap,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        'W${week.weekNumber}',
                        style: TextStyle(
                          color: accent,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.dialog_weekLabel(week.weekNumber),
                          style: TextStyle(
                            color: AppTheme.textPrimary(context),
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          l10n.plan_exerciseCount(week.exerciseCount),
                          style: TextStyle(
                            color: AppTheme.textTertiary(context),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0,
                    duration: AppTheme.kAnimFast,
                    child: Icon(
                      Icons.expand_more,
                      color: AppTheme.textSecondary(context),
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: AppTheme.kAnimMedium,
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: isExpanded
                ? Column(
                    children: [
                      Divider(
                        height: 1,
                        color: AppTheme.subtleFill(context, 0.12),
                      ),
                      ...week.days.asMap().entries.map((e) {
                        final di = e.key;
                        final day = e.value;
                        return _DayRow(
                          day: day,
                          onTap: () => onDayTap(di),
                        );
                      }),
                      const SizedBox(height: 4),
                    ],
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class _DayRow extends StatelessWidget {
  final PlanDay day;
  final VoidCallback onTap;

  const _DayRow({required this.day, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final rest = day.isRest;
    final preview = day.exercises.take(3).map((e) => e.exerciseName).join(', ');
    final more = day.exercises.length > 3
        ? ' +${day.exercises.length - 3}'
        : '';

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: rest
                    ? AppTheme.subtleFill(context, 0.08)
                    : AppTheme.hydrationBlue.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: rest
                  ? Icon(
                      Icons.nightlight_round,
                      size: 14,
                      color: AppTheme.textTertiary(context),
                    )
                  : Text(
                      'D${day.dayNumber}',
                      style: TextStyle(
                        color: AppTheme.hydrationBlue,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    rest
                        ? l10n.dialog_rest
                        : l10n.plan_dayWithCount(
                            day.dayNumber,
                            day.exercises.length,
                          ),
                    style: TextStyle(
                      color: rest
                          ? AppTheme.textTertiary(context)
                          : AppTheme.textPrimary(context),
                      fontSize: 14,
                      fontWeight: rest ? FontWeight.w400 : FontWeight.w600,
                      fontStyle: rest ? FontStyle.italic : FontStyle.normal,
                    ),
                  ),
                  if (!rest && preview.isNotEmpty)
                    Text(
                      '$preview$more',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppTheme.textTertiary(context),
                        fontSize: 12,
                      ),
                    ),
                  if (rest)
                    Text(
                      l10n.plan_tapToAddExercises,
                      style: TextStyle(
                        color: AppTheme.textDisabled(context),
                        fontSize: 11,
                      ),
                    ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              size: 18,
              color: AppTheme.textDisabled(context),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddWeekCard extends StatelessWidget {
  final VoidCallback onTap;
  final String label;

  const _AddWeekCard({required this.onTap, required this.label});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 72,
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: Theme.of(context)
                .colorScheme
                .primary
                .withValues(alpha: 0.25),
            width: 1.5,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.add_circle_outline,
                  size: 28,
                  color: AppTheme.hydrationBlue,
                ),
                const SizedBox(width: 10),
                Text(
                  label,
                  style: TextStyle(
                    color: AppTheme.hydrationBlue,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
