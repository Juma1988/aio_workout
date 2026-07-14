import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/colored_icon_box.dart';
import '../../l10n/app_localizations.dart';
import 'services/notification_repository.dart';
import 'services/notification_service.dart';
import 'widgets/achievement_dialog.dart';
import 'widgets/daily_reminder_dialog.dart';
import 'widgets/hydration_reminder_dialog.dart';
import 'widgets/missed_workout_dialog.dart';
import 'widgets/notification_card.dart';
import 'widgets/quiet_hours_dialog.dart';
import 'widgets/recovery_dialog.dart';
import 'config_screens/weekly_progress_config.dart';
import 'config_screens/weight_followup_config.dart';
import '../profile/home_settings_dialog.dart';

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

  bool _isLoading = true;
  bool _masterEnabled = true;
  bool _dailyReminder = true;
  bool _missedWorkout = false;
  bool _achievement = true;
  bool _recovery = true;
  bool _weeklyProgress = true;
  bool _weightFollowUp = false;
  bool _hydrationReminder = true;
  bool _quietHoursEnabled = false;
  DateTime? _pauseUntil;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    try {
      final data = await _repo.loadAll();
      if (!mounted) return;
      _service.setLocalizations(AppLocalizations.of(context));
      setState(() {
        _masterEnabled = data['master'] as bool;
        _dailyReminder = data['dailyReminder'] as bool;
        _missedWorkout = data['missedWorkout'] as bool;
        _achievement = data['achievement'] as bool;
        _recovery = data['recovery'] as bool;
        _weeklyProgress = data['weeklyProgress'] as bool;
        _weightFollowUp = data['weightFollowUp'] as bool;
        _hydrationReminder = data['hydrationReminder'] as bool;
        _quietHoursEnabled = data['quietHoursEnabled'] as bool;
        _pauseUntil = data['pauseUntil'] as DateTime?;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Shows a rationale dialog explaining why notification permission is needed.
  Future<bool> _showNotificationRationale() async {
    final l10n = AppLocalizations.of(context);
    final primaryColor = Theme.of(context).colorScheme.primary;
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Icon(Icons.notifications_active_outlined,
                color: primaryColor),
            const SizedBox(width: 10),
            Text(l10n.notif_title),
          ],
        ),
        content: const Text(
          'We need permission to send you workout reminders, '
          'achievement alerts, and hydration nudges.\n\n'
          'You can customize which notifications you receive below.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.notif_cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.notif_on),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  // ── Toggle handlers ──
  Future<void> _onMasterToggle(bool value) async {
    final l10n = AppLocalizations.of(context);
    if (!value) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(l10n.notif_confirmTurnOff),
          content: Text(l10n.notif_confirmTurnOffBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(l10n.notif_keepEnabled),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(l10n.notif_turnOff),
            ),
          ],
        ),
      );
      if (confirmed != false) return;
    }
    if (value) {
      // Show rationale dialog before requesting notification permission
      final proceed = await _showNotificationRationale();
      if (proceed == true) {
        if (!mounted) return;
        setState(() => _masterEnabled = true);
        await _repo.setMasterEnabled(true);
        _service.setLocalizations(AppLocalizations.of(context));
        await _service.requestPermissions();
        unawaited(_service.rescheduleAll());
      } else {
        if (!mounted) return;
        setState(() => _masterEnabled = false);
        await _repo.setMasterEnabled(false);
      }
    } else {
      setState(() => _masterEnabled = false);
      await _repo.setMasterEnabled(false);
      unawaited(_service.cancelAll());
    }
  }

  Future<void> _sendTestNotification() async {
    final l10n = AppLocalizations.of(context);
    _service.setLocalizations(l10n);
    try {
      await _service.sendTestNotification();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.notif_testSent)),
        );
      }
    } catch (e) {
      // silent
    }
  }

  void _showDailyReminderDialog() {
    HapticFeedback.lightImpact();
    _repo.dailyReminderTime.then((time) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (ctx) => DailyReminderDialog(
          initialEnabled: _dailyReminder,
          initialTime: time,
          onSave: (enabled, t) async {
            await _repo.setDailyReminderEnabled(enabled);
            await _repo.setDailyReminderTime(t);
            if (mounted) {
              setState(() => _dailyReminder = enabled);
            }
            _service.setLocalizations(AppLocalizations.of(context));
            unawaited(_service.scheduleDailyReminder());
          },
        ),
      );
    });
  }

  void _showMissedWorkoutDialog() {
    HapticFeedback.lightImpact();
    _repo.missedWorkoutDelayHours.then((delay) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (ctx) => MissedWorkoutDialog(
          initialEnabled: _missedWorkout,
          initialDelayHours: delay,
          onSave: (enabled, d) async {
            await _repo.setMissedWorkoutEnabled(enabled);
            await _repo.setMissedWorkoutDelayHours(d);
            if (mounted) {
              setState(() => _missedWorkout = enabled);
            }
            _service.setLocalizations(AppLocalizations.of(context));
            unawaited(_service.scheduleMissedWorkoutReminder());
          },
        ),
      );
    });
  }

  void _showAchievementDialog() {
    HapticFeedback.lightImpact();
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AchievementDialog(
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

  void _showRecoveryDialog() {
    HapticFeedback.lightImpact();
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => RecoveryDialog(
        initialEnabled: _recovery,
          onSave: (enabled) async {
            await _repo.setRecoveryEnabled(enabled);
            if (mounted) {
              setState(() => _recovery = enabled);
            }
            _service.setLocalizations(AppLocalizations.of(context));
            unawaited(_service.scheduleRecoverySuggestion());
          },
        ),
      );
  }

  void _showHydrationReminderDialog() {
    HapticFeedback.lightImpact();
    Future.wait([
      _repo.isHydrationReminderEnabled,
      _repo.hydrationIntervalMinutes,
      _repo.hydrationStartHour,
      _repo.hydrationEndHour,
      loadHydrationTarget(),
    ]).then((results) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (ctx) => HydrationReminderDialog(
          initialEnabled: results[0] as bool,
          initialIntervalMinutes: results[1] as int,
          initialStartHour: results[2] as int,
          initialEndHour: results[3] as int,
          hydrationGoal: results[4] as double,
          onSave: (enabled, intervalMinutes, startHour, endHour) async {
            await _repo.setHydrationReminderEnabled(enabled);
            await _repo.setHydrationIntervalMinutes(intervalMinutes);
            await _repo.setHydrationStartHour(startHour);
            await _repo.setHydrationEndHour(endHour);
            if (mounted) {
              setState(() => _hydrationReminder = enabled);
            }
            _service.setLocalizations(AppLocalizations.of(context));
            unawaited(_service.scheduleHydrationReminders());
          },
        ),
      );
    });
  }

  void _openConfig(Widget screen) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  void _showQuietHoursDialog() {
    HapticFeedback.lightImpact();
    _repo.quietHoursStart.then((start) {
      _repo.quietHoursEnd.then((end) {
        if (!mounted) return;
        showDialog(
          context: context,
          builder: (ctx) => QuietHoursDialog(
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
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
                  Divider(
                    height: 1,
                    indent: 56,
                    color: AppTheme.subtleFill(context),
                  ),
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
          const SizedBox(height: 12),

          // ── Test Notification ──
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _sendTestNotification,
              icon: const Icon(Icons.send_outlined, size: 18),
              label: Text(l10n.notif_test),
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // ── Workout Reminders ──
          _sectionHeader(
            Icons.notifications_active_outlined,
            l10n.notif_workoutReminders,
          ),
          const SizedBox(height: 8),
          Opacity(
            opacity: effectiveEnabled ? 1 : 0.4,
            child: NotificationCard(
              title: l10n.notif_dailyReminder,
              subtitle: l10n.notif_dailyReminderSub,
              icon: Icons.alarm_outlined,
              iconColor: AppTheme.stepsOrange,
              isEnabled: effectiveEnabled && _dailyReminder,
              hasSettings: true,
              onTap: effectiveEnabled ? _showDailyReminderDialog : null,
            ),
          ),
          const SizedBox(height: 8),
          Opacity(
            opacity: effectiveEnabled ? 1 : 0.4,
            child: NotificationCard(
              title: l10n.notif_missedWorkout,
              subtitle: l10n.notif_missedWorkoutSub,
              icon: Icons.fitness_center_outlined,
              iconColor: AppTheme.achievementGreen,
              isEnabled: effectiveEnabled && _missedWorkout,
              hasSettings: true,
              onTap: effectiveEnabled ? _showMissedWorkoutDialog : null,
            ),
          ),
          const SizedBox(height: 8),
          Opacity(
            opacity: effectiveEnabled ? 1 : 0.4,
            child: NotificationCard(
              title: l10n.notif_achievementNotif,
              subtitle: l10n.notif_achievementNotifSub,
              icon: Icons.emoji_events_outlined,
              iconColor: AppTheme.achievementGreen,
              isEnabled: effectiveEnabled && _achievement,
              hasSettings: true,
              onTap: effectiveEnabled ? _showAchievementDialog : null,
            ),
          ),
          const SizedBox(height: 8),
          Opacity(
            opacity: effectiveEnabled ? 1 : 0.4,
            child: NotificationCard(
              title: l10n.notif_recovery,
              subtitle: l10n.notif_recoverySub,
              icon: Icons.spa_outlined,
              iconColor: AppTheme.hydrationBlue,
              isEnabled: effectiveEnabled && _recovery,
              hasSettings: true,
              onTap: effectiveEnabled ? _showRecoveryDialog : null,
            ),
          ),
          const SizedBox(height: 8),
          Opacity(
            opacity: effectiveEnabled ? 1 : 0.4,
            child: NotificationCard(
              title: l10n.notif_hydrationReminder,
              subtitle: l10n.notif_hydrationReminderSub,
              icon: Icons.water_drop_outlined,
              iconColor: AppTheme.hydrationBlue,
              isEnabled: effectiveEnabled && _hydrationReminder,
              hasSettings: true,
              onTap: effectiveEnabled ? _showHydrationReminderDialog : null,
            ),
          ),

          const SizedBox(height: 24),

          // ── Progress & Stats ──
          _sectionHeader(
            Icons.bar_chart_outlined,
            l10n.notif_progressStats,
          ),
          const SizedBox(height: 8),
          Opacity(
            opacity: effectiveEnabled ? 1 : 0.4,
            child: NotificationCard(
              title: l10n.notif_weeklyProgress,
              subtitle: l10n.notif_weeklyProgressSub,
              icon: Icons.trending_up_outlined,
              iconColor: AppTheme.hydrationBlue,
              isEnabled: effectiveEnabled && _weeklyProgress,
              hasSettings: true,
              onTap: effectiveEnabled
                  ? () => _openConfig(const WeeklyProgressConfigScreen())
                  : null,
            ),
          ),
          const SizedBox(height: 8),
          Opacity(
            opacity: effectiveEnabled ? 1 : 0.4,
            child: NotificationCard(
              title: l10n.notif_weightFollowUp,
              subtitle: l10n.notif_weightFollowUpSub,
              icon: Icons.monitor_weight_outlined,
              iconColor: AppTheme.stepsOrange,
              isEnabled: effectiveEnabled && _weightFollowUp,
              hasSettings: true,
              onTap: effectiveEnabled
                  ? () => _openConfig(const WeightFollowUpConfigScreen())
                  : null,
            ),
          ),

          const SizedBox(height: 24),

          // ── Quiet Hours ──
          _sectionHeader(
            Icons.do_not_disturb_outlined,
            l10n.notif_quietHours,
          ),
          const SizedBox(height: 8),
          NotificationCard(
            title: l10n.notif_quietHours,
            subtitle: l10n.notif_quietHoursSub,
            icon: Icons.dark_mode_outlined,
            iconColor: AppTheme.textSecondary(context),
            isEnabled: _quietHoursEnabled,
            hasSettings: true,
            onTap: _showQuietHoursDialog,
          ),

        ],
      ),
    );
  }
}

