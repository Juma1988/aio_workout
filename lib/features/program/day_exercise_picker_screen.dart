import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/theme/app_theme.dart';
import '../../data/exercise.dart';
import '../../data/workout_plan.dart';
import '../../l10n/app_localizations.dart';

/// Multi-select exercise library for assigning exercises to a plan day.
/// Returns `List<PlanExerciseSlot>` via [Navigator.pop] on Done.
class DayExercisePickerScreen extends StatefulWidget {
  final List<PlanExerciseSlot> initiallySelected;

  const DayExercisePickerScreen({
    super.key,
    this.initiallySelected = const [],
  });

  @override
  State<DayExercisePickerScreen> createState() =>
      _DayExercisePickerScreenState();
}

class _DayExercisePickerScreenState extends State<DayExercisePickerScreen> {
  List<Exercise> _all = [];
  bool _loading = true;
  String _search = '';
  String? _filter;

  /// Selection order is preserved (list, not set).
  late List<String> _selectedOrder;
  late Map<String, PlanExerciseSlot> _slotById;

  @override
  void initState() {
    super.initState();
    _selectedOrder =
        widget.initiallySelected.map((s) => s.exerciseId).toList();
    _slotById = {
      for (final s in widget.initiallySelected) s.exerciseId: s,
    };
    _load();
  }

