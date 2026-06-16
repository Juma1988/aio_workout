import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';

class QuietHoursDialog extends StatefulWidget {
  final bool initialEnabled;
  final TimeOfDay initialStart;
  final TimeOfDay initialEnd;
  final void Function(bool enabled, TimeOfDay start, TimeOfDay end) onSave;

  const QuietHoursDialog({
    super.key,
    required this.initialEnabled,
    required this.initialStart,
    required this.initialEnd,
    required this.onSave,
  });

  @override
  State<QuietHoursDialog> createState() => _QuietHoursDialogState();
}

class _QuietHoursDialogState extends State<QuietHoursDialog> {
  late bool _enabled;
  late TimeOfDay _start;
  late TimeOfDay _end;

  @override
  void initState() {
    super.initState();
    _enabled = widget.initialEnabled;
    _start = widget.initialStart;
    _end = widget.initialEnd;
  }

  Future<void> _pickTime(bool isStart) async {
    final l10n = AppLocalizations.of(context);
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _start : _end,
      helpText: isStart ? l10n.notif_chooseStartTime : l10n.notif_chooseEndTime,
    );
    if (picked != null && mounted) {
      setState(() {
        if (isStart) {
          _start = picked;
        } else {
          _end = picked;
        }
      });
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
                  color: AppTheme.textSecondary(context).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(Icons.dark_mode_outlined, size: 28, color: AppTheme.textSecondary(context)),
              ),
              const SizedBox(height: 16),
              Text(
                l10n.notif_quietHours,
                style: TextStyle(
                  color: AppTheme.textPrimary(context),
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.notif_quietHoursDesc,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppTheme.textTertiary(context),
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 20),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  l10n.notif_enableQuietHours,
                  style: TextStyle(
                    color: AppTheme.textPrimary(context),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                value: _enabled,
                onChanged: (v) => setState(() => _enabled = v),
              ),
              if (_enabled) ...[
                const SizedBox(height: 16),
                InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => _pickTime(true),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: AppTheme.subtleFill(context, 0.06),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.wb_sunny_outlined, size: 20, color: AppTheme.stepsOrange),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            l10n.notif_startTime,
                            style: TextStyle(color: AppTheme.textSecondary(context), fontSize: 14),
                          ),
                        ),
                        Text(
                          _start.format(context),
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
                const SizedBox(height: 8),
                InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => _pickTime(false),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: AppTheme.subtleFill(context, 0.06),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.nightlight_round_outlined, size: 20, color: AppTheme.hydrationBlue),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            l10n.notif_endTime,
                            style: TextStyle(color: AppTheme.textSecondary(context), fontSize: 14),
                          ),
                        ),
                        Text(
                          _end.format(context),
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
                    widget.onSave(_enabled, _start, _end);
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
