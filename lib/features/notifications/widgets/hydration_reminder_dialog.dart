import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';

class HydrationReminderDialog extends StatefulWidget {
  final bool initialEnabled;
  final int initialIntervalMinutes;
  final int initialStartHour;
  final int initialEndHour;
  final double hydrationGoal;
  final void Function(bool enabled, int intervalMinutes, int startHour, int endHour) onSave;

  const HydrationReminderDialog({
    super.key,
    required this.initialEnabled,
    required this.initialIntervalMinutes,
    required this.initialStartHour,
    required this.initialEndHour,
    required this.hydrationGoal,
    required this.onSave,
  });

  @override
  State<HydrationReminderDialog> createState() => _HydrationReminderDialogState();
}

class _HydrationReminderDialogState extends State<HydrationReminderDialog> {
  late bool _enabled;
  late int _intervalMinutes;
  late int _startHour;
  late int _endHour;

  static const _intervalOptions = [30, 60, 120, 180];
  static const _intervalLabels = ['30m', '1h', '2h', '3h'];

  @override
  void initState() {
    super.initState();
    _enabled = widget.initialEnabled;
    _intervalMinutes = widget.initialIntervalMinutes;
    _startHour = widget.initialStartHour;
    _endHour = widget.initialEndHour;
  }

  Future<void> _pickStartTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _startHour, minute: 0),
    );
    if (picked != null && mounted) setState(() => _startHour = picked.hour);
  }

  Future<void> _pickEndTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _endHour, minute: 0),
    );
    if (picked != null && mounted) setState(() => _endHour = picked.hour);
  }

  String _formatHour(int hour) {
    if (hour == 0) return '12 AM';
    if (hour == 12) return '12 PM';
    if (hour < 12) return '$hour AM';
    return '${hour - 12} PM';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final blue = AppTheme.hydrationBlue;
    final activeHours = _endHour > _startHour ? _endHour - _startHour : 24 - _startHour + _endHour;
    final remindersPerDay = (activeHours * 60 / _intervalMinutes).floor();
    final amountPerReminder = remindersPerDay > 0 ? (widget.hydrationGoal / remindersPerDay * 1000).round() : 0;

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
                  color: blue.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(Icons.water_drop_outlined, size: 28, color: blue),
              ),
              const SizedBox(height: 16),
              Text(l10n.notif_hydrationReminder,
                style: TextStyle(color: AppTheme.textPrimary(context), fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text(l10n.notif_hydrationReminderSub,
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textTertiary(context), fontSize: 13)),
              const SizedBox(height: 20),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.notif_hydrationEnable,
                  style: TextStyle(color: AppTheme.textPrimary(context), fontWeight: FontWeight.w600)),
                subtitle: Text(l10n.notif_hydrationEnableSub,
                  style: TextStyle(color: AppTheme.textTertiary(context), fontSize: 12)),
                value: _enabled,
                onChanged: (v) => setState(() => _enabled = v),
              ),
              if (_enabled) ...[
                const SizedBox(height: 16),
                Text(l10n.notif_hydrationInterval,
                  style: TextStyle(color: AppTheme.textSecondary(context), fontSize: 12, fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8, runSpacing: 8,
                  children: List.generate(_intervalOptions.length, (index) {
                    final isSelected = _intervalMinutes == _intervalOptions[index];
                    return GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _intervalMinutes = _intervalOptions[index]);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected ? blue.withValues(alpha: 0.2) : AppTheme.subtleFill(context, 0.06),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected ? blue : Colors.transparent,
                          ),
                        ),
                        child: Text(_intervalLabels[index],
                          style: TextStyle(
                            color: isSelected ? blue : AppTheme.textSecondary(context),
                            fontWeight: FontWeight.w600, fontSize: 13)),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 20),
                Text(l10n.notif_hydrationActiveHours,
                  style: TextStyle(color: AppTheme.textSecondary(context), fontSize: 12, fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: _pickStartTime,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: AppTheme.subtleFill(context, 0.06),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.access_time, size: 18, color: blue),
                              const SizedBox(width: 8),
                              Text(_formatHour(_startHour),
                                style: TextStyle(color: AppTheme.textPrimary(context), fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Icon(Icons.arrow_forward, size: 18, color: AppTheme.textTertiary(context)),
                    ),
                    Expanded(
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: _pickEndTime,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: AppTheme.subtleFill(context, 0.06),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.access_time, size: 18, color: blue),
                              const SizedBox(width: 8),
                              Text(_formatHour(_endHour),
                                style: TextStyle(color: AppTheme.textPrimary(context), fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(l10n.notif_hydrationRemindersPerDay,
                            style: TextStyle(color: AppTheme.textTertiary(context), fontSize: 13)),
                          Text('$remindersPerDay',
                            style: TextStyle(color: blue, fontWeight: FontWeight.w600)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(l10n.notif_hydrationAmountPerReminder,
                            style: TextStyle(color: AppTheme.textTertiary(context), fontSize: 13)),
                          Text('~${amountPerReminder}mL',
                            style: TextStyle(color: blue, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(l10n.notif_hydrationBasedOnGoal(widget.hydrationGoal.toStringAsFixed(1)),
                  style: TextStyle(color: AppTheme.textTertiary(context), fontSize: 11)),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    widget.onSave(_enabled, _intervalMinutes, _startHour, _endHour);
                    Navigator.of(context).pop();
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: blue,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text(l10n.notif_done, style: const TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
