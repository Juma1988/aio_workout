import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_theme.dart';
import '../services/notification_strings.dart';

class DailyReminderSheet extends StatefulWidget {
  final bool initialEnabled;
  final TimeOfDay initialTime;
  final void Function(bool enabled, TimeOfDay time) onSave;

  const DailyReminderSheet({
    super.key,
    required this.initialEnabled,
    required this.initialTime,
    required this.onSave,
  });

  @override
  State<DailyReminderSheet> createState() => _DailyReminderSheetState();
}

class _DailyReminderSheetState extends State<DailyReminderSheet> {
  late bool _enabled;
  late TimeOfDay _time;

  @override
  void initState() {
    super.initState();
    _enabled = widget.initialEnabled;
    _time = widget.initialTime;
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _time,
      helpText: NotificationStrings.get('Choose reminder time', 'اختر وقت التذكير'),
    );
    if (picked != null && mounted) {
      setState(() => _time = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
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
              const Icon(Icons.alarm_outlined, size: 22, color: AppTheme.stepsOrange),
              const SizedBox(width: 10),
              Text(
                NotificationStrings.dailyReminderConfigTitle,
                style: TextStyle(
                  color: AppTheme.textPrimary(context),
                  fontSize: 18, fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            NotificationStrings.dailyReminderConfigBody,
            style: TextStyle(color: AppTheme.textTertiary(context), fontSize: 13),
          ),
          const SizedBox(height: 24),

          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text('Enable Daily Reminder',
              style: TextStyle(color: AppTheme.textPrimary(context), fontWeight: FontWeight.w600)),
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
                ),
                child: Row(
                  children: [
                    const Icon(Icons.access_time, size: 20, color: AppTheme.stepsOrange),
                    const SizedBox(width: 12),
                    Expanded(child: Text('Reminder time',
                      style: TextStyle(color: AppTheme.textSecondary(context), fontSize: 14))),
                    Text(_time.format(context),
                      style: TextStyle(color: AppTheme.textPrimary(context), fontSize: 16, fontWeight: FontWeight.w600)),
                    const SizedBox(width: 8),
                    Icon(Icons.edit_outlined, size: 16, color: AppTheme.textTertiary(context)),
                  ],
                ),
              ),
            ),
          ],

          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                widget.onSave(_enabled, _time);
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
