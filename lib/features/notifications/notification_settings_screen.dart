import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/colored_icon_box.dart';
import 'services/notification_repository.dart';
import 'services/notification_service.dart';
import 'services/notification_strings.dart';
import 'widgets/notification_card.dart';
import 'widgets/quiet_hours_sheet.dart';
import 'config_screens/daily_reminder_config.dart';
import 'config_screens/missed_workout_config.dart';
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
  bool _languageIsArabic = false;
  bool _useMetric = true;

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
      final lang = data['language'] as String;
      NotificationStrings.setOverride(lang);
      _languageIsArabic = lang == 'ar';
      _useMetric = data['isMetric'] as bool;
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
    if (_pauseUntil == null) return null;
    final remaining = _pauseUntil!.difference(DateTime.now());
    if (remaining.isNegative) return null;
    final hours = remaining.inHours;
    final minutes = remaining.inMinutes % 60;
    return '${hours}h ${minutes}m ${NotificationStrings.remaining}';
  }

  Widget _sectionHeader(IconData icon, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 4),
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
    final isPaused =
        _pauseUntil != null && DateTime.now().isBefore(_pauseUntil!);
    final effectiveEnabled = _masterEnabled && !isPaused;

    return Scaffold(
      appBar: AppBar(
        title: Text(NotificationStrings.notifications),
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
                    NotificationStrings.notifications,
                    style: TextStyle(
                      color: AppTheme.textPrimary(context),
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: Text(
                    _masterEnabled
                        ? NotificationStrings.on_
                        : NotificationStrings.off,
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
                      NotificationStrings.pauseNotifications,
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
                      child: Text(NotificationStrings.resumeNotifications),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 8),

          // ── Test + Pause buttons ──
          Wrap(
            spacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: _masterEnabled
                    ? () {
                        HapticFeedback.lightImpact();
                        final messenger = ScaffoldMessenger.of(context);
                        _service.sendTestNotification().then((_) {
                          if (mounted) {
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(
                                  NotificationStrings.testNotificationSent,
                                ),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          }
                        });
                      }
                    : null,
                icon: const Icon(Icons.send_outlined, size: 16),
                label: Text(NotificationStrings.testNotification),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              OutlinedButton.icon(
                onPressed: _togglePause,
                icon: Icon(
                  isPaused
                      ? Icons.play_arrow_outlined
                      : Icons.pause_outlined,
                  size: 16,
                ),
                label: Text(
                  isPaused
                      ? NotificationStrings.resumeNotifications
                      : NotificationStrings.pauseNotifications,
                ),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // ── Workout Reminders ──
          _sectionHeader(
            Icons.notifications_active_outlined,
            NotificationStrings.workoutReminders,
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
                    title: NotificationStrings.dailyReminderTitle,
                    subtitle: NotificationStrings.dailyReminderSubtitle,
                    icon: Icons.alarm_outlined,
                    iconColor: AppTheme.stepsOrange,
                    isEnabled: effectiveEnabled && _dailyReminder,
                    onOpenSettings: () =>
                        _openConfig(const DailyReminderConfigScreen()),
                  ),
                ),
                _divider(),
                Opacity(
                  opacity: effectiveEnabled ? 1 : 0.4,
                  child: NotificationCard(
                    title: NotificationStrings.missedWorkoutTitle,
                    subtitle: NotificationStrings.missedWorkoutSubtitle,
                    icon: Icons.fitness_center_outlined,
                    iconColor: AppTheme.achievementGreen,
                    isEnabled: effectiveEnabled && _missedWorkout,
                    onOpenSettings: () =>
                        _openConfig(const MissedWorkoutConfigScreen()),
                  ),
                ),
                _divider(),
                Opacity(
                  opacity: effectiveEnabled ? 1 : 0.4,
                  child: NotificationCard(
                    title: NotificationStrings.achievementTitle,
                    subtitle: NotificationStrings.achievementSubtitle,
                    icon: Icons.emoji_events_outlined,
                    iconColor: AppTheme.achievementGreen,
                    isEnabled: effectiveEnabled && _achievement,
                    onOpenSettings: () {
                      // Achievement has no config — just toast
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            '${NotificationStrings.achievementTitle} ${NotificationStrings.on_.toLowerCase()}',
                          ),
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    },
                  ),
                ),
                _divider(),
                Opacity(
                  opacity: effectiveEnabled ? 1 : 0.4,
                  child: NotificationCard(
                    title: NotificationStrings.recoveryTitle,
                    subtitle: NotificationStrings.recoverySubtitle,
                    icon: Icons.spa_outlined,
                    iconColor: AppTheme.hydrationBlue,
                    isEnabled: effectiveEnabled && _recovery,
                    onOpenSettings: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            '${NotificationStrings.recoveryTitle} ${NotificationStrings.on_.toLowerCase()}',
                          ),
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ── Progress & Stats ──
          _sectionHeader(
            Icons.bar_chart_outlined,
            NotificationStrings.progressStats,
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
                    title: NotificationStrings.weeklyProgressTitle,
                    subtitle: NotificationStrings.weeklyProgressSubtitle,
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
                    title: NotificationStrings.weightFollowUpTitle,
                    subtitle: NotificationStrings.weightFollowUpSubtitle,
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
            NotificationStrings.quietHours,
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
                NotificationStrings.quietHours,
                style: TextStyle(color: AppTheme.textPrimary(context)),
              ),
              subtitle: Text(
                _quietHoursEnabled
                    ? NotificationStrings.active
                    : NotificationStrings.off,
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
                        NotificationStrings.active,
                        style: TextStyle(
                          fontSize: 11,
                          color: AppTheme.achievementGreen,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.chevron_right,
                    color: AppTheme.textTertiary(context),
                  ),
                ],
              ),
              onTap: _showQuietHoursSheet,
            ),
          ),

          const SizedBox(height: 32),

          // ── Language & Units (for completeness) ──
          _sectionHeader(
            Icons.language_outlined,
            'Language & Units',
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
                SwitchListTile(
                  contentPadding: const EdgeInsets.only(left: 16, right: 16),
                  secondary: ColoredIconBox(
                    icon: Icons.translate_outlined,
                    color: AppTheme.textSecondary(context),
                    size: 36,
                  ),
                  title: Text(
                    'English / العربية',
                    style: TextStyle(
                      color: AppTheme.textPrimary(context),
                      fontSize: 15,
                    ),
                  ),
                  subtitle: Text(
                    _languageIsArabic ? 'العربية' : 'English',
                    style: TextStyle(
                      color: AppTheme.textTertiary(context),
                      fontSize: 13,
                    ),
                  ),
                  value: _languageIsArabic,
                  onChanged: (v) async {
                    final code = v ? 'ar' : 'en';
                    await _repo.setLanguageCode(code);
                    NotificationStrings.setOverride(code);
                    setState(() => _languageIsArabic = v);
                  },
                ),
                _divider(),
                SwitchListTile(
                  contentPadding: const EdgeInsets.only(left: 16, right: 16),
                  secondary: ColoredIconBox(
                    icon: Icons.straighten_outlined,
                    color: AppTheme.textSecondary(context),
                    size: 36,
                  ),
                  title: Text(
                    'Metric / Imperial',
                    style: TextStyle(
                      color: AppTheme.textPrimary(context),
                      fontSize: 15,
                    ),
                  ),
                  subtitle: Text(
                    _useMetric ? 'Metric (kg, km)' : 'Imperial (lb, mi)',
                    style: TextStyle(
                      color: AppTheme.textTertiary(context),
                      fontSize: 13,
                    ),
                  ),
                  value: _useMetric,
                  onChanged: (v) async {
                    await _repo.setMetric(v);
                    setState(() => _useMetric = v);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

