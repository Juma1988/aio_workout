import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_theme.dart';

class QuietHoursSheet extends StatefulWidget {
  final bool initialEnabled;
  final TimeOfDay initialStart;
  final TimeOfDay initialEnd;
  final void Function(bool enabled, TimeOfDay start, TimeOfDay end) onSave;

  const QuietHoursSheet({
    super.key,
    required this.initialEnabled,
    required this.initialStart,
    required this.initialEnd,
    required this.onSave,
  });

  @override
  State<QuietHoursSheet> createState() => _QuietHoursSheetState();
}

class _QuietHoursSheetState extends State<QuietHoursSheet> {
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
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _start : _end,
      helpText: isStart ? 'Choose start time' : 'Choose end time',
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.subtleFill(context, 0.30),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Icon(
                Icons.dark_mode_outlined,
                size: 22,
                color: AppTheme.textPrimary(context),
              ),
              const SizedBox(width: 10),
              Text(
                'Quiet Hours',
                style: TextStyle(
                  color: AppTheme.textPrimary(context),
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Notifications will be suppressed between start and end time.',
            style: TextStyle(
              color: AppTheme.textTertiary(context),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 24),

          // ── Enable switch ──
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              'Enable Quiet Hours',
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
            // ── Start time ──
            InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => _pickTime(true),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.subtleFill(context, 0.06),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.wb_sunny_outlined,
                      size: 20,
                      color: AppTheme.stepsOrange,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Start',
                        style: TextStyle(
                          color: AppTheme.textSecondary(context),
                          fontSize: 14,
                        ),
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
                    Icon(
                      Icons.edit_outlined,
                      size: 16,
                      color: AppTheme.textTertiary(context),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            // ── End time ──
            InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => _pickTime(false),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.subtleFill(context, 0.06),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.nightlight_round_outlined,
                      size: 20,
                      color: AppTheme.hydrationBlue,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'End',
                        style: TextStyle(
                          color: AppTheme.textSecondary(context),
                          fontSize: 14,
                        ),
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
                    Icon(
                      Icons.edit_outlined,
                      size: 16,
                      color: AppTheme.textTertiary(context),
                    ),
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
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Done'),
            ),
          ),
        ],
      ),
    );
  }
}