  Future<void> _load() async {
    final all = <Exercise>[...defaultExercises];
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString('custom_exercises');
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final decoded = (jsonDecode(jsonStr) as List<dynamic>)
            .map((j) => Exercise.fromJson(j as Map<String, dynamic>))
            .toList();
        all.addAll(decoded);
      }
    } catch (_) {}
    if (!mounted) return;
    setState(() {
      _all = all;
      _loading = false;
    });
  }

  Set<String> get _selectedIds => _selectedOrder.toSet();

  static const _customFilterKey = 'custom';

  List<Exercise> get _filtered {
    final q = _search.toLowerCase().trim();
    return _all.where((ex) {
      if (_filter == _customFilterKey) {
        if (ex.isDefault) return false;
      } else if (_filter != null && ex.categoryKey != _filter) {
        return false;
      }
      if (q.isEmpty) return true;
      return ex.name.toLowerCase().contains(q) ||
          (ex.description ?? '').toLowerCase().contains(q);
    }).toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  }

  void _toggle(Exercise ex) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_selectedOrder.contains(ex.uuid)) {
        _selectedOrder.remove(ex.uuid);
      } else {
        _selectedOrder.add(ex.uuid);
        _slotById[ex.uuid] = PlanExerciseSlot.fromExercise(ex);
      }
    });
  }

  void _done() {
    HapticFeedback.mediumImpact();
    final result = <PlanExerciseSlot>[];
    for (final id in _selectedOrder) {
      final existing = _slotById[id];
      if (existing != null) {
        result.add(existing);
        continue;
      }
      final ex = _all.where((e) => e.uuid == id).firstOrNull;
      if (ex != null) result.add(PlanExerciseSlot.fromExercise(ex));
    }
    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final filtered = _filtered;
    final selected = _selectedIds;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.plan_pickExercises),
        actions: [
          TextButton(
            onPressed: _done,
            child: Text(
              selected.isEmpty
                  ? l10n.plan_done
                  : '${l10n.plan_done} (${selected.length})',
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (selected.isNotEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                    child: Text(
                      l10n.plan_selectedCount(selected.length),
                      style: TextStyle(
                        color: AppTheme.hydrationBlue,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: TextField(
                    onChanged: (v) => setState(() => _search = v),
                    decoration: InputDecoration(
                      hintText: l10n.plan_searchExercises,
                      prefixIcon: const Icon(Icons.search, size: 20),
                      suffixIcon: _search.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () => setState(() => _search = ''),
                            )
                          : null,
                      filled: true,
                      fillColor: AppTheme.cardColor(context),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _filterChip(
                          l10n.plan_filterAll,
                          _filter == null,
                          () => setState(() => _filter = null),
                        ),
                        const SizedBox(width: 6),
                        _filterChip(
                          l10n.plan_filterCustom,
                          _filter == _customFilterKey,
                          () => setState(() => _filter = _customFilterKey),
                          color: AppTheme.achievementGreen,
                        ),
                        const SizedBox(width: 6),
                        ...exerciseCategories.values.map(
                          (cat) => Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: _filterChip(
                              cat.label,
                              _filter == cat.key,
                              () => setState(() => _filter = cat.key),
                              color: cat.color,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: filtered.isEmpty
                      ? Center(
                          child: Text(
                            l10n.plan_noExercisesFound,
                            style: TextStyle(
                              color: AppTheme.textTertiary(context),
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                          itemCount: filtered.length,
                          itemBuilder: (ctx, i) {
                            final ex = filtered[i];
                            final isSel = selected.contains(ex.uuid);
                            final cat = exerciseCategories[ex.categoryKey];
                            final color =
                                cat?.color ?? AppTheme.textSecondary(context);
                            final display = ex.getRecommendedDisplay();
                            final isCustom = !ex.isDefault;
                            final orderIndex = isSel
                                ? _selectedOrder.indexOf(ex.uuid) + 1
                                : 0;

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Material(
                                color: isSel
                                    ? color.withValues(alpha: 0.08)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(12),
                                  onTap: () => _toggle(ex),
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: isSel
                                            ? color.withValues(alpha: 0.5)
                                            : AppTheme.subtleFill(
                                                context, 0.1),
                                        width: isSel ? 1.5 : 1,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 36,
                                          height: 36,
                                          decoration: BoxDecoration(
                                            color:
                                                color.withValues(alpha: 0.10),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: isSel
                                              ? Center(
                                                  child: Text(
                                                    '$orderIndex',
                                                    style: TextStyle(
                                                      color: color,
                                                      fontWeight:
                                                          FontWeight.w800,
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                )
                                              : Icon(
                                                  exerciseCategoryIcons[
                                                          ex.categoryKey] ??
                                                      Icons.fitness_center,
                                                  size: 18,
                                                  color: color,
                                                ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Flexible(
                                                    child: Text(
                                                      ex.name,
                                                      style: TextStyle(
                                                        color: AppTheme
                                                            .textPrimary(
                                                                context),
                                                        fontSize: 14,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                    ),
                                                  ),
                                                  if (isCustom) ...[
                                                    const SizedBox(width: 6),
                                                    Container(
                                                      padding:
                                                          const EdgeInsets
                                                              .symmetric(
                                                        horizontal: 6,
                                                        vertical: 2,
                                                      ),
                                                      decoration: BoxDecoration(
                                                        color: AppTheme
                                                            .achievementGreen
                                                            .withValues(
                                                                alpha: 0.12),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(999),
                                                      ),
                                                      child: Text(
                                                        l10n.plan_customBadge,
                                                        style: const TextStyle(
                                                          color: AppTheme
                                                              .achievementGreen,
                                                          fontSize: 10,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ],
                                              ),
                                              if (display.isNotEmpty)
                                                Text(
                                                  display,
                                                  style: TextStyle(
                                                    color:
                                                        AppTheme.textTertiary(
                                                            context),
                                                    fontSize: 12,
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                        Icon(
                                          isSel
                                              ? Icons.check_circle
                                              : Icons.circle_outlined,
                                          size: 22,
                                          color: isSel
                                              ? color
                                              : AppTheme.textDisabled(context),
                                        ),
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

  Widget _filterChip(
    String label,
    bool selected,
    VoidCallback onTap, {
    Color? color,
  }) {
    final accent = color ?? AppTheme.textSecondary(context);
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? accent.withValues(alpha: 0.18)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected
                ? accent.withValues(alpha: 0.55)
                : AppTheme.subtleFill(context, 0.2),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? accent : AppTheme.textTertiary(context),
            fontSize: 12,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
