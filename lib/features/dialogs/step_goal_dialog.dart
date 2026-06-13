import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_theme.dart';

class StepGoalDialog extends StatefulWidget {
  final int currentGoal;

  const StepGoalDialog({super.key, required this.currentGoal});

  @override
  State<StepGoalDialog> createState() => _StepGoalDialogState();
}

class _StepGoalDialogState extends State<StepGoalDialog> {
  late int _goal;
  late TextEditingController _controller;

  static const _presetGoals = [5000, 7500, 10000, 12500, 15000, 20000];

  @override
  void initState() {
    super.initState();
    _goal = widget.currentGoal;
    _controller = TextEditingController(text: _goal.toString());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final orange = AppTheme.stepsOrange;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: orange.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.flag, color: orange, size: 24),
            ),
            const SizedBox(height: 16),
            Text(
              'Daily Step Goal',
              style: TextStyle(
                color: AppTheme.textPrimary(context),
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Set your target steps per day',
              style: TextStyle(
                color: AppTheme.textTertiary(context),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: 140,
              child: TextField(
                controller: _controller,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppTheme.textPrimary(context),
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                ),
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: AppTheme.subtleFill(context, 0.2),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: orange.withValues(alpha: 0.4),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: orange, width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onChanged: (v) {
                  final parsed = int.tryParse(v);
                  if (parsed != null) setState(() => _goal = parsed);
                },
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'steps per day',
              style: TextStyle(
                color: AppTheme.textTertiary(context),
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: _presetGoals.map((preset) {
                final selected = _goal == preset;
                return GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() {
                      _goal = preset;
                      _controller.text = preset.toString();
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: selected
                          ? orange.withValues(alpha: 0.2)
                          : AppTheme.subtleFill(context, 0.06),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: selected ? orange : Colors.transparent,
                        width: 1,
                      ),
                    ),
                    child: Text(
                      '${(preset / 1000).toStringAsFixed(preset % 1000 == 0 ? 0 : 1)}k',
                      style: TextStyle(
                        color: selected ? orange : AppTheme.textSecondary(context),
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: BorderSide(
                        color: AppTheme.subtleFill(context, 0.2),
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        color: AppTheme.textSecondary(context),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _goal > 0
                        ? () {
                            HapticFeedback.lightImpact();
                            Navigator.of(context).pop(_goal);
                          }
                        : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: orange,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Save',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
