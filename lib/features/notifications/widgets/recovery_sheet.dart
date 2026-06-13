import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';

class RecoverySheet extends StatefulWidget {
  final bool initialEnabled;
  final void Function(bool enabled) onSave;

  const RecoverySheet({
    super.key,
    required this.initialEnabled,
    required this.onSave,
  });

  @override
  State<RecoverySheet> createState() => _RecoverySheetState();
}

class _RecoverySheetState extends State<RecoverySheet> {
  late bool _enabled;

  @override
  void initState() {
    super.initState();
    _enabled = widget.initialEnabled;
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
            child: const Icon(Icons.spa_outlined, size: 28, color: AppTheme.hydrationBlue),
          ),
          const SizedBox(height: 16),
          Text(l10n.notif_recovery,
            style: TextStyle(color: AppTheme.textPrimary(context), fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(l10n.notif_recoverySub,
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.textTertiary(context), fontSize: 13)),
          const SizedBox(height: 24),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text('Enable Recovery Suggestions',
              style: TextStyle(color: AppTheme.textPrimary(context), fontWeight: FontWeight.w600)),
            subtitle: Text('Get reminded to take rest days after consecutive workouts',
              style: TextStyle(color: AppTheme.textTertiary(context), fontSize: 12)),
            value: _enabled,
            onChanged: (v) => setState(() => _enabled = v),
          ),
          const SizedBox(height: 24),
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
