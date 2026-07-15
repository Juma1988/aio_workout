import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_theme.dart';
import '../../data/workout_plan.dart';
import '../../l10n/app_localizations.dart';
import '../../services/workout_storage_service.dart';
import 'plan_editor_screen.dart';
import 'workout_plan_screen.dart';

/// List of workout plans: built-in default + user plans + add card.
class PlanHubScreen extends StatefulWidget {
  const PlanHubScreen({super.key});

  @override
  State<PlanHubScreen> createState() => _PlanHubScreenState();
}

class _PlanHubScreenState extends State<PlanHubScreen> {
  List<WorkoutPlan> _plans = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final plans = await WorkoutStorageService().loadUserPlans();
      if (!mounted) return;
      setState(() {
        _plans = plans;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _openDefault() async {
    HapticFeedback.lightImpact();
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const WorkoutPlanScreen()),
    );
  }

  Future<void> _openCreate() async {
    HapticFeedback.lightImpact();
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const PlanEditorScreen()),
    );
    if (!mounted) return;
    if (saved == true) {
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).plan_saved)),
      );
    }
  }

  Future<void> _openEdit(WorkoutPlan plan) async {
    HapticFeedback.lightImpact();
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => PlanEditorScreen(initial: plan)),
    );
    if (!mounted) return;
    if (saved == true) {
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).plan_saved)),
      );
    }
  }

  Future<void> _confirmDelete(WorkoutPlan plan) async {
    final l10n = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.plan_deleteTitle),
        content: Text(l10n.plan_deleteMessage(plan.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.plan_cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            child: Text(l10n.plan_delete),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await WorkoutStorageService().deleteUserPlan(plan.id);
    HapticFeedback.mediumImpact();
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.profile_workoutPlan),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline,
                            size: 48, color: Colors.redAccent),
                        const SizedBox(height: 12),
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppTheme.textSecondary(context),
                          ),
                        ),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: _load,
                          child: Text(l10n.plan_retry),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                    children: [
                      Text(
                        l10n.plan_hubSubtitle,
                        style: TextStyle(
                          color: AppTheme.textTertiary(context),
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _PlanCard(
                        title: l10n.plan_defaultTitle,
                        weeks: WorkoutPlan.defaultPlanWeeks,
                        exercises: WorkoutPlan.defaultPlanExerciseTotal(),
                        isDefault: true,
                        onTap: _openDefault,
                      ),
                      const SizedBox(height: 12),
                      ..._plans.map(
                        (p) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _PlanCard(
                            title: p.name,
                            weeks: p.weekCount,
                            exercises: p.totalExercises,
                            isDefault: false,
                            onTap: () => _openEdit(p),
                            onDelete: () => _confirmDelete(p),
                          ),
                        ),
                      ),
                      _AddPlanCard(
                        label: l10n.plan_newPlan,
                        onTap: _openCreate,
                      ),
                    ],
                  ),
                ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final String title;
  final int weeks;
  final int exercises;
  final bool isDefault;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  const _PlanCard({
    required this.title,
    required this.weeks,
    required this.exercises,
    required this.isDefault,
    required this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final accent =
        isDefault ? AppTheme.hydrationBlue : AppTheme.achievementGreen;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 108),
        child: Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: onTap,
                onLongPress: onDelete,
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          isDefault ? Icons.auto_awesome : Icons.route,
                          color: accent,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: AppTheme.textPrimary(context),
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: accent.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    isDefault
                                        ? l10n.plan_defaultBadge
                                        : l10n.plan_customBadge,
                                    style: TextStyle(
                                      color: accent,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              l10n.plan_cardStats(weeks, exercises),
                              style: TextStyle(
                                color: AppTheme.textTertiary(context),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (onDelete == null)
                        Icon(
                          Icons.chevron_right,
                          color: AppTheme.textDisabled(context),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            if (onDelete != null)
              IconButton(
                onPressed: onDelete,
                icon: Icon(
                  Icons.delete_outline,
                  color: AppTheme.textTertiary(context),
                  size: 20,
                ),
                tooltip: l10n.plan_delete,
              ),
          ],
        ),
      ),
    );
  }
}

class _AddPlanCard extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _AddPlanCard({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 108,
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
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.add,
                  size: 40,
                  color: AppTheme.hydrationBlue,
                ),
                const SizedBox(height: 6),
                Text(
                  label,
                  style: TextStyle(
                    color: AppTheme.hydrationBlue,
                    fontSize: 14,
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
