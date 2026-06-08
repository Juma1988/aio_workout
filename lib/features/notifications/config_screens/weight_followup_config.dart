import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_theme.dart';
import '../services/notification_repository.dart';
import '../services/notification_service.dart';
import '../services/notification_strings.dart';

class WeightFollowUpConfigScreen extends StatefulWidget {
  const WeightFollowUpConfigScreen({super.key});

  @override
  State<WeightFollowUpConfigScreen> createState() =>
      _WeightFollowUpConfigScreenState();
}

class _WeightFollowUpConfigScreenState
    extends State<WeightFollowUpConfigScreen> {
  final _repo = NotificationRepository();
  final _service = NotificationService();
  double _targetWeightKg = 75.0;
  int _intervalDays = 3;
  bool _useKg = true;

  static const _intervals = [1, 2, 3, 5, 7, 14];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final target = await _repo.weightTarget;
    final interval = await _repo.weightIntervalDays;
    final metric = await _repo.isMetric;
    if (mounted) {
      setState(() {
        _targetWeightKg = target;
        _intervalDays = interval;
        _useKg = metric;
      });
    }
  }

  Future<void> _saveWeight(double kg) async {
    await _repo.setWeightTarget(kg);
  }

  Future<void> _saveInterval(int days) async {
    await _repo.setWeightIntervalDays(days);
    unawaited(_service.scheduleWeightFollowUp());
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
            final displayWeight = _useKg
                ? localWeight
                : localWeight * 2.205;
            final unit = _useKg ? 'kg' : 'lb';
            return Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppTheme.subtleFill(context, 0.30),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    NotificationStrings.targetWeight,
                    style: TextStyle(
                      color: AppTheme.textPrimary(context),
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    '${displayWeight.toStringAsFixed(0)} $unit',
                    style: TextStyle(
                      color: AppTheme.textPrimary(context),
                      fontSize: 48,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Slide to set your target weight',
                    style: TextStyle(
                      color: AppTheme.textTertiary(context),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Slider(
                    value: localWeight,
                    min: 50,
                    max: 200,
                    divisions: 150,
                    label: '${localWeight.toStringAsFixed(0)} kg',
                    onChanged: (v) => setSheetState(() => localWeight = v),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _useKg ? '50 kg' : '110 lb',
                        style: TextStyle(
                          color: AppTheme.textTertiary(context),
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        _useKg ? '200 kg' : '440 lb',
                        style: TextStyle(
                          color: AppTheme.textTertiary(context),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () {
                        setState(() => _targetWeightKg = localWeight);
                        _saveWeight(localWeight);
                        Navigator.of(ctx).pop();
                      },
                      style: FilledButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
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
    final weightStr = _useKg
        ? '${_targetWeightKg.toStringAsFixed(0)} kg'
        : '${(_targetWeightKg * 2.205).toStringAsFixed(0)} lb';

    return Scaffold(
      appBar: AppBar(
        title: Text(NotificationStrings.weightConfigTitle),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
        children: [
          Center(
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppTheme.hydrationBlue.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(
                Icons.monitor_weight_outlined,
                size: 36,
                color: AppTheme.hydrationBlue,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            NotificationStrings.weightConfigTitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppTheme.textPrimary(context),
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            NotificationStrings.weightConfigHeader,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppTheme.textSecondary(context),
              fontSize: 14,
            ),
          ),

          const SizedBox(height: 32),
          Text(
            NotificationStrings.targetWeight,
            style: TextStyle(
              color: AppTheme.textPrimary(context),
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'What weight are you working toward?',
            style: TextStyle(
              color: AppTheme.textTertiary(context),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 12),

          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: _showWeightPicker,
            child: Container(
              padding: const EdgeInsets.symmetric(
                vertical: 16,
                horizontal: 20,
              ),
              decoration: BoxDecoration(
                color: AppTheme.cardColor(context),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppTheme.hydrationBlue.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.monitor_weight_outlined,
                    size: 24,
                    color: AppTheme.hydrationBlue,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          weightStr,
                          style: TextStyle(
                            color: AppTheme.textPrimary(context),
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          _useKg ? 'Kilograms' : 'Pounds',
                          style: TextStyle(
                            color: AppTheme.textTertiary(context),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.edit_outlined,
                    size: 20,
                    color: AppTheme.textTertiary(context),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 28),
          Text(
            NotificationStrings.remindEvery,
            style: TextStyle(
              color: AppTheme.textPrimary(context),
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'How often to ask you to log your weight',
            style: TextStyle(
              color: AppTheme.textTertiary(context),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 12),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _intervals.map((days) {
              final selected = days == _intervalDays;
              return GestureDetector(
                onTap: () {
                  setState(() => _intervalDays = days);
                  _saveInterval(days);
                },
                child: AnimatedContainer(
                  duration: AppTheme.kAnimFast,
                  curve: AppTheme.kEaseOut,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppTheme.hydrationBlue.withValues(alpha: 0.2)
                        : AppTheme.subtleFill(context, 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: selected
                          ? AppTheme.hydrationBlue.withValues(alpha: 0.5)
                          : AppTheme.subtleFill(context, 0.15),
                      width: selected ? 1.5 : 1,
                    ),
                  ),
                  child: Text(
                    days == 1
                        ? 'Every day'
                        : days == 7
                            ? 'Weekly'
                            : days == 14
                                ? 'Every 2 weeks'
                                : 'Every $days days',
                    style: TextStyle(
                      color: selected
                          ? AppTheme.hydrationBlue
                          : AppTheme.textSecondary(context),
                      fontWeight:
                          selected ? FontWeight.w600 : FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.subtleFill(context, 0.06),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 18,
                  color: AppTheme.textTertiary(context),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Every $_intervalDays day${_intervalDays > 1 ? 's' : ''}, you\'ll be reminded to log your weight toward $weightStr.',
                    style: TextStyle(
                      color: AppTheme.textSecondary(context),
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(
                NotificationStrings.done,
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
