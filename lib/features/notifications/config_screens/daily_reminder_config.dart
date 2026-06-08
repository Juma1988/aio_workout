import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../services/notification_repository.dart';
import '../services/notification_service.dart';
import '../services/notification_strings.dart';

class DailyReminderConfigScreen extends StatefulWidget {
  const DailyReminderConfigScreen({super.key});

  @override
  State<DailyReminderConfigScreen> createState() =>
      _DailyReminderConfigScreenState();
}

class _DailyReminderConfigScreenState
    extends State<DailyReminderConfigScreen> {
  final _repo = NotificationRepository();
  final _service = NotificationService();
  TimeOfDay _reminderTime = const TimeOfDay(hour: 8, minute: 0);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final time = await _repo.dailyReminderTime;
    if (mounted) setState(() => _reminderTime = time);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _reminderTime,
      helpText: NotificationStrings.get(
        'Choose reminder time',
        'اختر وقت التذكير',
      ),
    );
    if (picked != null && mounted) {
      setState(() => _reminderTime = picked);
      await _repo.setDailyReminderTime(picked);
      unawaited(_service.scheduleDailyReminder());
    }
  }

  @override
  Widget build(BuildContext context) {
    final timeStr = _reminderTime.format(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(NotificationStrings.dailyReminderConfigTitle),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 32),
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.stepsOrange.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.alarm_outlined,
                size: 40,
                color: AppTheme.stepsOrange,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              NotificationStrings.dailyReminderConfigBody,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.textPrimary(context),
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 32),

            InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: _pickTime,
              child: Container(
                width: 200,
                padding: const EdgeInsets.symmetric(
                  vertical: 20,
                  horizontal: 32,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.cardColor(context),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppTheme.stepsOrange.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.access_time,
                      size: 32,
                      color: AppTheme.stepsOrange,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      timeStr,
                      style: TextStyle(
                        color: AppTheme.textPrimary(context),
                        fontSize: 36,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      NotificationStrings.tapToChange,
                      style: TextStyle(
                        color: AppTheme.textTertiary(context),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),
            Text(
              'You\'ll receive a notification every day at $timeStr\nas a reminder to complete your workout.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.textSecondary(context),
                fontSize: 14,
                height: 1.5,
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
