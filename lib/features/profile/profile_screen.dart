import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/localization/locale_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/colored_icon_box.dart';
import '../../core/widgets/directional_icon.dart';
import '../../core/widgets/progress_ring.dart';
import '../../core/widgets/staggered_section.dart';
import '../../data/workout_log.dart';
import '../../l10n/app_localizations.dart';
import '../../services/workout_storage_service.dart' show WorkoutStorageService, dateKey;
import '../achievements/models/achievement_category.dart';
import '../achievements/providers/achievement_provider.dart';
import '../achievements/widgets/achievement_preview_card.dart';
import '../dialogs/achivment_dialog.dart';
import '../dialogs/edit_profile_dialog.dart';
import '../dialogs/workout_plan_dialog.dart';
import '../notifications/notification_settings_screen.dart';
import '../notifications/services/notification_repository.dart';
import 'exersise_dialog.dart';
import 'home_settings_dialog.dart';
import 'changelog_dialog.dart';
import 'tips_dialog.dart';
import '../help_feedback/help_feedback_screen.dart';
import '../../core/app_version.dart';

class ProfileScreen extends StatefulWidget {
  final VoidCallback? onHomeSettingsChanged;
  final VoidCallback? onResetSteps;
  final VoidCallback? onResetHydration;
  final VoidCallback? onResetWorkout;

  const ProfileScreen({
    super.key,
    this.onHomeSettingsChanged,
    this.onResetSteps,
    this.onResetHydration,
    this.onResetWorkout,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with TickerProviderStateMixin {
  late final AnimationController _entranceController;
  bool _reduceMotion = false;
  int _restTimerSeconds = 30;

  // Profile data
  String _name = '';
  String _email = 'alex@workout.dev';
  String? _avatarPath;
  int _age = 28;
  String _goal = 'general_fitness';

  // Stats data
  int _workoutCount = 0;
  int _dayStreak = 0;

  // Language & Units
  bool _isEnglish = true;
  bool _useMetric = true;

  String get _initials {
    if (_name.trim().isEmpty) return '';
    final parts = _name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: AppTheme.kAnimEntrance,
    );
    _loadAll();
  }

  Future<void> _loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _name = prefs.getString('profile_name') ?? '';
      _email = prefs.getString('profile_email') ?? '';
      final avatarPath = prefs.getString('profile_avatar_path');
      _avatarPath = (avatarPath != null && File(avatarPath).existsSync()) ? avatarPath : null;
      _age = prefs.getInt('profile_age') ?? 28;
      _goal = prefs.getString('profile_goal') ?? 'general_fitness';
      _restTimerSeconds = prefs.getInt('rest_timer_seconds') ?? 30;
    });

    await _loadStats(prefs);

