import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_theme.dart';
import '../services/notification_strings.dart';

class WeightFollowUpSheet extends StatefulWidget {
  final bool initialEnabled;
  final double initialTargetKg;
  final int initialIntervalDays;
  final bool useMetric;
  final void Function(bool enabled, double targetKg, int intervalDays) onSave;

  const WeightFollowUpSheet({
    super.key,
    required this.initialEnabled,
    required this.initialTargetKg,
    required this.initialIntervalDays,
    required this.useMetric,
    required this.onSave,
  });

  @override
  State<WeightFollowUpSheet> createState() => _WeightFollowUpSheetState();
}

class _WeightFollowUpSheetState extends State<WeightFollowUpSheet> {
  late bool _enabled;
  late double _targetWeightKg;
  late int _intervalDays;

  static const _intervals = [1, 2, 3, 5, 7, 14];

  @override
  void initState() {
    super.initState();
    _enabled = widget.initialEnabled;
    _targetWeightKg = widget.initialTargetKg;
    _intervalDays = widget.initialIntervalDays;
  }

  void _showWeightPicker() {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        double localWeight = _targetWeightKg;
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final displayWeight = widget.useMetric ? localWeight : localWeight * 2.205;
            final unit = widget.useMetric ? 'kg' : 'lb';
            return Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 36, height: 4,
                    decoration: BoxDecoration(
                      color: AppTheme.subtleFill(context, 0.30),
                      borderRadius: BorderRadius.circular(2),
                    )),
                  const SizedBox(height: 20),
                  Text(NotificationStrings.targetWeight,
                    style: TextStyle(color: AppTheme.textPrimary(context), fontSize: 18, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 24),
                  Text('${displayWeight.toStringAsFixed(0)} $unit',
                    style: TextStyle(color: AppTheme.textPrimary(context), fontSize: 48, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Text('Slide to set your target weight',
                    style: TextStyle(color: AppTheme.textTertiary(context), fontSize: 13)),
                  const SizedBox(height: 16),
                  Slider(
                    value: localWeight, min: 50, max: 200, divisions: 150,
                    label: '${localWeight.toStringAsFixed(0)} kg',
                    onChanged: (v) => setSheetState(() => localWeight = v),
                  ),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(widget.useMetric ? '50 kg' : '110 lb',
                        style: TextStyle(color: AppTheme.textTertiary(context), fontSize: 12)),
                      Text(widget.useMetric ? '200 kg' : '440 lb',
                        style: TextStyle(color: AppTheme.textTertiary(context), fontSize: 12)),
                    ]),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () {
                        setState(() => _targetWeightKg = localWeight);
                        Navigator.of(ctx).pop();
                      },
                      style: FilledButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Set Target'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final weightStr = widget.useMetric
        ? '${_targetWeightKg.toStringAsFixed(0)} kg'
        : '${(_targetWeightKg * 2.205).toStringAsFixed(0)} lb';

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36, height: 4,
            decoration: BoxDecoration(
              color: AppTheme.subtleFill(context, 0.30),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              const Icon(Icons.monitor_weight_outlined, size: 22, color: AppTheme.hydrationBlue),
              const SizedBox(width: 10),
              Text(NotificationStrings.weightConfigTitle,
                style: TextStyle(
                  color: AppTheme.textPrimary(context),
                  fontSize: 18, fontWeight: FontWeight.w700,
                )),
            ],
          ),
          const SizedBox(height: 8),
          Text(NotificationStrings.weightConfigHeader,
            style: TextStyle(color: AppTheme.textTertiary(context), fontSize: 13)),
          const SizedBox(height: 24),

          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text('Enable Weight Follow-Up',
              style: TextStyle(color: AppTheme.textPrimary(context), fontWeight: FontWeight.w600)),
            value: _enabled,
            onChanged: (v) => setState(() => _enabled = v),
          ),

          if (_enabled) ...[
            const SizedBox(height: 16),
            InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: _showWeightPicker,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: AppTheme.subtleFill(context, 0.06),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.monitor_weight_outlined, size: 20, color: AppTheme.hydrationBlue),
                    const SizedBox(width: 12),
                    Expanded(child: Text(NotificationStrings.targetWeight,
                      style: TextStyle(color: AppTheme.textSecondary(context), fontSize: 14))),
                    Text(weightStr,
                      style: TextStyle(color: AppTheme.textPrimary(context), fontSize: 16, fontWeight: FontWeight.w600)),
                    const SizedBox(width: 8),
                    Icon(Icons.edit_outlined, size: 16, color: AppTheme.textTertiary(context)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(NotificationStrings.remindEvery,
              style: TextStyle(color: AppTheme.textPrimary(context), fontWeight: FontWeight.w600, fontSize: 15)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8, runSpacing: 8,
              children: _intervals.map((days) {
                final selected = days == _intervalDays;
                return GestureDetector(
                  onTap: () => setState(() => _intervalDays = days),
                  child: AnimatedContainer(
                    duration: AppTheme.kAnimFast,
                    curve: AppTheme.kEaseOut,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: selected ? AppTheme.hydrationBlue.withValues(alpha: 0.2) : AppTheme.subtleFill(context, 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selected ? AppTheme.hydrationBlue.withValues(alpha: 0.5) : AppTheme.subtleFill(context, 0.15),
                        width: selected ? 1.5 : 1,
                      ),
                    ),
                    child: Text(
                      days == 1 ? 'Every day' : days == 7 ? 'Weekly' : days == 14 ? 'Every 2 weeks' : 'Every $days days',
                      style: TextStyle(
                        color: selected ? AppTheme.hydrationBlue : AppTheme.textSecondary(context),
                        fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                        fontSize: 14,
                      )),
                  ),
                );
              }).toList(),
            ),
          ],

          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                widget.onSave(_enabled, _targetWeightKg, _intervalDays);
                Navigator.of(context).pop();
              },
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(NotificationStrings.done),
            ),
          ),
        ],
      ),
    );
  }
}
