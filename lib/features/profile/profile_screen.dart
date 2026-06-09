import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/colored_icon_box.dart';
import '../../core/widgets/progress_ring.dart';
import '../../core/widgets/staggered_section.dart';
import '../../core/widgets/top_action.dart';
import '../../data/workout_log.dart';
import '../../services/workout_storage_service.dart';
import '../dialogs/achivment_dialog.dart';
import '../dialogs/edit_profile_dialog.dart';
import '../dialogs/workout_plan_dialog.dart';
import '../notifications/notification_settings_screen.dart';
import 'exersise_dialog.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with TickerProviderStateMixin {
  late final AnimationController _entranceController;
  bool _reduceMotion = false;
  int _restTimerSeconds = 30;

  // Profile data
  String _name = 'Alex Rivera';
  String _email = 'alex@workout.dev';
  String? _avatarPath;
  int _age = 28;
  String _goal = 'general_fitness';

  // Stats data
  int _workoutCount = 0;
  int _dayStreak = 0;
  int _totalMinutes = 0;
  int _achievementCount = 0;
  String _latestAchievement = '';

  String get _initials {
    final parts = _name.split(' ');
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
      _name = prefs.getString('profile_name') ?? 'Alex Rivera';
      _email = prefs.getString('profile_email') ?? 'alex@workout.dev';
      _avatarPath = prefs.getString('profile_avatar_path');
      _age = prefs.getInt('profile_age') ?? 28;
      _goal = prefs.getString('profile_goal') ?? 'general_fitness';
      _restTimerSeconds = prefs.getInt('rest_timer_seconds') ?? 30;
    });

    await _loadStats(prefs);
  }

  Future<void> _loadStats(SharedPreferences prefs) async {
    final sessions = await WorkoutStorageService().loadSessions();

    final uniqueDays = <String>{};
    int totalSecs = 0;
    for (final s in sessions) {
      uniqueDays.add(s.date.toIso8601String().substring(0, 10));
      for (final e in s.exercises) {
        totalSecs += e.setsCompleted;
      }
    }

    final streak = _calculateStreak(sessions);
    final unlockedAchievements = evaluateAchievements(sessions);
    final unlocked = unlockedAchievements.length;
    final latest = unlockedAchievements.isNotEmpty
        ? unlockedAchievements.last
        : null;

    if (!mounted) return;
    setState(() {
      _workoutCount = uniqueDays.length;
      _dayStreak = streak;
      _totalMinutes = (totalSecs / 60).round();
      _achievementCount = unlocked;
      _latestAchievement = latest?.title ?? '';
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
              const SizedBox(height: 24),
              buildStaggeredSection(
                controller: _entranceController,
                index: 2,
                reduceMotion: _reduceMotion,
                child: _buildStats(context),
              ),
              const SizedBox(height: 24),
              buildStaggeredSection(
                controller: _entranceController,
                index: 3,
                reduceMotion: _reduceMotion,
                child: _buildAchievementsPreview(context),
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
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Text(
          'Profile',
          style: TextStyle(
            color: AppTheme.textPrimary(context),
            fontSize: 28,
            fontWeight: FontWeight.w700,
          ),
        ),
        const Spacer(),
        TopAction(
          icon: Icons.settings_outlined,
          semanticsLabel: 'Settings',
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
                  'Goal: ${_goal.replaceAll('_', ' ').split(' ').map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '').join(' ')}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textTertiary(context),
                      ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Member since June 2025',
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
    final workoutProgress =
        _workoutCount > 0 ? (_workoutCount / 50).clamp(0.0, 1.0) : 0.0;
    final streakProgress =
        _dayStreak > 0 ? (_dayStreak / 30).clamp(0.0, 1.0) : 0.0;
    final timeProgress =
        _totalMinutes > 0 ? (_totalMinutes / 6000).clamp(0.0, 1.0) : 0.0; // 100h

    return Semantics(
      label: 'Your fitness statistics',
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              context,
              value: '$_workoutCount',
              label: 'Workouts',
              icon: Icons.fitness_center,
              color: AppTheme.achievementGreen,
              progress: workoutProgress,
              goalLabel: '50 goal',
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              context,
              value: '$_dayStreak',
              label: 'Day Streak',
              icon: Icons.local_fire_department,
              color: AppTheme.stepsOrange,
              progress: streakProgress,
              goalLabel: '30 day',
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              context,
              value: '${_totalMinutes}h',
              label: 'Total Time',
              icon: Icons.timer_outlined,
              color: AppTheme.hydrationBlue,
              progress: timeProgress,
              goalLabel: '100h goal',
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
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Row(
                  children: [
                    ColoredIconBox(icon: icon, color: color, size: 36),
                    const Spacer(),
                    ProgressRing(
                      progress: progress,
                      centerLabel: '${(progress * 100).round()}%',
                      bottomLabel: goalLabel.split(' ').first,
                      color: color,
                      size: 44,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: numericValue),
                  duration: AppTheme.kAnimMedium,
                  curve: AppTheme.kEaseOut,
                  builder: (context, animatedValue, _) {
                    return Text(
                      '${animatedValue.toInt()}$suffix',
                      style: TextStyle(
                        color: AppTheme.textPrimary(context),
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                      ),
                    );
                  },
                ),
                Text(
                  label,
                  style: TextStyle(
                    color: AppTheme.textTertiary(context),
                    fontSize: 12,
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
    final green = AppTheme.achievementGreen;

    return Semantics(
      label: 'Achievements: $_achievementCount of 12 unlocked. Latest: $_latestAchievement',
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: green.withValues(alpha: 0.25), width: 1),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            HapticFeedback.lightImpact();
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const AchievementsDialog(),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: green.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.emoji_events, color: green, size: 26),
                    ),
                    Positioned(
                      top: -2,
                      right: -2,
                      child: Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          color: AppTheme.stepsOrange,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppTheme.cardColor(context),
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            '$_achievementCount',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Achievements',
                        style: TextStyle(
                          color: green,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$_achievementCount / 12 unlocked',
                        style: TextStyle(
                          color: AppTheme.textPrimary(context),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        _latestAchievement.isNotEmpty
                            ? 'Latest: $_latestAchievement'
                            : 'Complete workouts to earn achievements',
                        style: TextStyle(
                          color: AppTheme.textTertiary(context),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: AppTheme.textDisabled(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSettings(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(context, Icons.manage_accounts_outlined, 'Account'),
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
                title: 'Edit Profile',
                color: Theme.of(context).colorScheme.primary,
                subtitle: '$_name · $_age yrs',
                onTap: () => _openEditProfile(),
              ),
              _divider(context),
              _buildSettingsTile(
                context,
                icon: Icons.fitness_center_outlined,
                title: 'Exercise Library',
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
                title: 'Workout Plan',
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
        _buildSectionHeader(context, Icons.tune, 'Preferences'),
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
                title: 'Notifications',
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
                title: 'Appearance',
                color: AppTheme.hydrationBlue,
                isSoon: true,
                onTap: () => _showComingSoon(context, 'Appearance'),
              ),
              _divider(context),
              _buildRestTimerTile(context),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _buildSectionHeader(context, Icons.support_outlined, 'Support'),
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
                title: 'Reset',
                color: colorSchemeOrDefault(context).error,
                onTap: () => _showResetDialog(context),
              ),
              _divider(context),
              _buildSettingsTile(
                context,
                icon: Icons.help_outline,
                title: 'Help & Feedback',
                color: Theme.of(context).colorScheme.primary,
                isSoon: true,
                onTap: () => _showComingSoon(context, 'Help'),
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
      title: 'Rest Timer',
      color: AppTheme.hydrationBlue,
      subtitle: '${_restTimerSeconds}s',
      onTap: () => _showRestTimerDialog(context),
    );
  }

  void _showRestTimerDialog(BuildContext context) {
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
                  'Rest Timer',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  'Time between exercise sets',
                  style: TextStyle(
                    color: AppTheme.textTertiary(context),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 24),
                SegmentedButton<int>(
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
                    child: const Text('Done'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, IconData icon, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 4),
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
    bool isSoon = false,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: ColoredIconBox(icon: icon, color: color, size: 36),
      title: Row(
        children: [
          Text(title, style: TextStyle(color: AppTheme.textPrimary(context))),
          if (isSoon) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.subtleFill(context, 0.10),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                'Soon',
                style: TextStyle(
                  fontSize: 11,
                  color: AppTheme.textTertiary(context),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
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
      trailing: Icon(Icons.chevron_right, color: AppTheme.textTertiary(context)),
      onTap: onTap,
    );
  }

  Widget _divider(BuildContext context) {
    return Divider(height: 1, indent: 56, color: AppTheme.subtleFill(context));
  }

  Widget _buildFooter(BuildContext context, ColorScheme colorScheme) {
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
                'Sign Out',
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
          'v0.1.0',
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
    ).then((result) {
      if (result == true) {
        _loadAll();
      }
    });
  }

  void _showComingSoon(BuildContext context, String feature) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
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
            const SizedBox(height: 24),
            Icon(
              Icons.construction,
              size: 48,
              color: AppTheme.textTertiary(context),
            ),
            const SizedBox(height: 16),
            Text(
              feature,
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'Coming soon!',
              style: TextStyle(color: AppTheme.textSecondary(context)),
            ),
          ],
        ),
      ),
    );
  }

  void _showResetDialog(BuildContext context) {
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
                  const Text('Reset Progress'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Select what to reset:',
                    style: TextStyle(
                      color: AppTheme.textSecondary(context),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildResetCheckbox(
                    context,
                    icon: Icons.fitness_center_outlined,
                    label: 'Daily workout progress',
                    value: resetWorkout,
                    onChanged: (v) => setDialogState(() => resetWorkout = v ?? false),
                  ),
                  const SizedBox(height: 4),
                  _buildResetCheckbox(
                    context,
                    icon: Icons.water_drop_outlined,
                    label: 'Water drank',
                    value: resetWater,
                    onChanged: (v) => setDialogState(() => resetWater = v ?? false),
                  ),
                  const SizedBox(height: 4),
                  _buildResetCheckbox(
                    context,
                    icon: Icons.directions_run,
                    label: 'Steps count',
                    value: resetSteps,
                    onChanged: (v) => setDialogState(() => resetSteps = v ?? false),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: Text(
                    'Cancel',
                    style: TextStyle(color: AppTheme.textSecondary(context)),
                  ),
                ),
                FilledButton(
                  onPressed: resetWorkout || resetWater || resetSteps
                      ? () {
                          HapticFeedback.mediumImpact();
                          Navigator.of(ctx).pop();

                          final items = <String>[];
                          if (resetWorkout) items.add('workout progress');
                          if (resetWater) items.add('water intake');
                          if (resetSteps) items.add('steps count');

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Reset: ${items.join(', ')}'),
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
                  child: const Text('Reset'),
                ),
              ],
            );
          },
        );
      },
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
    HapticFeedback.lightImpact();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text('Sign Out'),
        content: Text(
          'Are you sure you want to sign out?',
          style: TextStyle(color: AppTheme.textSecondary(context)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppTheme.textSecondary(context)),
            ),
          ),
          FilledButton(
            onPressed: () {
              HapticFeedback.mediumImpact();
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Signed out successfully'),
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
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }
}
