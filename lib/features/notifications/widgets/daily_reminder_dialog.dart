import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';

class DailyReminderDialog extends StatefulWidget {
  final bool initialEnabled;
  final TimeOfDay initialTime;
  final void Function(bool enabled, TimeOfDay time) onSave;

  const DailyReminderDialog({
    super.key,
    required this.initialEnabled,
    required this.initialTime,
    required this.onSave,
  });

  @override
  State<DailyReminderDialog> createState() => _DailyReminderDialogState();
}

class _DailyReminderDialogState extends State<DailyReminderDialog> {
  late bool _enabled;
  late TimeOfDay _time;

  @override
  void initState() {
    super.initState();
    _enabled = widget.initialEnabled;
    _time = widget.initialTime;
  }

  Future<void> _pickTime() async {
    final l10n = AppLocalizations.of(context);
    final picked = await showTimePicker(
      context: context,
      initialTime: _time,
      helpText: l10n.notif_dailyReminderConfigBody,
    );
    if (picked != null && mounted) {
      setState(() => _time = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56, height: 56,
                decoration: BoxDecoration(
                  color: AppTheme.stepsOrange.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.alarm_outlined, size: 28, color: AppTheme.stepsOrange),
              ),
              const SizedBox(height: 16),
              Text(l10n.notif_dailyReminder,
                style: TextStyle(color: AppTheme.textPrimary(context), fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text(l10n.notif_dailyReminderSub,
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textTertiary(context), fontSize: 13)),
              const SizedBox(height: 20),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.notif_enableDailyReminder,
                  style: TextStyle(color: AppTheme.textPrimary(context), fontWeight: FontWeight.w600)),
                subtitle: Text(l10n.notif_enableDailyReminderSub,
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
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.access_time, size: 20, color: AppTheme.stepsOrange),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            l10n.notif_tapToChange,
                            style: TextStyle(color: AppTheme.textSecondary(context), fontSize: 14),
                          ),
                        ),
                        Text(
                          _time.format(context),
                          style: TextStyle(
                            color: AppTheme.textPrimary(context),
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
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
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text(l10n.notif_done),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
