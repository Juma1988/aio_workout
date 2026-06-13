import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/colored_icon_box.dart';
import '../../core/widgets/directional_icon.dart';
import '../../l10n/app_localizations.dart';
import 'services/notification_repository.dart';
import 'services/notification_service.dart';
import 'widgets/achievement_sheet.dart';
import 'widgets/daily_reminder_sheet.dart';
import 'widgets/missed_workout_sheet.dart';
import 'widgets/notification_card.dart';
import 'widgets/quiet_hours_sheet.dart';
import 'widgets/recovery_sheet.dart';
import 'config_screens/weekly_progress_config.dart';
import 'config_screens/weight_followup_config.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  final _repo = NotificationRepository();
  final _service = NotificationService();

  bool _masterEnabled = true;
  bool _dailyReminder = true;
  bool _missedWorkout = false;
  bool _achievement = true;
  bool _recovery = true;
  bool _weeklyProgress = true;
  bool _weightFollowUp = false;
  bool _quietHoursEnabled = false;
  DateTime? _pauseUntil;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    final data = await _repo.loadAll();
    if (!mounted) return;
    setState(() {
      _masterEnabled = data['master'] as bool;
      _dailyReminder = data['dailyReminder'] as bool;
      _missedWorkout = data['missedWorkout'] as bool;
      _achievement = data['achievement'] as bool;
      _recovery = data['recovery'] as bool;
      _weeklyProgress = data['weeklyProgress'] as bool;
      _weightFollowUp = data['weightFollowUp'] as bool;
      _quietHoursEnabled = data['quietHoursEnabled'] as bool;
      _pauseUntil = data['pauseUntil'] as DateTime?;
    });
  }

  // ── Toggle handlers ──
  Future<void> _onMasterToggle(bool value) async {
    setState(() => _masterEnabled = value);
    await _repo.setMasterEnabled(value);
    if (value) {
      unawaited(_service.rescheduleAll());
    } else {
      unawaited(_service.cancelAll());
    }
  }

  void _showDailyReminderSheet() {
    HapticFeedback.lightImpact();
    _repo.dailyReminderTime.then((time) {
      if (!mounted) return;
      showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (ctx) => DailyReminderSheet(
          initialEnabled: _dailyReminder,
          initialTime: time,
          onSave: (enabled, t) async {
            await _repo.setDailyReminderEnabled(enabled);
            await _repo.setDailyReminderTime(t);
            if (mounted) {
              setState(() => _dailyReminder = enabled);
            }
            unawaited(_service.scheduleDailyReminder());
          },
        ),
      );
    });
  }

  void _showMissedWorkoutSheet() {
    HapticFeedback.lightImpact();
    _repo.missedWorkoutDelayHours.then((delay) {
      if (!mounted) return;
      showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (ctx) => MissedWorkoutSheet(
          initialEnabled: _missedWorkout,
          initialDelayHours: delay,
          onSave: (enabled, d) async {
            await _repo.setMissedWorkoutEnabled(enabled);
            await _repo.setMissedWorkoutDelayHours(d);
            if (mounted) {
              setState(() => _missedWorkout = enabled);
            }
            unawaited(_service.scheduleMissedWorkoutReminder());
          },
        ),
      );
    });
  }

  void _showAchievementSheet() {
    HapticFeedback.lightImpact();
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => AchievementSheet(
        initialEnabled: _achievement,
        onSave: (enabled) async {
          await _repo.setAchievementEnabled(enabled);
          if (mounted) {
            setState(() => _achievement = enabled);
          }
        },
      ),
    );
  }

  void _showRecoverySheet() {
    HapticFeedback.lightImpact();
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => RecoverySheet(
        initialEnabled: _recovery,
        onSave: (enabled) async {
          await _repo.setRecoveryEnabled(enabled);
          if (mounted) {
            setState(() => _recovery = enabled);
          }
          unawaited(_service.scheduleRecoverySuggestion());
        },
      ),
    );
  }

  void _openConfig(Widget screen) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  void _showQuietHoursSheet() {
    HapticFeedback.lightImpact();
    _repo.quietHoursStart.then((start) {
      _repo.quietHoursEnd.then((end) {
        if (!mounted) return;
        showModalBottomSheet(
          context: context,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (ctx) => QuietHoursSheet(
            initialEnabled: _quietHoursEnabled,
            initialStart: start,
            initialEnd: end,
            onSave: (enabled, s, e) async {
              await _repo.setQuietHoursEnabled(enabled);
              await _repo.setQuietHours(s, e);
              if (mounted) {
                setState(() {
                  _quietHoursEnabled = enabled;
                });
              }
            },
          ),
        );
      });
    });
  }

  // ── Pause 24h ──
  Future<void> _togglePause() async {
    if (_pauseUntil != null && DateTime.now().isBefore(_pauseUntil!)) {
      await _repo.setPauseUntil(null);
      setState(() => _pauseUntil = null);
      unawaited(_service.rescheduleAll());
    } else {
      final until = DateTime.now().add(const Duration(hours: 24));
      await _repo.setPauseUntil(until);
      setState(() => _pauseUntil = until);
      unawaited(_service.cancelAll());
    }
  }

  String? _pauseRemaining() {
    final l10n = AppLocalizations.of(context);
    if (_pauseUntil == null) return null;
    final remaining = _pauseUntil!.difference(DateTime.now());
    if (remaining.isNegative) return null;
    final hours = remaining.inHours;
    final minutes = remaining.inMinutes % 60;
    return '${hours}h ${minutes}m ${l10n.notif_remaining}';
  }

  Widget _sectionHeader(IconData icon, String title) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 4, bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppTheme.textSecondary(context)),
          const SizedBox(width: 8),
          Text(
            title,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _divider() {
    return Divider(
      height: 1,
      indent: 56,
      color: AppTheme.subtleFill(context),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isPaused =
        _pauseUntil != null && DateTime.now().isBefore(_pauseUntil!);
    final effectiveEnabled = _masterEnabled && !isPaused;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.notif_title),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          // ── Master toggle ──
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: Theme.of(context)
                    .colorScheme
                    .primary
                    .withValues(alpha: 0.15),
                width: 1,
              ),
            ),
            elevation: 0,
            child: Column(
              children: [
                ListTile(
                  leading: ColoredIconBox(
                    icon: Icons.notifications_outlined,
                    color: Theme.of(context).colorScheme.primary,
                    size: 40,
                  ),
                  title: Text(
                    l10n.notif_title,
                    style: TextStyle(
                      color: AppTheme.textPrimary(context),
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: Text(
                    _masterEnabled
                        ? l10n.notif_on
                        : l10n.notif_off,
                    style: TextStyle(
                      color: _masterEnabled
                          ? AppTheme.achievementGreen
                          : AppTheme.textTertiary(context),
                      fontSize: 13,
                    ),
                  ),
                  trailing: Switch.adaptive(
                    value: _masterEnabled,
                    onChanged: _onMasterToggle,
                  ),
                ),
                if (isPaused) ...[
                  _divider(),
                  ListTile(
                    leading: ColoredIconBox(
                      icon: Icons.pause_circle_outline,
                      color: AppTheme.stepsOrange,
                      size: 36,
                    ),
                    title: Text(
                      l10n.notif_pause,
                      style: TextStyle(
                        color: AppTheme.stepsOrange,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: Text(
                      _pauseRemaining() ?? '',
                      style: TextStyle(
                        color: AppTheme.textTertiary(context),
                        fontSize: 13,
                      ),
                    ),
                    trailing: TextButton(
                      onPressed: _togglePause,
                      child: Text(l10n.notif_resume),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ── Workout Reminders ──
          _sectionHeader(
            Icons.notifications_active_outlined,
            l10n.notif_workoutReminders,
          ),
          const SizedBox(height: 8),
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: Theme.of(context)
                    .colorScheme
                    .primary
                    .withValues(alpha: 0.15),
                width: 1,
              ),
            ),
            elevation: 0,
            child: Column(
              children: [
                Opacity(
                  opacity: effectiveEnabled ? 1 : 0.4,
                  child: NotificationCard(
                    title: l10n.notif_dailyReminder,
                    subtitle: l10n.notif_dailyReminderSub,
                    icon: Icons.alarm_outlined,
                    iconColor: AppTheme.stepsOrange,
                    isEnabled: effectiveEnabled && _dailyReminder,
                    onOpenSettings: _showDailyReminderSheet,
                  ),
                ),
                _divider(),
                Opacity(
                  opacity: effectiveEnabled ? 1 : 0.4,
                  child: NotificationCard(
                    title: l10n.notif_missedWorkout,
                    subtitle: l10n.notif_missedWorkoutSub,
                    icon: Icons.fitness_center_outlined,
                    iconColor: AppTheme.achievementGreen,
                    isEnabled: effectiveEnabled && _missedWorkout,
                    onOpenSettings: _showMissedWorkoutSheet,
                  ),
                ),
                _divider(),
                Opacity(
                  opacity: effectiveEnabled ? 1 : 0.4,
                  child: NotificationCard(
                    title: l10n.notif_achievementNotif,
                    subtitle: l10n.notif_achievementNotifSub,
                    icon: Icons.emoji_events_outlined,
                    iconColor: AppTheme.achievementGreen,
                    isEnabled: effectiveEnabled && _achievement,
                    onOpenSettings: _showAchievementSheet,
                  ),
                ),
                _divider(),
                Opacity(
                  opacity: effectiveEnabled ? 1 : 0.4,
                  child: NotificationCard(
                    title: l10n.notif_recovery,
                    subtitle: l10n.notif_recoverySub,
                    icon: Icons.spa_outlined,
                    iconColor: AppTheme.hydrationBlue,
                    isEnabled: effectiveEnabled && _recovery,
                    onOpenSettings: _showRecoverySheet,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ── Progress & Stats ──
          _sectionHeader(
            Icons.bar_chart_outlined,
            l10n.notif_progressStats,
          ),
          const SizedBox(height: 8),
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: Theme.of(context)
                    .colorScheme
                    .primary
                    .withValues(alpha: 0.15),
                width: 1,
              ),
            ),
            elevation: 0,
            child: Column(
              children: [
                Opacity(
                  opacity: effectiveEnabled ? 1 : 0.4,
                  child: NotificationCard(
                    title: l10n.notif_weeklyProgress,
                    subtitle: l10n.notif_weeklyProgressSub,
                    icon: Icons.trending_up_outlined,
                    iconColor: AppTheme.hydrationBlue,
                    isEnabled: effectiveEnabled && _weeklyProgress,
                    onOpenSettings: () =>
                        _openConfig(const WeeklyProgressConfigScreen()),
                  ),
                ),
                _divider(),
                Opacity(
                  opacity: effectiveEnabled ? 1 : 0.4,
                  child: NotificationCard(
                    title: l10n.notif_weightFollowUp,
                    subtitle: l10n.notif_weightFollowUpSub,
                    icon: Icons.monitor_weight_outlined,
                    iconColor: AppTheme.stepsOrange,
                    isEnabled: effectiveEnabled && _weightFollowUp,
                    onOpenSettings: () =>
                        _openConfig(const WeightFollowUpConfigScreen()),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ── Quiet Hours ──
          _sectionHeader(
            Icons.do_not_disturb_outlined,
            l10n.notif_quietHours,
          ),
          const SizedBox(height: 8),
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: Theme.of(context)
                    .colorScheme
                    .primary
                    .withValues(alpha: 0.15),
                width: 1,
              ),
            ),
            elevation: 0,
            child: ListTile(
              leading: ColoredIconBox(
                icon: Icons.dark_mode_outlined,
                color: AppTheme.textSecondary(context),
                size: 36,
              ),
              title: Text(
                l10n.notif_quietHours,
                style: TextStyle(color: AppTheme.textPrimary(context)),
              ),
              subtitle: Text(
                _quietHoursEnabled
                    ? l10n.notif_active
                    : l10n.notif_off,
                style: TextStyle(
                  color: _quietHoursEnabled
                      ? AppTheme.achievementGreen
                      : AppTheme.textTertiary(context),
                  fontSize: 13,
                ),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_quietHoursEnabled)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.subtleFill(context, 0.10),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        l10n.notif_active,
                        style: TextStyle(
                          fontSize: 11,
                          color: AppTheme.achievementGreen,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  const SizedBox(width: 4),
                  DirectionalIcon(
                    icon: Icons.chevron_right,
                    color: AppTheme.textTertiary(context),
                  ),
                ],
              ),
              onTap: _showQuietHoursSheet,
            ),
          ),

        ],
      ),
    );
  }
}

