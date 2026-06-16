import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_theme.dart';

class HydrationGoalDialog extends StatefulWidget {
  final double currentGoalLiters;
  final bool isAutoCalculated;
  final double? weightKg;

  const HydrationGoalDialog({
    super.key,
    required this.currentGoalLiters,
    required this.isAutoCalculated,
    this.weightKg,
  });

  @override
  State<HydrationGoalDialog> createState() => _HydrationGoalDialogState();
}

class _HydrationGoalDialogState extends State<HydrationGoalDialog> {
  late double _goalLiters;
  late bool _isAutoCalculated;
  late TextEditingController _controller;

  static const _minGoal = 1.0;
  static const _maxGoal = 5.0;
  static const _defaultWeight = 70.0;
  static const _formula = 0.035;

  @override
  void initState() {
    super.initState();
    _goalLiters = widget.currentGoalLiters;
    _isAutoCalculated = widget.isAutoCalculated;
    _controller = TextEditingController(text: _goalLiters.toStringAsFixed(2));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double get _calculatedGoal {
    final weight = widget.weightKg ?? _defaultWeight;
    return (weight * _formula).roundToDouble() * 4 / 4; // Round to 0.25L
  }

  void _updateAutoCalc() {
    if (_isAutoCalculated) {
      final newGoal = _calculatedGoal.clamp(_minGoal, _maxGoal);
      setState(() {
        _goalLiters = newGoal;
        _controller.text = _goalLiters.toStringAsFixed(2);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final blue = AppTheme.hydrationBlue;
    final weight = widget.weightKg ?? _defaultWeight;
    final hasWeight = widget.weightKg != null;

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
                color: blue.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.water_drop_rounded, color: blue, size: 24),
            ),
            const SizedBox(height: 16),
            Text(
              'Daily Hydration Goal',
              style: TextStyle(
                color: AppTheme.textPrimary(context),
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Set your target water intake per day',
              style: TextStyle(
                color: AppTheme.textTertiary(context),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 20),
            // Auto-calculate toggle
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.subtleFill(context, 0.06),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calculate_rounded,
                    color: hasWeight ? blue : AppTheme.textTertiary(context),
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Auto-calculate from weight',
                          style: TextStyle(
                            color: AppTheme.textPrimary(context),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (hasWeight)
                          Text(
                            '${weight.toStringAsFixed(0)}kg × $_formula = ${_calculatedGoal.toStringAsFixed(2)}L',
                            style: TextStyle(
                              color: AppTheme.textTertiary(context),
                              fontSize: 12,
                            ),
                          )
                        else
                          Text(
                            'Set weight in Profile to enable',
                            style: TextStyle(
                              color: AppTheme.textTertiary(context),
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Switch.adaptive(
                    value: _isAutoCalculated,
                    activeTrackColor: blue.withValues(alpha: 0.5),
                    activeThumbColor: blue,
                    onChanged: hasWeight
                        ? (value) {
                              HapticFeedback.selectionClick();
                              setState(() => _isAutoCalculated = value);
                              _updateAutoCalc();
                            }
                        : null,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Manual input
            if (!_isAutoCalculated) ...[
              Text(
                'Custom Target',
                style: TextStyle(
                  color: AppTheme.textSecondary(context),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: 140,
                child: TextField(
                  controller: _controller,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                  ],
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
                        color: blue.withValues(alpha: 0.4),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: blue, width: 2),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onChanged: (v) {
                    final parsed = double.tryParse(v);
                    if (parsed != null) {
                      setState(() => _goalLiters = parsed);
                    }
                  },
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'liters per day',
                style: TextStyle(
                  color: AppTheme.textTertiary(context),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 16),
              // Slider
              Slider(
                value: _goalLiters.clamp(_minGoal, _maxGoal),
                min: _minGoal,
                max: _maxGoal,
                divisions: 16, // 0.25L increments
                activeColor: blue,
                inactiveColor: blue.withValues(alpha: 0.2),
                onChanged: (value) {
                  HapticFeedback.selectionClick();
                  setState(() {
                    _goalLiters = value;
                    _controller.text = _goalLiters.toStringAsFixed(2);
                  });
                },
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${_minGoal}L',
                    style: TextStyle(
                      color: AppTheme.textTertiary(context),
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    '${_maxGoal}L',
                    style: TextStyle(
                      color: AppTheme.textTertiary(context),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ] else ...[
              // Auto-calculated display
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: blue.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.water_drop_rounded,
                      color: blue,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${_goalLiters.toStringAsFixed(2)}L',
                      style: TextStyle(
                        color: blue,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Based on your ${weight.toStringAsFixed(0)}kg weight',
                style: TextStyle(
                  color: AppTheme.textTertiary(context),
                  fontSize: 12,
                ),
              ),
            ],
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
                    onPressed: _goalLiters >= _minGoal && _goalLiters <= _maxGoal
                        ? () {
                              HapticFeedback.lightImpact();
                              Navigator.of(context).pop((_goalLiters, _isAutoCalculated));
                            }
                        : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: blue,
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

/// Shows the hydration goal dialog and returns the selected goal or null if cancelled.
Future<(double, bool)?> showHydrationGoalDialog(
  BuildContext context, {
  required double currentGoalLiters,
  required bool isAutoCalculated,
  double? weightKg,
}) {
  return showDialog<(double, bool)>(
    context: context,
    builder: (_) => HydrationGoalDialog(
      currentGoalLiters: currentGoalLiters,
      isAutoCalculated: isAutoCalculated,
      weightKg: weightKg,
    ),
  );
}