    final notifRepo = NotificationRepository();
    final lang = await notifRepo.languageCode;
    final isMetric = await notifRepo.isMetric;
    if (mounted) {
      setState(() {
        _isEnglish = lang != 'ar';
        _useMetric = isMetric;
      });
    }
  }

  Future<void> _loadStats(SharedPreferences prefs) async {
    final sessions = await WorkoutStorageService().loadSessions();

    final uniqueDays = <String>{};
    for (final s in sessions) {
      uniqueDays.add(dateKey(s.date));
    }

    final streak = _calculateStreak(sessions);

    if (!mounted) return;
    setState(() {
      _workoutCount = uniqueDays.length;
      _dayStreak = streak;
      _restTimerSeconds = prefs.getInt('rest_timer_seconds') ?? 30;
    });
  }

  int _calculateStreak(List<WorkoutSession> sessions) {
    final dates = sessions.map((s) => s.date).toSet().toList()..sort();
    if (dates.isEmpty) return 0;

    int streak = 0;
    final today = DateTime.now();
    for (int i = dates.length - 1; i >= 0; i--) {
      final expected = today.subtract(Duration(days: streak));
      if (dates[i].year == expected.year &&
          dates[i].month == expected.month &&
          dates[i].day == expected.day) {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.of(context).disableAnimations;
    if (!_reduceMotion) {
      _entranceController.forward();
    } else {
      _entranceController.value = 1.0;
    }
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  Future<void> _saveRestTimer(int seconds) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('rest_timer_seconds', seconds);
    if (mounted) {
      setState(() => _restTimerSeconds = seconds);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Semantics(
      label: 'Profile screen',
      child: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              buildStaggeredSection(
                controller: _entranceController,
                index: 0,
                reduceMotion: _reduceMotion,
                child: _buildHeader(context),
              ),
              const SizedBox(height: 24),
              buildStaggeredSection(
                controller: _entranceController,
                index: 1,
                reduceMotion: _reduceMotion,
                child: _buildIdentity(context),
              ),
              const SizedBox(height: 12),
              buildStaggeredSection(
                controller: _entranceController,
                index: 2,
                reduceMotion: _reduceMotion,
                child: _buildAchievementsPreview(context),
              ),
              const SizedBox(height: 12),
              buildStaggeredSection(
                controller: _entranceController,
                index: 3,
                reduceMotion: _reduceMotion,
                child: _buildStats(context),
              ),
              const SizedBox(height: 24),
              buildStaggeredSection(
                controller: _entranceController,
                index: 4,
                reduceMotion: _reduceMotion,
                child: _buildSettings(context),
              ),
              const SizedBox(height: 32),
              buildStaggeredSection(
                controller: _entranceController,
                index: 5,
                reduceMotion: _reduceMotion,
                child: _buildFooter(context, colorScheme),
              ),
],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Text(
          AppLocalizations.of(context).profile_title,
          style: TextStyle(
            color: AppTheme.textPrimary(context),
            fontSize: 28,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildIdentity(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final cardColor = AppTheme.cardColor(context);

    return Semantics(
      label: 'User profile: $_name',
      child: Center(
        child: Column(
          children: [
            GestureDetector(
              onTap: () => _openEditProfile(),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  CircleAvatar(
                    radius: 48,
                    backgroundColor: colorScheme.primaryContainer,
                    backgroundImage: _avatarPath != null
                        ? FileImage(File(_avatarPath!))
                        : null,
                    child: _avatarPath == null
                        ? Text(
                            _initials,
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              color: colorScheme.onPrimaryContainer,
                            ),
                          )
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: cardColor, width: 2.5),
                      ),
                      child: Icon(
                        Icons.camera_alt,
                        size: 14,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _name,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary(context),
                  ),
            ),
            Text(
              _email,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary(context),
                  ),
            ),
            if (_goal != 'general_fitness')
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  AppLocalizations.of(context).profile_goalDisplay(_goal.replaceAll('_', ' ').split(' ').map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '').join(' ')),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textTertiary(context),
                      ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '${AppLocalizations.of(context).profile_memberSince} June 2025',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textTertiary(context),
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStats(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final workoutProgress =
        _workoutCount > 0 ? (_workoutCount / 50).clamp(0.0, 1.0) : 0.0;
    final streakProgress =
        _dayStreak > 0 ? (_dayStreak / 30).clamp(0.0, 1.0) : 0.0;

    return Semantics(
      label: 'Your fitness statistics',
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              context,
              value: '$_workoutCount',
              label: l10n.profile_workouts,
              icon: Icons.fitness_center,
              color: AppTheme.achievementGreen,
              progress: workoutProgress,
              goalLabel: '50 ${l10n.profile_goal}',
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildStatCard(
              context,
              value: '$_dayStreak',
              label: l10n.profile_dayStreak,
              icon: Icons.local_fire_department,
              color: AppTheme.stepsOrange,
              progress: streakProgress,
              goalLabel: '30 ${l10n.profile_day}',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required String value,
    required String label,
    required IconData icon,
    required Color color,
    required double progress,
    required String goalLabel,
  }) {
    final numericValue =
        double.tryParse(value.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;
    final suffix = value.replaceAll(RegExp(r'[0-9]'), '');

    return Semantics(
      label: '$label: $value $goalLabel',
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          HapticFeedback.lightImpact();
        },
        child: Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: color.withValues(alpha: 0.25), width: 1),
          ),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              children: [
                Row(
                  children: [
                    ColoredIconBox(icon: icon, color: color, size: 28),
                    const Spacer(),
                    ProgressRing(
                      progress: progress,
                      centerLabel: '${(progress * 100).round()}%',
                      bottomLabel: goalLabel.split(' ').first,
                      color: color,
                      size: 32,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: numericValue),
                  duration: AppTheme.kAnimMedium,
                  curve: AppTheme.kEaseOut,
                  builder: (context, animatedValue, _) {
                    return Text(
                      '${animatedValue.toInt()}$suffix',
                      style: TextStyle(
                        color: AppTheme.textPrimary(context),
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        height: 1.0,
                      ),
                    );
                  },
                ),
                Text(
                  label,
                  style: TextStyle(
                    color: AppTheme.textTertiary(context),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAchievementsPreview(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final provider = context.watch<AchievementProvider>();
    final cats = {
      for (final cat in AchievementCategory.values)
        cat.label: provider.unlockedFor(cat),
    };

    return AchievementPreviewCard(
      count: provider.unlockedCount,
      totalCount: provider.totalCount,
      latestAchievement: provider.results
          .where((r) => r.isUnlocked)
          .toList()
          .lastOrNull
          ?.definition
          .localizedTitle(l10n),
      closest: provider.closestToUnlock,
      categoryState: cats,
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const AchievementsDialog(),
          ),
        );
      },
    );
  }

  Widget _buildSettings(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(context, Icons.manage_accounts_outlined, l10n.profile_account),
        const SizedBox(height: 8),
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
              width: 1,
            ),
          ),
          elevation: 0,
          child: Column(
            children: [
              _buildSettingsTile(
                context,
                icon: Icons.edit_outlined,
                title: l10n.profile_editProfile,
                color: Theme.of(context).colorScheme.primary,
                subtitle: l10n.profile_ageYrs(_name, _age),
                onTap: () => _openEditProfile(),
              ),
              _divider(context),
              _buildSettingsTile(
                context,
                icon: Icons.fitness_center_outlined,
                title: l10n.profile_exerciseLibrary,
                color: AppTheme.achievementGreen,
                onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ExerciseDialog()),
                  );
                },
              ),
              _divider(context),
              _buildSettingsTile(
                context,
                icon: Icons.route_outlined,
                title: l10n.profile_workoutPlan,
                color: AppTheme.hydrationBlue,
                onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) => const WorkoutPlanDialog()),
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _buildSectionHeader(context, Icons.tune, l10n.profile_preferences),
        const SizedBox(height: 8),
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
              width: 1,
            ),
          ),
          elevation: 0,
          child: Column(
            children: [
              _buildSettingsTile(
                context,
                icon: Icons.notifications_outlined,
                title: l10n.profile_notifications,
                color: AppTheme.stepsOrange,
                onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          const NotificationSettingsScreen(),
                    ),
                  );
                },
              ),
              _divider(context),
              _buildSettingsTile(
                context,
                icon: Icons.palette_outlined,
                title: l10n.profile_appearance,
                color: Theme.of(context).colorScheme.primary,
                onTap: () => _showHomeSettingsDialog(context),
              ),
              _divider(context),
              _buildRestTimerTile(context),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _buildSectionHeader(context, Icons.language_outlined, l10n.profile_languageUnits),
        const SizedBox(height: 8),
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
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
                  l10n.profile_languageToggle,
                  style: TextStyle(
                    color: AppTheme.textPrimary(context),
                    fontSize: 15,
                  ),
                ),
                subtitle: Text(
                  _isEnglish ? l10n.profile_english : l10n.profile_arabic,
                  style: TextStyle(
                    color: AppTheme.textTertiary(context),
                    fontSize: 13,
                  ),
                ),
                value: _isEnglish,
                onChanged: (v) async {
                  final code = v ? 'en' : 'ar';
                  final localeProvider = context.read<LocaleProvider>();
                  await localeProvider.setLanguageCode(code);
                  if (mounted) setState(() => _isEnglish = v);
                },
              ),
              _divider(context),
              SwitchListTile(
                contentPadding: const EdgeInsets.only(left: 16, right: 16),
                secondary: ColoredIconBox(
                  icon: Icons.straighten_outlined,
                  color: AppTheme.textSecondary(context),
                  size: 36,
                ),
                title: Text(
                  l10n.profile_metricImperial,
                  style: TextStyle(
                    color: AppTheme.textPrimary(context),
                    fontSize: 15,
                  ),
                ),
                subtitle: Text(
                  _useMetric ? l10n.profile_metric : l10n.profile_imperial,
                  style: TextStyle(
                    color: AppTheme.textTertiary(context),
                    fontSize: 13,
                  ),
                ),
                value: _useMetric,
                onChanged: (v) async {
                  final repo = NotificationRepository();
                  await repo.setMetric(v);
                  if (mounted) setState(() => _useMetric = v);
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _buildSectionHeader(context, Icons.support_outlined, l10n.profile_support),
        const SizedBox(height: 8),
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
              width: 1,
            ),
          ),
          elevation: 0,
          child: Column(
            children: [
              _buildSettingsTile(
                context,
                icon: Icons.restart_alt_outlined,
                title: l10n.profile_reset,
                color: colorSchemeOrDefault(context).error,
                onTap: () => _showResetDialog(context),
              ),
              _divider(context),
              _buildSettingsTile(
                context,
                icon: Icons.lightbulb_outline,
                title: l10n.profile_tips,
                color: Colors.amber.shade700,
                onTap: () => showTipsDialog(context),
              ),
              _divider(context),
              _buildSettingsTile(
                context,
                icon: Icons.update_rounded,
                title: l10n.profile_logUpdates,
                color: AppTheme.achievementGreen,
                onTap: () => showChangelogDialog(context),
              ),
              _divider(context),
              _buildSettingsTile(
                context,
                icon: Icons.help_outline,
                title: l10n.profile_help,
                color: Theme.of(context).colorScheme.primary,
                onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const HelpFeedbackScreen()),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  ColorScheme colorSchemeOrDefault(BuildContext context) {
    return Theme.of(context).colorScheme;
  }

  Widget _buildRestTimerTile(BuildContext context) {
    return _buildSettingsTile(
      context,
      icon: Icons.timer_outlined,
      title: AppLocalizations.of(context).profile_restTimer,
      color: AppTheme.hydrationBlue,
      subtitle: '${_restTimerSeconds}s',
      onTap: () => _showRestTimerDialog(context),
    );
  }

  void _showRestTimerDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    HapticFeedback.lightImpact();
    const options = [15, 30, 45, 60, 90];

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) {
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
                Icon(
                  Icons.timer_outlined,
                  size: 40,
                  color: AppTheme.hydrationBlue,
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.profile_restTimer,
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.profile_restTimerDesc,
                  style: TextStyle(
                    color: AppTheme.textTertiary(context),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 24),
                SegmentedButton<int>(
                  showSelectedIcon: false,
                  segments: options.map((sec) {
                    return ButtonSegment(
                      value: sec,
                      label: Text('${sec}s',
                          style: const TextStyle(fontSize: 15)),
                    );
                  }).toList(),
                  selected: {_restTimerSeconds},
                  onSelectionChanged: (selected) {
                    _saveRestTimer(selected.first);
                    setSheetState(() {});
                  },
                  style: SegmentedButton.styleFrom(
                    selectedBackgroundColor:
                        Theme.of(context).colorScheme.primaryContainer,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    style: FilledButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(l10n.profile_done),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showHomeSettingsDialog(BuildContext context) {
    HapticFeedback.lightImpact();
    showHomeSettingsDialog(
      context,
      onSettingsChanged: widget.onHomeSettingsChanged,
    );
  }

  Widget _buildSectionHeader(BuildContext context, IconData icon, String title) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 4, bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppTheme.textSecondary(context)),
          const SizedBox(width: 8),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Color color,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: ColoredIconBox(icon: icon, color: color, size: 36),
      title: Text(title, style: TextStyle(color: AppTheme.textPrimary(context))),
      subtitle: subtitle != null
          ? Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                subtitle,
                style: TextStyle(
                  color: AppTheme.textTertiary(context),
                  fontSize: 13,
                ),
              ),
            )
          : null,
      trailing: DirectionalIcon(icon: Icons.chevron_right, size: 20, color: AppTheme.textTertiary(context)),
      onTap: onTap,
    );
  }

  Widget _divider(BuildContext context) {
    return Divider(height: 1, indent: 56, color: AppTheme.subtleFill(context));
  }

  Widget _buildFooter(BuildContext context, ColorScheme colorScheme) {
    final l10n = AppLocalizations.of(context);
    return Column(
      children: [
        Semantics(
          label: 'Sign out of your account',
          child: SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              onPressed: () => _showSignOutDialog(context),
              icon: Icon(Icons.logout, color: colorScheme.error),
              label: Text(
                l10n.profile_signOut,
                style: TextStyle(color: colorScheme.error),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: colorScheme.error.withValues(alpha: 0.4)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'v$appVersion',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: AppTheme.textDisabled(context),
          ),
        ),
      ],
    );
  }

  void _openEditProfile() {
    HapticFeedback.lightImpact();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const EditProfileDialog(),
      ),
    ).then((_) => _loadAll());
  }

  void _showResetDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    HapticFeedback.lightImpact();
    bool resetWorkout = false;
    bool resetWater = false;
    bool resetSteps = false;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Row(
                children: [
                  Icon(
                    Icons.restart_alt_outlined,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(width: 10),
                  Text(l10n.profile_resetTitle),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    l10n.profile_resetSelect,
                    style: TextStyle(
                      color: AppTheme.textSecondary(context),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildResetCheckbox(
                    context,
                    icon: Icons.fitness_center_outlined,
                    label: l10n.profile_resetWorkout,
                    value: resetWorkout,
                    onChanged: (v) => setDialogState(() => resetWorkout = v ?? false),
                  ),
                  const SizedBox(height: 4),
                  _buildResetCheckbox(
                    context,
                    icon: Icons.water_drop_outlined,
                    label: l10n.profile_resetWater,
                    value: resetWater,
                    onChanged: (v) => setDialogState(() => resetWater = v ?? false),
                  ),
                  const SizedBox(height: 4),
                  _buildResetCheckbox(
                    context,
                    icon: Icons.directions_run,
                    label: l10n.profile_resetSteps,
                    value: resetSteps,
                    onChanged: (v) => setDialogState(() => resetSteps = v ?? false),
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        HapticFeedback.heavyImpact();
                        Navigator.of(ctx).pop();
                        _confirmResetAll(context);
                      },
                      icon: const Icon(Icons.delete_forever_outlined),
                      label: Text(l10n.profile_resetAllData),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Theme.of(context).colorScheme.error,
                        side: BorderSide(
                          color: Theme.of(context).colorScheme.error.withValues(alpha: 0.4),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: Text(
                    l10n.profile_resetCancel,
                    style: TextStyle(color: AppTheme.textSecondary(context)),
                  ),
                ),
                FilledButton(
                  onPressed: resetWorkout || resetWater || resetSteps
                      ? () {
                          HapticFeedback.mediumImpact();
                          Navigator.of(ctx).pop();

                          if (resetSteps) widget.onResetSteps?.call();
                          if (resetWater) widget.onResetHydration?.call();
                          if (resetWorkout) widget.onResetWorkout?.call();

                          final items = <String>[];
                          if (resetWorkout) items.add(l10n.profile_resetWorkout);
                          if (resetWater) items.add(l10n.profile_resetWater);
                          if (resetSteps) items.add(l10n.profile_resetSteps);

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(l10n.profile_resetSnackbar(items.join(', '))),
                              behavior: SnackBarBehavior.floating,
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        }
                      : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.error,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(l10n.profile_resetConfirm),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _confirmResetAll(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    HapticFeedback.lightImpact();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Icon(Icons.warning_rounded, color: Theme.of(context).colorScheme.error),
            const SizedBox(width: 10),
            Text(l10n.profile_resetAllTitle),
          ],
        ),
        content: Text(
          l10n.profile_resetAllBody,
          style: TextStyle(color: AppTheme.textSecondary(context)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              l10n.profile_resetCancel,
              style: TextStyle(color: AppTheme.textSecondary(context)),
            ),
          ),
          FilledButton(
            onPressed: () async {
              HapticFeedback.heavyImpact();
              Navigator.of(ctx).pop();
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear();
              if (!context.mounted) return;
              setState(() => _loadAll());
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(l10n.profile_resetAllSnackbar),
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(l10n.profile_resetAllConfirm),
          ),
        ],
      ),
    );
  }

  Widget _buildResetCheckbox(
    BuildContext context, {
    required IconData icon,
    required String label,
    required bool value,
    required ValueChanged<bool?> onChanged,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () => onChanged(!value),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        child: Row(
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: Checkbox(
                value: value,
                onChanged: onChanged,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Icon(icon, size: 20, color: AppTheme.textSecondary(context)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: AppTheme.textPrimary(context),
                  fontSize: 15,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSignOutDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    HapticFeedback.lightImpact();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(l10n.profile_signOutTitle),
        content: Text(
          l10n.profile_signOutBody,
          style: TextStyle(color: AppTheme.textSecondary(context)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              l10n.profile_resetCancel,
              style: TextStyle(color: AppTheme.textSecondary(context)),
            ),
          ),
          FilledButton(
            onPressed: () {
              HapticFeedback.mediumImpact();
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(l10n.profile_signOutSuccess),
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(l10n.profile_signOut),
          ),
        ],
      ),
    );
  }
}
