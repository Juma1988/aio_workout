import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';

class WeeklyProgressSheet extends StatefulWidget {
  final bool initialEnabled;
  final int initialDay;
  final TimeOfDay initialTime;
  final void Function(bool enabled, int day, TimeOfDay time) onSave;

  const WeeklyProgressSheet({
    super.key,
    required this.initialEnabled,
    required this.initialDay,
    required this.initialTime,
    required this.onSave,
  });

  @override
  State<WeeklyProgressSheet> createState() => _WeeklyProgressSheetState();
}

class _WeeklyProgressSheetState extends State<WeeklyProgressSheet> {
  late bool _enabled;
  late int _selectedDay;
  late TimeOfDay _selectedTime;

  static const _days = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday',
    'Friday', 'Saturday', 'Sunday',
  ];

  @override
  void initState() {
    super.initState();
    _enabled = widget.initialEnabled;
    _selectedDay = widget.initialDay;
    _selectedTime = widget.initialTime;
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      helpText: 'Choose notification time',
    );
    if (picked != null && mounted) {
      setState(() => _selectedTime = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
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
          Container(
            width: 56, height: 56,
            decoration: BoxDecoration(
              color: AppTheme.hydrationBlue.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.calendar_view_week_outlined, size: 28, color: AppTheme.hydrationBlue),
          ),
          const SizedBox(height: 16),
          Text(l10n.notif_weeklyProgress,
            style: TextStyle(color: AppTheme.textPrimary(context), fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(l10n.notif_weeklyProgressSub,
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.textTertiary(context), fontSize: 13)),
          const SizedBox(height: 24),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text('Enable Weekly Progress',
              style: TextStyle(color: AppTheme.textPrimary(context), fontWeight: FontWeight.w600)),
            subtitle: Text('Get a weekly summary of your stats',
              style: TextStyle(color: AppTheme.textTertiary(context), fontSize: 12)),
            value: _enabled,
            onChanged: (v) => setState(() => _enabled = v),
          ),
          if (_enabled) ...[
            const SizedBox(height: 16),
            InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: _pickTime,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: AppTheme.subtleFill(context, 0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.hydrationBlue.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.access_time, size: 20, color: AppTheme.hydrationBlue),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text('Notification time',
                        style: TextStyle(color: AppTheme.textSecondary(context), fontSize: 14)),
                    ),
                    Text(
                      _selectedTime.format(context),
                      style: TextStyle(color: AppTheme.textPrimary(context), fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.edit_outlined, size: 16, color: AppTheme.textTertiary(context)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('Choose day',
              style: TextStyle(color: AppTheme.textPrimary(context), fontWeight: FontWeight.w600, fontSize: 15)),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: AppTheme.cardColor(context),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.hydrationBlue.withValues(alpha: 0.15)),
              ),
              child: Column(
                children: List.generate(_days.length, (i) {
                  final dayIndex = i + 1;
                  final selected = dayIndex == _selectedDay;
                  return Column(
                    children: [
                      if (i > 0)
                        Divider(height: 1, indent: 16, endIndent: 16, color: AppTheme.subtleFill(context)),
                      InkWell(
                        onTap: () => setState(() => _selectedDay = dayIndex),
                        borderRadius: i == 0
                            ? const BorderRadius.vertical(top: Radius.circular(16))
                            : i == _days.length - 1
                                ? const BorderRadius.vertical(bottom: Radius.circular(16))
                                : null,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _days[i],
                                  style: TextStyle(
                                    color: selected ? AppTheme.hydrationBlue : AppTheme.textPrimary(context),
                                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              if (selected)
                                Container(
                                  width: 24, height: 24,
                                  decoration: const BoxDecoration(color: AppTheme.hydrationBlue, shape: BoxShape.circle),
                                  child: const Icon(Icons.check, size: 16, color: Colors.white),
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
          ],
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                widget.onSave(_enabled, _selectedDay, _selectedTime);
                Navigator.of(context).pop();
              },
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(l10n.notif_done),
            ),
          ),
        ],
      ),
    );
  }
}
