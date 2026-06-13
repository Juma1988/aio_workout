import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/clock.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/directional_icon.dart';
import '../../data/weight_entry.dart';
import '../../l10n/app_localizations.dart';
import '../notifications/services/notification_repository.dart';

class WeightLogSheet extends StatefulWidget {
  final double currentWeightKg;
  final double? weightGoalKg;
  final ValueChanged<WeightEntry> onSave;
  final Clock clock;

  const WeightLogSheet({
    super.key,
    required this.currentWeightKg,
    this.weightGoalKg,
    required this.onSave,
    this.clock = const SystemClock(),
  });

  @override
  State<WeightLogSheet> createState() => _WeightLogSheetState();
}

class _WeightLogSheetState extends State<WeightLogSheet> {
  late double _weightKg;
  late DateTime _selectedDate;
  bool _saving = false;
  bool _isEditingWeight = false;
  late TextEditingController _weightController;
  final FocusNode _weightFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _weightKg = widget.currentWeightKg > 0 ? widget.currentWeightKg : 70.0;
    _selectedDate = widget.clock.now();
    _weightController = TextEditingController(text: _weightKg.toStringAsFixed(1));
    _weightFocusNode.addListener(_onWeightFocusLost);
  }

  @override
  void dispose() {
    _weightFocusNode.removeListener(_onWeightFocusLost);
    _weightFocusNode.dispose();
    _weightController.dispose();
    super.dispose();
  }

  void _onWeightFocusLost() {
    if (!_weightFocusNode.hasFocus && _isEditingWeight) {
      _commitWeightEdit();
    }
  }

  void _startWeightEdit() {
    setState(() {
      _weightController.text = _weightKg.toStringAsFixed(1);
      _isEditingWeight = true;
    });
    // Focus after the next frame so the TextField is rendered
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _weightFocusNode.requestFocus();
    });
  }

  void _commitWeightEdit() {
    final parsed = double.tryParse(_weightController.text);
    if (parsed != null && parsed >= 30.0 && parsed <= 250.0) {
      setState(() {
        _weightKg = parsed;
        _isEditingWeight = false;
      });
    } else {
      // Revert to previous value
      setState(() {
        _weightController.text = _weightKg.toStringAsFixed(1);
        _isEditingWeight = false;
      });
    }
  }

  void _save() {
    HapticFeedback.mediumImpact();
    setState(() => _saving = true);
    final now = widget.clock.now();
    final entry = WeightEntry(
      uuid: 'w-${now.millisecondsSinceEpoch}',
      date: _selectedDate,
      weightKg: _weightKg,
    );
    widget.onSave(entry);
    Navigator.of(context).pop();
  }

  Future<void> _setGoal() => _showGoalDialog();

  Future<void> _showGoalDialog() async {
    final l10n = AppLocalizations.of(context);
    final repo = NotificationRepository();
    final currentGoal = await repo.weightTarget;
    if (!mounted) return;

    double newGoal = currentGoal;

    await showDialog<double>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Text(l10n.dialog_setTargetWeight),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${newGoal.toStringAsFixed(1)} kg',
                      style: TextStyle(
                        color: AppTheme.textPrimary(context),
                        fontSize: 36,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Slider(
                      value: newGoal,
                      min: 30.0,
                      max: 250.0,
                      divisions: 2200,
                      activeColor: AppTheme.weightPurple,
                      inactiveColor: AppTheme.subtleFill(context),
                      onChanged: (v) => setDialogState(() => newGoal = v),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('30 kg',
                            style: TextStyle(fontSize: 11,
                                color: AppTheme.textTertiary(context))),
                        Text('250 kg',
                            style: TextStyle(fontSize: 11,
                                color: AppTheme.textTertiary(context))),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: Text(l10n.dialog_cancel,
                      style: TextStyle(
                          color: AppTheme.textSecondary(context))),
                ),
                FilledButton(
                  onPressed: () {
                    repo.setWeightTarget(newGoal);
                    if (ctx.mounted) Navigator.of(ctx).pop(newGoal);
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.weightPurple,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(l10n.dialog_setGoal),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final purple = AppTheme.weightPurple;
    final hasGoal = widget.weightGoalKg != null && widget.weightGoalKg! > 0;
    final now = widget.clock.now();

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          24, 24, 24, 20 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: purple.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(14),
              ),
              child:
                  Icon(Icons.monitor_weight_outlined, color: purple, size: 30),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.dialog_weightLogTitle,
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.dialog_recordWeightSubtitle,
              style: TextStyle(
                color: AppTheme.textTertiary(context),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            // ── Weight value display / inline edit ──
            GestureDetector(
              onTap: _isEditingWeight ? null : _startWeightEdit,
              child: Container(
                height: 56,
                alignment: Alignment.center,
                child: _isEditingWeight
                    ? SizedBox(
                        width: 180,
                        child: TextField(
                          controller: _weightController,
                          focusNode: _weightFocusNode,
                          keyboardType:
                              const TextInputType.numberWithOptions(decimal: true),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppTheme.textPrimary(context),
                            fontSize: 48,
                            fontWeight: FontWeight.w700,
                          ),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: _weightKg.toStringAsFixed(1),
                            hintStyle: TextStyle(
                              color: AppTheme.textTertiary(context),
                              fontSize: 48,
                              fontWeight: FontWeight.w700,
                            ),
                            suffixText: ' kg',
                            suffixStyle: TextStyle(
                              color: AppTheme.textSecondary(context),
                              fontSize: 20,
                              fontWeight: FontWeight.w500,
                            ),
                            contentPadding: EdgeInsets.zero,
                            isDense: true,
                          ),
                          onSubmitted: (_) => _commitWeightEdit(),
                        ),
                      )
                    : Text(
                        '${_weightKg.toStringAsFixed(1)} kg',
                        style: TextStyle(
                          color: AppTheme.textPrimary(context),
                          fontSize: 48,
                          fontWeight: FontWeight.w700,
                          height: 1.1,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 8),
            Slider(
              value: _weightKg,
              min: 30.0,
              max: 250.0,
              divisions: 2200,
              activeColor: purple,
              inactiveColor: AppTheme.subtleFill(context),
              onChanged: (v) {
                setState(() {
                  _weightKg = v;
                  _isEditingWeight = false;
                });
              },
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('30 kg',
                    style: TextStyle(
                        fontSize: 11, color: AppTheme.textTertiary(context))),
                Text('250 kg',
                    style: TextStyle(
                        fontSize: 11, color: AppTheme.textTertiary(context))),
              ],
            ),
            const SizedBox(height: 12),
            InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: now.subtract(const Duration(days: 365)),
                  lastDate: now,
                );
                if (date != null) {
                  setState(() => _selectedDate = date);
                }
              },
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today,
                        size: 16, color: AppTheme.textSecondary(context)),
                    const SizedBox(width: 8),
                    Text(
                      _selectedDate.year == now.year &&
                              _selectedDate.month == now.month &&
                              _selectedDate.day == now.day
                          ? l10n.dialog_today
                          : '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}',
                      style:
                          TextStyle(color: AppTheme.textSecondary(context)),
                    ),
                    const Spacer(),
                    DirectionalIcon(icon: Icons.chevron_right,
                        size: 18, color: AppTheme.textDisabled(context)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _saving ? null : _save,
                style: FilledButton.styleFrom(
                  backgroundColor: purple,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  _saving ? l10n.dialog_saving : l10n.dialog_saveWeight,
                  style:
                      const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            if (!hasGoal)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: TextButton(
                  onPressed: _saving ? null : () => _setGoal(),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.textTertiary(context),
                  ),
                  child: Text(l10n.dialog_setTargetWeightLink),
                ),
              ),
          ],
        ),
        ),
      ),
    );
  }
}
