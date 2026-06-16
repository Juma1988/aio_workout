import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';

class MissedWorkoutDialog extends StatefulWidget {
  final bool initialEnabled;
  final int initialDelayHours;
  final void Function(bool enabled, int delayHours) onSave;

  const MissedWorkoutDialog({
    super.key,
    required this.initialEnabled,
    required this.initialDelayHours,
    required this.onSave,
  });

  @override
  State<MissedWorkoutDialog> createState() => _MissedWorkoutDialogState();
}

class _MissedWorkoutDialogState extends State<MissedWorkoutDialog> {
  late bool _enabled;
  late int _delayHours;

  static const List<int> _delayOptions = [1, 2, 3, 4, 6, 8, 12, 24];

  @override
  void initState() {
    super.initState();
    _enabled = widget.initialEnabled;
    _delayHours = widget.initialDelayHours;
  }

  String _delayLabel(int hours, AppLocalizations l10n) {
    if (hours == 1) return '1 ${l10n.notif_hour}';
    if (hours < 24) return '$hours ${l10n.notif_hours}';
    return '24 ${l10n.notif_hours} (1 ${l10n.notif_day})';
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
                  color: AppTheme.achievementGreen.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.fitness_center_outlined, size: 28, color: AppTheme.achievementGreen),
              ),
              const SizedBox(height: 16),
              Text(l10n.notif_missedWorkout,
                style: TextStyle(color: AppTheme.textPrimary(context), fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text(l10n.notif_missedWorkoutSub,
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textTertiary(context), fontSize: 13)),
              const SizedBox(height: 20),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.notif_enableMissedWorkout,
                  style: TextStyle(color: AppTheme.textPrimary(context), fontWeight: FontWeight.w600)),
                subtitle: Text(l10n.notif_enableMissedWorkoutSub,
                  style: TextStyle(color: AppTheme.textTertiary(context), fontSize: 12)),
                value: _enabled,
                onChanged: (v) => setState(() => _enabled = v),
              ),
              if (_enabled) ...[
                const SizedBox(height: 16),
                Text(l10n.notif_waitTime,
                  style: TextStyle(color: AppTheme.textPrimary(context), fontWeight: FontWeight.w600, fontSize: 15)),
                const SizedBox(height: 4),
                Text(l10n.notif_waitTimeDesc,
                  style: TextStyle(color: AppTheme.textTertiary(context), fontSize: 13)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: List.generate(_delayOptions.length, (i) {
                    final hours = _delayOptions[i];
                    final selected = hours == _delayHours;
                    return GestureDetector(
                      onTap: () => setState(() => _delayHours = hours),
                      child: AnimatedContainer(
                        duration: AppTheme.kAnimFast,
                        curve: AppTheme.kEaseOut,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
                          _delayLabel(hours, l10n),
                          style: TextStyle(
                            color: selected ? AppTheme.achievementGreen : AppTheme.textSecondary(context),
                            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    widget.onSave(_enabled, _delayHours);
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
