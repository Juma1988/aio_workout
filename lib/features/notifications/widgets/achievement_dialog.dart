import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';

class AchievementDialog extends StatefulWidget {
  final bool initialEnabled;
  final void Function(bool enabled) onSave;

  const AchievementDialog({
    super.key,
    required this.initialEnabled,
    required this.onSave,
  });

  @override
  State<AchievementDialog> createState() => _AchievementDialogState();
}

class _AchievementDialogState extends State<AchievementDialog> {
  late bool _enabled;

  @override
  void initState() {
    super.initState();
    _enabled = widget.initialEnabled;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Padding(
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
                child: const Icon(Icons.emoji_events_outlined, size: 28, color: AppTheme.achievementGreen),
              ),
              const SizedBox(height: 16),
              Text(l10n.notif_achievementNotif,
                style: TextStyle(color: AppTheme.textPrimary(context), fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text(l10n.notif_achievementNotifSub,
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textTertiary(context), fontSize: 13)),
              const SizedBox(height: 20),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.notif_enableAchievement,
                  style: TextStyle(color: AppTheme.textPrimary(context), fontWeight: FontWeight.w600)),
                subtitle: Text(l10n.notif_enableAchievementSub,
                  style: TextStyle(color: AppTheme.textTertiary(context), fontSize: 12)),
                value: _enabled,
                onChanged: (v) => setState(() => _enabled = v),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    widget.onSave(_enabled);
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
