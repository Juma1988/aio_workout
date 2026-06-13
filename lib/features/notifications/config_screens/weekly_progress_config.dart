import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../services/notification_repository.dart';
import '../services/notification_service.dart';

class WeeklyProgressConfigScreen extends StatefulWidget {
  const WeeklyProgressConfigScreen({super.key});

  @override
  State<WeeklyProgressConfigScreen> createState() =>
      _WeeklyProgressConfigScreenState();
}

class _WeeklyProgressConfigScreenState
    extends State<WeeklyProgressConfigScreen> {
  final _repo = NotificationRepository();
  final _service = NotificationService();
  int _selectedDay = DateTime.monday;
  TimeOfDay _selectedTime = const TimeOfDay(hour: 10, minute: 0);

  static const _days = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday',
    'Friday', 'Saturday', 'Sunday',
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final day = await _repo.weeklyProgressDay;
    final time = await _repo.weeklyProgressTime;
    if (mounted) {
      setState(() {
        _selectedDay = day;
        _selectedTime = time;
      });
    }
  }

  Future<void> _saveDay(int day) async {
    await _repo.setWeeklyProgressDay(day);
    unawaited(_service.scheduleWeeklyProgress());
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      helpText: 'Choose notification time',
    );
    if (picked != null && mounted) {
      setState(() => _selectedTime = picked);
      await _repo.setWeeklyProgressTime(picked);
      unawaited(_service.scheduleWeeklyProgress());
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.notif_weeklyProgress),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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
                  Icons.calendar_view_week_outlined,
                  size: 36,
                  color: AppTheme.hydrationBlue,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              l10n.notif_weeklyProgress,
              style: TextStyle(
                color: AppTheme.textPrimary(context),
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.notif_weeklyProgressConfigHeader,
              style: TextStyle(
                color: AppTheme.textSecondary(context),
                fontSize: 14,
              ),
            ),

            const SizedBox(height: 24),
            // ── Time picker row ──
            InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: _pickTime,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.subtleFill(context, 0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.hydrationBlue.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.access_time,
                      size: 20,
                      color: AppTheme.hydrationBlue,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Notification time',
                        style: TextStyle(
                          color: AppTheme.textSecondary(context),
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Text(
                      _selectedTime.format(context),
                      style: TextStyle(
                        color: AppTheme.textPrimary(context),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.edit_outlined,
                      size: 16,
                      color: AppTheme.textTertiary(context),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),
            Text(
              'Choose day',
              style: TextStyle(
                color: AppTheme.textPrimary(context),
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 8),

            Container(
              decoration: BoxDecoration(
                color: AppTheme.cardColor(context),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppTheme.hydrationBlue.withValues(alpha: 0.15),
                ),
              ),
              child: Column(
                children: List.generate(_days.length, (i) {
                  final dayIndex = i + 1;
                  final selected = dayIndex == _selectedDay;
                  return Column(
                    children: [
                      if (i > 0)
                        Divider(
                          height: 1,
                          indent: 16,
                          endIndent: 16,
                          color: AppTheme.subtleFill(context),
                        ),
                      InkWell(
                        onTap: () {
                          setState(() => _selectedDay = dayIndex);
                          _saveDay(dayIndex);
                        },
                        borderRadius: i == 0
                            ? const BorderRadius.vertical(
                                top: Radius.circular(16))
                            : i == _days.length - 1
                                ? const BorderRadius.vertical(
                                    bottom: Radius.circular(16))
                                : null,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _days[i],
                                  style: TextStyle(
                                    color: selected
                                        ? AppTheme.hydrationBlue
                                        : AppTheme.textPrimary(context),
                                    fontWeight: selected
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              if (selected)
                                Container(
                                  width: 24,
                                  height: 24,
                                  decoration: const BoxDecoration(
                                    color: AppTheme.hydrationBlue,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.check,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ),

            const SizedBox(height: 24),
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
                      'You\'ll receive your weekly summary every ${_days[_selectedDay - 1]} at ${_selectedTime.format(context)}.',
                      style: TextStyle(
                        color: AppTheme.textSecondary(context),
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
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
                  l10n.notif_done,
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
