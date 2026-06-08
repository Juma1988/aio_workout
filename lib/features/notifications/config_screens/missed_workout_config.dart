import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../services/notification_repository.dart';
import '../services/notification_service.dart';
import '../services/notification_strings.dart';

class MissedWorkoutConfigScreen extends StatefulWidget {
  const MissedWorkoutConfigScreen({super.key});

  @override
  State<MissedWorkoutConfigScreen> createState() =>
      _MissedWorkoutConfigScreenState();
}

class _MissedWorkoutConfigScreenState
    extends State<MissedWorkoutConfigScreen> {
  final _repo = NotificationRepository();
  final _service = NotificationService();
  int _delayHours = 2;

  static const List<int> _delayOptions = [1, 2, 3, 4, 6, 8, 12, 24];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final hours = await _repo.missedWorkoutDelayHours;
    if (mounted) setState(() => _delayHours = hours);
  }

  Future<void> _save(int hours) async {
    await _repo.setMissedWorkoutDelayHours(hours);
    unawaited(_service.scheduleMissedWorkoutReminder());
  }

  String _delayLabel(int hours) {
    if (hours < 2) return '$hours hour';
    if (hours < 24) return '$hours hours';
    return '24 hours (1 day)';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(NotificationStrings.missedWorkoutConfigTitle),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppTheme.achievementGreen.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.fitness_center_outlined,
                  size: 36,
                  color: AppTheme.achievementGreen,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              NotificationStrings.missedWorkoutConfigTitle,
              style: TextStyle(
                color: AppTheme.textPrimary(context),
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              NotificationStrings.missedWorkoutConfigHeader,
              style: TextStyle(
                color: AppTheme.textSecondary(context),
                fontSize: 14,
              ),
            ),

            const SizedBox(height: 32),
            Text(
              NotificationStrings.waitTimeLabel,
              style: TextStyle(
                color: AppTheme.textPrimary(context),
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              NotificationStrings.waitTimeDesc,
              style: TextStyle(
                color: AppTheme.textTertiary(context),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 20),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(_delayOptions.length, (i) {
                final hours = _delayOptions[i];
                final selected = hours == _delayHours;
                return GestureDetector(
                  onTap: () {
                    setState(() => _delayHours = hours);
                    _save(hours);
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
                          ? AppTheme.achievementGreen.withValues(alpha: 0.2)
                          : AppTheme.subtleFill(context, 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selected
                            ? AppTheme.achievementGreen.withValues(alpha: 0.5)
                            : AppTheme.subtleFill(context, 0.15),
                        width: selected ? 1.5 : 1,
                      ),
                    ),
                    child: Text(
                      _delayLabel(hours),
                      style: TextStyle(
                        color: selected
                            ? AppTheme.achievementGreen
                            : AppTheme.textSecondary(context),
                        fontWeight:
                            selected ? FontWeight.w600 : FontWeight.w500,
                        fontSize: 15,
                      ),
                    ),
                  ),
                );
              }),
            ),

            const SizedBox(height: 32),
            Container(
              width: double.infinity,
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
                      'You\'ll be reminded ${_delayLabel(_delayHours)} after a missed workout.',
                      style: TextStyle(
                        color: AppTheme.textSecondary(context),
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const Spacer(),
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
      ),
    );
  }
}
