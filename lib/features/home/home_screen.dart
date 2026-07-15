import 'dart:async';
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/clock.dart';
import '../../core/theme/app_theme.dart';
import '../../data/exercise.dart';
import '../../data/weight_entry.dart';
import '../../data/workout_log.dart';
import '../../l10n/app_localizations.dart';
import '../achievements/providers/achievement_provider.dart';
import '../dialogs/achivment_dialog.dart';
import '../dialogs/exercise_progress_dialog.dart';
import '../dialogs/weight_log_sheet.dart';
import '../hydration/hydration_history_screen.dart';
import '../steps/step_history_screen.dart';
import 'models/trend_info.dart';
import 'painters/weight_spark_painter.dart';
import 'rest_timer.dart';
import 'widgets/exercise_info_sheet.dart';
import 'widgets/progress_ring.dart';
import 'widgets/top_action.dart';

enum _HomeMetric {
  /// First icon in the rail (when visible).
  achievements,
  /// Default selected tab.
  thisWeek,
  weight,
  steps,
  hydration,
}

class HomeScreen extends StatefulWidget {
  final VoidCallback? onThemeToggle;
  final double? hydrationLiters;
  final int? steps;
  final Set<String> completedExerciseUuids;
  final ValueChanged<double>? onHydrationChanged;
  final ValueChanged<int>? onStepsChanged;
  final ValueChanged<String>? onExerciseCompleted;
  final ValueChanged<String>? onExerciseToggled;
  final int currentWeek;
  final int currentDay;
  final void Function(int durationSeconds, DateTime startTime)? onWorkoutComplete;
  final List<WeightEntry>? weightEntries;
  final double? weightGoalKg;
  final ValueChanged<WeightEntry>? onWeightLogged;
  final Clock clock;
  final VoidCallback? onRefresh;
  final int restTimerSeconds;
  final List<WorkoutSession>? recentSessions;

  // Home section visibility
  final bool showSteps;
  final bool showAchievements;
  final bool showHydration;
  final bool showWeightTrend;
  final bool showThisWeek;

  final int stepsPerClick;
  final int hydrationMLPerClick;
  final int stepsGoal;
  final double hydrationGoal;
  final bool useSensor;

  /// When true, today's workout has already been completed.
  /// Instead of showing the exercise list, a "Workout Complete!" message is shown.
  final bool isTodayCompleted;

  const HomeScreen({
    super.key,
    this.onThemeToggle,
    this.hydrationLiters,
    this.steps,
    this.completedExerciseUuids = const {},
    this.onHydrationChanged,
    this.onStepsChanged,
    this.onExerciseCompleted,
    this.onExerciseToggled,
    this.currentWeek = 1,
    this.currentDay = 1,
    this.onWorkoutComplete,
    this.weightEntries,
    this.weightGoalKg,
    this.onWeightLogged,
    this.clock = const SystemClock(),
    this.onRefresh,
    this.restTimerSeconds = 0,
    this.recentSessions,
    this.showSteps = true,
    this.showAchievements = true,
    this.showHydration = true,
    this.showWeightTrend = true,
    this.showThisWeek = true,
    this.stepsPerClick = 200,
    this.hydrationMLPerClick = 250,
    this.stepsGoal = 10000,
    this.hydrationGoal = 2.5,
    this.useSensor = true,
    this.isTodayCompleted = false,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

List<Exercise> getTodayExercises(int day) {
  if (isRestDay(day)) {
    return [restExercise];
  }
  return [
    highKneeMarch,
    plank,
    deadBug,
    gluteBridge,
    birdDog,
    sideLyingLegRaise,
  ];
}

class _HomeScreenState extends State<HomeScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  Timer? _greetingTimer;

  Set<String> get _completedUuids => widget.completedExerciseUuids;
  List<WeightEntry> get _weightEntries => widget.weightEntries ?? [];
  double? get _weightGoalKg => widget.weightGoalKg;

  late final AnimationController _entranceController;
  late final AnimationController _barsController;
  late final AnimationController _weightTapController;
  late final AnimationController _weightChartController;
  late final Animation<double> _weightChartAnim;

  bool _reduceMotion = false;
  bool _hasAnimated = false;
  String _lastGreeting = '';
  DateTime? _workoutStartTime;
  final List<CurvedAnimation?> _cachedSectionCurves = List.filled(7, null);
  final List<CurvedAnimation?> _cachedBarCurves = List.filled(7, null);
  String? _restTimerExerciseUuid;

  /// Stacked metrics: This Week is default.
  _HomeMetric _selectedMetric = _HomeMetric.thisWeek;

  String get _greeting {
    final now = widget.clock.now();
    final hour = now.hour;
    if (hour < 12) return 'morning';
    if (hour < 17) return 'afternoon';
    return 'evening';
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _lastGreeting = _greeting;
    _greetingTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (!mounted) return;
      final newGreeting = _greeting;
      if (newGreeting != _lastGreeting) {
        setState(() => _lastGreeting = newGreeting);
      }
    });
    _entranceController = AnimationController(
      vsync: this,
      duration: AppTheme.kAnimEntrance,
    );
    _barsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 820),
    );
    _weightTapController = AnimationController(
      vsync: this,
      duration: AppTheme.kAnimFast,
    );
    _weightChartController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _weightChartAnim = CurvedAnimation(
      parent: _weightChartController,
      curve: AppTheme.kEaseOut,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.of(context).disableAnimations;
    if (_hasAnimated) return;
    _hasAnimated = true;
    if (!_reduceMotion) {
      _entranceController.forward();
      _barsController.forward();
      _weightChartController.forward();
    } else {
      _entranceController.value = 1.0;
      _barsController.value = 1.0;
      _weightChartController.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(covariant HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    final metrics = _availableMetrics;
    if (metrics.isNotEmpty && !metrics.contains(_selectedMetric)) {
      _selectedMetric = metrics.first;
    }
  }

  _HomeMetric get _effectiveMetric {
    final metrics = _availableMetrics;
    if (metrics.isEmpty) return _HomeMetric.thisWeek;
    if (metrics.contains(_selectedMetric)) return _selectedMetric;
    return metrics.first;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _greetingTimer?.cancel();
    for (final c in _cachedSectionCurves) {
      c?.dispose();
    }
    for (final c in _cachedBarCurves) {
      c?.dispose();
    }
    _entranceController.dispose();
    _barsController.dispose();
    _weightTapController.dispose();
    _weightChartController.dispose();
    super.dispose();
  }

  Widget _buildStaggeredSection({required Widget child, required int index}) {
    if (_reduceMotion) return child;

    final idx = index.clamp(0, 6);
    _cachedSectionCurves[idx] ??= CurvedAnimation(
      parent: _entranceController,
      curve: Interval(
        (idx * 0.115).clamp(0.0, 0.7),
        ((idx * 0.115) + 0.38).clamp(0.0, 1.0),
        curve: AppTheme.kEaseOut,
      ),
    );
    final curved = _cachedSectionCurves[idx]!;

    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0.0, 0.09),
          end: Offset.zero,
        ).animate(curved),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[
      _buildStaggeredSection(child: _buildHeader(context), index: 0),
    ];

    int sectionIndex = 1;

    final metrics = _availableMetrics;
    if (metrics.isNotEmpty) {
      children.addAll([
        const SizedBox(height: 16),
        _buildStaggeredSection(
          child: _buildMetricsStack(context, metrics),
          index: sectionIndex++,
        ),
      ]);
    }

    children.addAll([
      const SizedBox(height: 16),
      _buildStaggeredSection(
        child: _buildTodaysWorkoutSection(context),
        index: sectionIndex++,
      ),
    ]);

    return Semantics(
      label: 'Home dashboard',
      child: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: RefreshIndicator(
              onRefresh: () async => widget.onRefresh?.call(),
              displacement: 60,
              edgeOffset: 8,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: children,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final greetingText = switch (_greeting) {
      'morning' => l10n.home_greeting_morning,
      'afternoon' => l10n.home_greeting_afternoon,
      _ => l10n.home_greeting_evening,
    };
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(
                label: greetingText,
                child: Text(
                  greetingText,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary(context),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                l10n.home_todaysWorkout,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppTheme.textSecondary(context),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        TopAction(
          icon: Theme.of(context).brightness == Brightness.dark
              ? Icons.light_mode_rounded
              : Icons.dark_mode_rounded,
          onTap: widget.onThemeToggle,
          semanticsLabel: 'Toggle theme',
        ),
      ],
    );
  }

  Widget _buildAchievementCard(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final provider = context.watch<AchievementProvider>();
    final green = AppTheme.achievementGreen;
    final count = provider.unlockedCount;
    final total = provider.totalCount;
    final progress = total > 0 ? count / total : 0.0;
    final latest = provider.results
        .where((r) => r.isUnlocked)
        .toList()
        .lastOrNull
        ?.definition
        .localizedTitle(l10n);
    final closest = provider.closestToUnlock;

    return Semantics(
      label: 'Achievements: $count of $total unlocked',
      button: true,
      child: _metricCardFrame(
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const AchievementsDialog(),
              ),
            );
          },
          borderRadius: BorderRadius.circular(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _metricHeader(
                context: context,
                icon: Icons.emoji_events_rounded,
                title: l10n.dialog_achievementsTitle,
                trailing: Text(
                  '$count / $total',
                  style: TextStyle(
                    color: green,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: _kMetricBodyHeight,
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            latest != null && latest.isNotEmpty
                                ? latest
                                : l10n.dialog_achievementsTitle,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: AppTheme.textPrimary(context),
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          if (closest != null && !closest.isUnlocked)
                            Text(
                              closest.definition.localizedTitle(l10n),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: AppTheme.textTertiary(context),
                                fontSize: 13,
                              ),
                            )
                          else
                            Text(
                              '$count unlocked',
                              style: TextStyle(
                                color: AppTheme.textTertiary(context),
                                fontSize: 13,
                              ),
                            ),
                          const SizedBox(height: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: progress.clamp(0.0, 1.0),
                              minHeight: 8,
                              backgroundColor: AppTheme.subtleFill(context),
                              color: green,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    ProgressRing(
                      progress: progress,
                      centerLabel: '${(progress * 100).round()}%',
                      bottomLabel: l10n.dialog_achievementsUnlocked,
                      color: green,
                      size: 72,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 16,
                child: Text(
                  latest != null ? 'Latest: $latest' : '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppTheme.textTertiary(context),
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<_HomeMetric> get _availableMetrics {
    // Order = icon rail order. Achievements first; This Week stays default selection.
    final list = <_HomeMetric>[];
    if (widget.showAchievements) list.add(_HomeMetric.achievements);
    if (widget.showThisWeek) list.add(_HomeMetric.thisWeek);
    if (widget.showWeightTrend) list.add(_HomeMetric.weight);
    if (widget.showSteps) list.add(_HomeMetric.steps);
    if (widget.showHydration) list.add(_HomeMetric.hydration);
    return list;
  }

  IconData _metricIcon(_HomeMetric m) {
    switch (m) {
      case _HomeMetric.achievements:
        return Icons.emoji_events_rounded;
      case _HomeMetric.thisWeek:
        return Icons.bar_chart_rounded;
      case _HomeMetric.weight:
        return Icons.monitor_weight_outlined;
      case _HomeMetric.steps:
        return Icons.directions_walk_rounded;
      case _HomeMetric.hydration:
        return Icons.water_drop_rounded;
    }
  }

  Color _metricColor(BuildContext context, _HomeMetric m) {
    switch (m) {
      case _HomeMetric.achievements:
        return AppTheme.achievementGreen;
      case _HomeMetric.thisWeek:
        return Theme.of(context).colorScheme.primary;
      case _HomeMetric.weight:
        return AppTheme.weightPurple;
      case _HomeMetric.steps:
        return AppTheme.stepsOrange;
      case _HomeMetric.hydration:
        return AppTheme.hydrationBlue;
    }
  }

  String _metricLabel(AppLocalizations l10n, _HomeMetric m) {
    switch (m) {
      case _HomeMetric.achievements:
        return l10n.dialog_achievementsTitle;
      case _HomeMetric.thisWeek:
        return l10n.home_thisWeek;
      case _HomeMetric.weight:
        return l10n.home_weight;
      case _HomeMetric.steps:
        return l10n.home_steps;
      case _HomeMetric.hydration:
        return l10n.home_hydration;
    }
  }

  Widget _buildMetricsStack(BuildContext context, List<_HomeMetric> metrics) {
    final l10n = AppLocalizations.of(context);
    final selected = _effectiveMetric;
    final selectedColor = _metricColor(context, selected);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Magic full-width sliding pill rail
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              height: 58,
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: AppTheme.cardColor(context).withValues(alpha: 0.72),
                border: Border.all(
                  color: AppTheme.subtleFill(context, 0.10),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.28 : 0.06),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final n = metrics.length;
                  if (n == 0) return const SizedBox.shrink();
                  final gap = 4.0;
                  final cellW =
                      (constraints.maxWidth - gap * (n - 1)) / n;
                  final index = metrics.indexOf(selected).clamp(0, n - 1);
                  final pillLeft = index * (cellW + gap);

                  return Stack(
                    children: [
                      // Sliding glow pill
                      AnimatedPositioned(
                        duration: _reduceMotion
                            ? Duration.zero
                            : const Duration(milliseconds: 380),
                        curve: Curves.easeOutBack,
                        left: pillLeft,
                        width: cellW,
                        top: 0,
                        bottom: 0,
                        child: AnimatedContainer(
                          duration: AppTheme.kAnimMedium,
                          curve: AppTheme.kEaseOut,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(15),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                selectedColor.withValues(alpha: 0.95),
                                Color.lerp(
                                  selectedColor,
                                  Colors.black,
                                  0.22,
                                )!,
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: selectedColor.withValues(
                                  alpha: isDark ? 0.55 : 0.35,
                                ),
                                blurRadius: 16,
                                offset: const Offset(0, 4),
                                spreadRadius: -2,
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Equal-width hit targets + icons
                      Row(
                        children: [
                          for (var i = 0; i < n; i++) ...[
                            if (i > 0) SizedBox(width: gap),
                            Expanded(
                              child: _buildMagicMetricIcon(
                                context,
                                metric: metrics[i],
                                selected: metrics[i] == selected,
                                label: _metricLabel(l10n, metrics[i]),
                                onTap: () {
                                  if (metrics[i] == _selectedMetric) return;
                                  HapticFeedback.mediumImpact();
                                  setState(
                                    () => _selectedMetric = metrics[i],
                                  );
                                },
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Card content with scale + fade + slide magic
        AnimatedSwitcher(
          duration: _reduceMotion
              ? Duration.zero
              : const Duration(milliseconds: 420),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          layoutBuilder: (currentChild, previousChildren) {
            return Stack(
              alignment: Alignment.topCenter,
              children: [
                ...previousChildren,
                if (currentChild != null) currentChild,
              ],
            );
          },
          transitionBuilder: (child, anim) {
            final curved = CurvedAnimation(
              parent: anim,
              curve: Curves.easeOutCubic,
            );
            return FadeTransition(
              opacity: curved,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.96, end: 1.0).animate(curved),
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.0, 0.06),
                    end: Offset.zero,
                  ).animate(curved),
                  child: child,
                ),
              ),
            );
          },
          child: KeyedSubtree(
            key: ValueKey(selected),
            child: _buildMetricBody(context, selected),
          ),
        ),
      ],
    );
  }

  Widget _buildMagicMetricIcon(
    BuildContext context, {
    required _HomeMetric metric,
    required bool selected,
    required String label,
    required VoidCallback onTap,
  }) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(15),
          splashColor: Colors.white.withValues(alpha: 0.12),
          highlightColor: Colors.white.withValues(alpha: 0.06),
          child: SizedBox(
            height: double.infinity,
            child: Center(
              child: AnimatedScale(
                scale: selected ? 1.14 : 1.0,
                duration: AppTheme.kAnimMedium,
                curve: Curves.easeOutBack,
                child: Icon(
                  _metricIcon(metric),
                  size: selected ? 26 : 22,
                  color: selected
                      ? Colors.white
                      : AppTheme.textTertiary(context),
                  shadows: selected
                      ? [
                          Shadow(
                            color: Colors.black.withValues(alpha: 0.25),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Matches "This Week": header + 16 gap + 110 body + 8 gap + footer + padding.
  static const double _kMetricCardHeight = 208;
  static const double _kMetricBodyHeight = 110;
  static const EdgeInsets _kMetricPadding =
      EdgeInsets.fromLTRB(16, 16, 16, 18);

  Widget _buildMetricBody(BuildContext context, _HomeMetric metric) {
    final content = switch (metric) {
      _HomeMetric.achievements => _buildAchievementCard(context),
      _HomeMetric.thisWeek => _buildThisWeekSection(context),
      _HomeMetric.weight => _buildWeightTrendCard(context),
      _HomeMetric.steps => _buildStepsCard(context),
      _HomeMetric.hydration => _buildHydrationCard(context),
    };
    return SizedBox(
      height: _kMetricCardHeight,
      width: double.infinity,
      child: content,
    );
  }

  Widget _metricCardFrame({required Widget child}) {
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: SizedBox.expand(
        child: Padding(
          padding: _kMetricPadding,
          child: child,
        ),
      ),
    );
  }

  Widget _metricHeader({
    required BuildContext context,
    required IconData icon,
    required String title,
    Widget? trailing,
  }) {
    return SizedBox(
      height: 24,
      child: Row(
        children: [
          Icon(icon, color: AppTheme.textSecondary(context), size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppTheme.textPrimary(context),
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }

  Widget _buildStepsCard(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final steps = widget.steps ?? 0;
    final goal = widget.stepsGoal <= 0 ? 10000 : widget.stepsGoal;
    final progress = (steps / goal).clamp(0.0, 1.0);
    final color = AppTheme.stepsOrange;

    return Semantics(
      label: '${l10n.home_steps}, $steps',
      child: _metricCardFrame(
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            widget.onStepsChanged?.call(steps + widget.stepsPerClick);
          },
          onLongPress: () {
            HapticFeedback.mediumImpact();
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const StepHistoryScreen()),
            );
          },
          borderRadius: BorderRadius.circular(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _metricHeader(
                context: context,
                icon: Icons.directions_walk_rounded,
                title: l10n.home_steps,
                trailing: Text(
                  '$steps / $goal',
                  style: TextStyle(
                    color: AppTheme.textTertiary(context),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: _kMetricBodyHeight,
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0, end: steps.toDouble()),
                            duration: AppTheme.kAnimMedium,
                            curve: AppTheme.kEaseOut,
                            builder: (context, value, _) {
                              return Text(
                                '${value.round()}',
                                style: TextStyle(
                                  color: AppTheme.textPrimary(context),
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                  height: 1.0,
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: progress,
                              minHeight: 8,
                              backgroundColor: AppTheme.subtleFill(context),
                              color: color,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    ProgressRing(
                      progress: progress,
                      centerLabel: '${(progress * 100).round()}%',
                      bottomLabel: l10n.home_steps,
                      color: color,
                      size: 72,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 16,
                child: Text(
                  l10n.home_tapToAdd,
                  style: TextStyle(
                    color: AppTheme.textDisabled(context),
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHydrationCard(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final liters = widget.hydrationLiters ?? 0.0;
    final goal = widget.hydrationGoal <= 0 ? 2.5 : widget.hydrationGoal;
    final progress = (liters / goal).clamp(0.0, 1.0);
    final color = AppTheme.hydrationBlue;
    final addLiters = widget.hydrationMLPerClick / 1000.0;

    return Semantics(
      label:
          '${l10n.home_hydration}, ${liters.toStringAsFixed(2)} ${l10n.home_liters}',
      child: _metricCardFrame(
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            final next = (liters + addLiters).clamp(0.0, goal * 3);
            widget.onHydrationChanged?.call(next);
          },
          onLongPress: () {
            HapticFeedback.mediumImpact();
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const HydrationHistoryScreen(),
              ),
            );
          },
          borderRadius: BorderRadius.circular(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _metricHeader(
                context: context,
                icon: Icons.water_drop_rounded,
                title: l10n.home_hydration,
                trailing: Text(
                  '${liters.toStringAsFixed(2)} / ${goal.toStringAsFixed(1)}',
                  style: TextStyle(
                    color: AppTheme.textTertiary(context),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: _kMetricBodyHeight,
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0, end: liters),
                            duration: AppTheme.kAnimMedium,
                            curve: AppTheme.kEaseOut,
                            builder: (context, value, _) {
                              return Text(
                                '${value.toStringAsFixed(2)} ${l10n.home_liters}',
                                style: TextStyle(
                                  color: AppTheme.textPrimary(context),
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                  height: 1.0,
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: progress,
                              minHeight: 8,
                              backgroundColor: AppTheme.subtleFill(context),
                              color: color,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    ProgressRing(
                      progress: progress,
                      centerLabel: '${(progress * 100).round()}%',
                      bottomLabel: l10n.home_hydration,
                      color: color,
                      size: 72,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 16,
                child: Text(
                  l10n.home_tapToAdd,
                  style: TextStyle(
                    color: AppTheme.textDisabled(context),
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThisWeekSection(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final days = [
      l10n.weekday_monday_abbr,
      l10n.weekday_tuesday_abbr,
      l10n.weekday_wednesday_abbr,
      l10n.weekday_thursday_abbr,
      l10n.weekday_friday_abbr,
      l10n.weekday_saturday_abbr,
      l10n.weekday_sunday_abbr,
    ];

    final levels = _computeWeeklyLevels();
    // Count total exercises completed this week across all sessions.
    final totalExercises = (widget.recentSessions ?? [])
        .where((s) {
          final now = widget.clock.now();
          final weekday = now.weekday;
          final monday = now.subtract(Duration(days: weekday - 1));
          final mondayDate = DateTime(monday.year, monday.month, monday.day);
          final weekEnd = mondayDate.add(const Duration(days: 7));
          return !s.date.isBefore(mondayDate) && !s.date.isAfter(weekEnd);
        })
        .fold<int>(0, (sum, s) => sum + s.exercises.length);

    return Semantics(
      label: '${l10n.home_thisWeek} activity chart',
      child: _metricCardFrame(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _metricHeader(
              context: context,
              icon: Icons.bar_chart_rounded,
              title: l10n.home_thisWeek,
              trailing: Text(
                '$totalExercises ${l10n.home_exercises}',
                style: TextStyle(
                  color: AppTheme.textTertiary(context),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: _kMetricBodyHeight,
              child: AnimatedBuilder(
                animation: _barsController,
                builder: (context, _) {
                  for (int i = 0; i < 7; i++) {
                    final double start = 0.08 + (i * 0.065);
                    _cachedBarCurves[i] ??= CurvedAnimation(
                      parent: _barsController,
                      curve: Interval(
                        start,
                        (start + 0.55).clamp(0.0, 1.0),
                        curve: AppTheme.kEaseOut,
                      ),
                    );
                  }
                  final barAnims = List.generate(7, (i) {
                    return Tween<double>(begin: 0.0, end: levels[i]).animate(
                      _cachedBarCurves[i]!,
                    );
                  });

                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: List.generate(7, (i) {
                      final h = barAnims[i].value;
                      final isActive = h > 0.05;
                      return Semantics(
                        label: '${days[i]}: ${(h * 100).round()}% activity',
                        child: Container(
                          width: 28,
                          height: (_kMetricBodyHeight - 10) * h,
                          decoration: BoxDecoration(
                            color: isActive
                                ? Theme.of(context).colorScheme.primary
                                : AppTheme.subtleFill(context),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      );
                    }),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 16,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: days
                    .map(
                      (d) => SizedBox(
                        width: 28,
                        child: Text(
                          d,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppTheme.textTertiary(context),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodaysWorkoutSection(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final completed = _completedUuids.length;

    // ── Completed for today: show a done card instead of the exercise list ──
    if (widget.isTodayCompleted) {
      final nextProgress = ProgramProgress(
        currentWeek: widget.currentWeek,
        currentDay: widget.currentDay,
      ).advance();
      final nextFocus = getLocalizedFocus(l10n, nextProgress.currentWeek, nextProgress.currentDay);

      return Semantics(
        label: '${l10n.home_todaysWorkout} complete',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  l10n.home_todaysWorkout,
                  style: TextStyle(
                    color: AppTheme.textPrimary(context),
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.achievementGreen.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    l10n.notif_done,
                    style: TextStyle(
                      color: AppTheme.achievementGreen,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: AppTheme.achievementGreen.withValues(alpha: 0.25),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: AppTheme.achievementGreen.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.emoji_events_rounded,
                        color: AppTheme.achievementGreen,
                        size: 30,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.home_workoutComplete,
                            style: TextStyle(
                              color: AppTheme.textPrimary(context),
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            l10n.home_noExercises,
                            style: TextStyle(
                              color: AppTheme.textSecondary(context),
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppTheme.subtleFill(context, 0.08),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              '${l10n.home_week} ${nextProgress.currentWeek} \u2014 ${l10n.home_day} ${nextProgress.currentDay} \u2014 $nextFocus',
                              style: TextStyle(
                                color: AppTheme.textTertiary(context),
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Semantics(
      label: l10n.home_todaysWorkout,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                l10n.home_todaysWorkout,
                style: TextStyle(
                  color: AppTheme.textPrimary(context),
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.subtleFill(context, 0.15),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Semantics(
                  label: isRestDay(widget.currentDay)
                      ? (_allExercisesDone ? '${l10n.home_restDay} complete' : l10n.home_restDay)
                      : '$completed of ${getTodayExercises(widget.currentDay).length} ${l10n.home_exercises} ${l10n.home_completed}',
                  child: Text(
                    isRestDay(widget.currentDay)
                        ? (_allExercisesDone ? l10n.home_restDay : '0')
                        : '$completed/${getTodayExercises(widget.currentDay).length}',
                    style: TextStyle(
                      color: AppTheme.textSecondary(context),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${l10n.home_week} ${widget.currentWeek} \u2014 ${l10n.home_day} ${widget.currentDay} \u2014 ${getLocalizedFocus(l10n, widget.currentWeek, widget.currentDay)}',
            style: TextStyle(
              color: AppTheme.textTertiary(context),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 16),

          // ── Rest timer banner ──
          if (_restTimerExerciseUuid != null && widget.restTimerSeconds > 0)
            RestTimer(
              key: ValueKey('rest_$_restTimerExerciseUuid'),
              seconds: widget.restTimerSeconds,
              onComplete: () {
                if (mounted) setState(() => _restTimerExerciseUuid = null);
              },
            ),

          ...List.generate(getTodayExercises(widget.currentDay).length, (i) {
            final ex = getTodayExercises(widget.currentDay)[i];
            final isDone = _completedUuids.contains(ex.uuid);
              return Padding(
              padding: EdgeInsets.only(bottom: i < getTodayExercises(widget.currentDay).length - 1 ? 8 : 0),
              child: _buildExerciseTile(
                exercise: ex,
                isDone: isDone,
                onToggle: () {
                  final uuid = ex.uuid;
                  final wasDone = _completedUuids.contains(uuid);
                  widget.onExerciseToggled?.call(uuid);
                  if (!wasDone) {
                    _startRestTimer(uuid);
                    // Brief pause so user sees the final checkmark before
                    // auto-completing the workout.
                    Future.delayed(const Duration(milliseconds: 600), () {
                      if (mounted) _checkAutoComplete();
                    });
                  }
                },
                onPlay: () => _onPlayExercise(context, ex),
                onInfo: () => _showExerciseInfo(context, ex),
              ),
            );
          }),

          // ── Finish Workout button (shows when all exercises are done) ──
          if (_allExercisesDone) ...[
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _finishWorkout,
                icon: const Icon(Icons.check_circle_rounded, size: 22),
                label: Text(
                  l10n.home_completeWorkout,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _startRestTimer(String exerciseUuid) {
    if (widget.restTimerSeconds <= 0) return;
    setState(() => _restTimerExerciseUuid = exerciseUuid);
  }

  void _onPlayExercise(BuildContext context, Exercise ex) {
    HapticFeedback.lightImpact();
    _workoutStartTime ??= widget.clock.now();
    setState(() => _restTimerExerciseUuid = null); // dismiss rest timer
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ExerciseProgressDialog(
          exercise: ex,
          onComplete: () {
            widget.onExerciseCompleted?.call(ex.uuid);
            _startRestTimer(ex.uuid);
            _checkAutoComplete();
          },
        ),
      ),
    );
  }

  void _checkAutoComplete() {
    final exercises = getTodayExercises(widget.currentDay);
    final allDone = exercises
        .every((e) => _completedUuids.contains(e.uuid));
    if (!allDone) return;

    _finishWorkout();
  }

  void _finishWorkout() {
    final duration = _workoutStartTime != null
        ? widget.clock.now().difference(_workoutStartTime!).inSeconds
        : 0;
    widget.onWorkoutComplete?.call(duration, _workoutStartTime ?? widget.clock.now());
  }

  bool get _allExercisesDone {
    final exercises = getTodayExercises(widget.currentDay);
    return exercises.isNotEmpty &&
        exercises.every((e) => _completedUuids.contains(e.uuid));
  }



  Widget _buildExerciseTile({
    required Exercise exercise,
    required bool isDone,
    required VoidCallback onToggle,
    required VoidCallback onPlay,
    required VoidCallback onInfo,
  }) {
    final setsReps = exercise.getRecommendedDisplay();
    final suffix = setsReps.isNotEmpty ? ' · $setsReps' : '';
    final green = AppTheme.achievementGreen;

    return Semantics(
      label: '${exercise.name}$suffix, ${isDone ? "completed" : "not completed"}',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: AppTheme.cardColor(context),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Semantics(
              label: isDone ? 'Mark as incomplete' : 'Mark as complete',
              child: InkWell(
                onTap: () {
                  HapticFeedback.lightImpact();
                  onToggle();
                },
                borderRadius: BorderRadius.circular(5),
                child: Padding(
                  padding: const EdgeInsets.all(11),
                  child: AnimatedContainer(
                    duration: AppTheme.kAnimFast,
                    curve: AppTheme.kEaseOutBack,
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isDone
                            ? AppTheme.achievementGreen
                            : AppTheme.subtleFill(context, 0.30),
                        width: 1.8,
                      ),
                      borderRadius: BorderRadius.circular(5),
                      color: isDone
                          ? AppTheme.achievementGreen.withValues(alpha: 0.15)
                          : null,
                    ),
                    child: isDone
                        ? TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0.6, end: 1.0),
                            duration: AppTheme.kAnimFast,
                            curve: Curves.easeOutBack,
                            builder: (context, scale, _) => Transform.scale(
                              scale: scale,
                              child: const Icon(
                                Icons.check,
                                size: 16,
                                color: AppTheme.achievementGreen,
                              ),
                            ),
                          )
                        : null,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    exercise.name,
                    style: TextStyle(
                      color: AppTheme.textPrimary(context),
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    setsReps.isNotEmpty ? setsReps : '—',
                    style: TextStyle(
                      color: AppTheme.textTertiary(context),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Semantics(
                  label: isDone
                      ? '${exercise.name} completed'
                      : 'Start exercise ${exercise.name}',
                  child: InkWell(
                    onTap: isDone ? null : onPlay,
                    borderRadius: BorderRadius.circular(8),
                    child: AnimatedContainer(
                      duration: AppTheme.kAnimFast,
                      curve: AppTheme.kEaseOut,
                      width: 44,
                      height: 44,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isDone
                            ? green.withValues(alpha: 0.15)
                            : AppTheme.subtleFill(context, 0.10),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        isDone
                            ? Icons.check_circle_rounded
                            : Icons.play_circle_outline,
                        size: 20,
                        color: isDone
                            ? green
                            : AppTheme.textSecondary(context),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Semantics(
                  label: 'Show exercise info for ${exercise.name}',
                  child: InkWell(
                    onTap: onInfo,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 44,
                      height: 44,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppTheme.subtleFill(context, 0.10),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.info_outline_rounded,
                        size: 20,
                        color: AppTheme.textSecondary(context),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showExerciseInfo(BuildContext context, Exercise ex) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => ExerciseInfoSheet(exercise: ex),
    );
  }

  List<double> _computeWeeklyLevels() {
    final sessions = widget.recentSessions;
    if (sessions == null || sessions.isEmpty) {
      return List.filled(7, 0.0);
    }

    final now = widget.clock.now();
    final weekday = now.weekday; // 1=Mon .. 7=Sun
    final monday = now.subtract(Duration(days: weekday - 1));
    final mondayDate = DateTime(monday.year, monday.month, monday.day);
    final weekEnd = mondayDate.add(const Duration(days: 7));

    // Bar height = fraction of exercises completed per day.
    // Days with no session get 0. A day where all planned exercises were
    // completed gets 1.0. Partial workouts get proportional height.
    // Rest days always count as 100% (recovery is progress!).
    final levels = List.filled(7, 0.0);
    for (final s in sessions) {
      if (s.date.isBefore(mondayDate) || s.date.isAfter(weekEnd)) continue;
      final dayIdx = s.date.weekday - 1; // 0=Mon..6=Sun
      if (isRestDay(s.dayNumber)) {
        levels[dayIdx] = 1.0;
      } else {
        final planned = s.plannedExerciseUuids.length;
        if (planned == 0) {
          levels[dayIdx] = 1.0;
        } else {
          levels[dayIdx] = (s.exercises.length / planned).clamp(0.0, 1.0);
        }
      }
    }

    return levels;
  }

  // ── Weight Chart Card ──

  TrendInfo _computeTrend() {
    final entries = _weightEntries;
    if (entries.length < 2) return TrendInfo.none();

    final sorted = List<WeightEntry>.from(entries)
      ..sort((a, b) => a.date.compareTo(b.date));

    final weekAgo = widget.clock.now().subtract(const Duration(days: 7));
    final weekEntries = sorted.where((e) => e.date.isAfter(weekAgo)).toList();

    if (weekEntries.length >= 2) {
      final current = weekEntries.last.weightKg;
      final previous = weekEntries.first.weightKg;
      return TrendInfo(
        changeKg: current - previous,
        period: 'this week',
      );
    }

    final last = sorted.last.weightKg;
    final prev = sorted[sorted.length - 2].weightKg;
    return TrendInfo(
      changeKg: last - prev,
      period: 'last entry',
    );
  }

  void     _onWeightTap(BuildContext context) {
    HapticFeedback.lightImpact();
    if (!_reduceMotion) {
      _weightTapController.forward(from: 0.0).then((_) {
        if (mounted) _weightTapController.reverse();
      });
    }
    final current = _weightEntries.isNotEmpty
        ? _weightEntries.reduce((a, b) => a.date.isAfter(b.date) ? a : b).weightKg
        : 70.0;
    showDialog(
      context: context,
      builder: (ctx) => WeightLogSheet(
        currentWeightKg: current,
        weightGoalKg: _weightGoalKg,
        clock: widget.clock,
        onSave: (entry) {
          widget.onWeightLogged?.call(entry);
          if (!_reduceMotion) {
            _weightChartController.forward(from: 0.0);
          }
        },
      ),
    );
  }

  Widget _buildWeightTrendCard(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final purple = AppTheme.weightPurple;
    final entries = _weightEntries;
    final sorted = List<WeightEntry>.from(entries)
      ..sort((a, b) => a.date.compareTo(b.date));
    final currentWeight =
        sorted.isNotEmpty ? sorted.last.weightKg : 0.0;
    final trend = _computeTrend();
    final goalKg = _weightGoalKg;
    final hasGoal = goalKg != null && goalKg > 0;
    final goalProgress = hasGoal && currentWeight > 0
        ? (currentWeight / goalKg).clamp(0.0, 1.0)
        : 0.0;

    return Semantics(
      label: 'Weight tracker, ${currentWeight.toStringAsFixed(1)} kilograms',
      child: _metricCardFrame(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _metricHeader(
              context: context,
              icon: Icons.monitor_weight_outlined,
              title: l10n.home_weight,
              trailing: trend.isValid
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(trend.icon, size: 16, color: trend.color(context)),
                        const SizedBox(width: 4),
                        Text(
                          trend.displayText,
                          style: TextStyle(
                            color: trend.color(context),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    )
                  : null,
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: _kMetricBodyHeight,
              width: double.infinity,
              child: sorted.isEmpty
                  ? _buildWeightEmpty(context)
                  : GestureDetector(
                      onTap: () => _onWeightTap(context),
                      child: AnimatedBuilder(
                        animation: _weightChartAnim,
                        builder: (context, _) {
                          return CustomPaint(
                            size: const Size(double.infinity, _kMetricBodyHeight),
                            painter: WeightSparkPainter(
                              entries: sorted,
                              lineColor: purple,
                              animationValue: _reduceMotion
                                  ? 1.0
                                  : _weightChartAnim.value,
                            ),
                          );
                        },
                      ),
                    ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 16,
              child: sorted.isEmpty
                  ? const SizedBox.shrink()
                  : Row(
                      children: [
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0.0, end: currentWeight),
                          duration: AppTheme.kAnimMedium,
                          curve: AppTheme.kEaseOut,
                          builder: (context, animated, _) {
                            return Text(
                              '${animated.toStringAsFixed(1)} ${l10n.home_kg}',
                              style: TextStyle(
                                color: AppTheme.textPrimary(context),
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 8),
                        if (hasGoal) ...[
                          SizedBox(
                            width: 60,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(3),
                              child: LinearProgressIndicator(
                                value: goalProgress.clamp(0.0, 1.0),
                                backgroundColor: AppTheme.subtleFill(context),
                                color: purple,
                                minHeight: 6,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${(goalProgress * 100).round()}%',
                            style: TextStyle(
                              color: AppTheme.textTertiary(context),
                              fontSize: 12,
                            ),
                          ),
                        ],
                        const Spacer(),
                        Text(
                          _lastLoggedText(sorted),
                          style: TextStyle(
                            color: AppTheme.textTertiary(context),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  String _lastLoggedText(List<WeightEntry> sorted) {
    if (sorted.isEmpty) return '';
    final l10n = AppLocalizations.of(context);
    final last = sorted.last.date;
    final diff = widget.clock.now().difference(last);
    if (diff.inDays == 0) return l10n.home_loggedToday;
    if (diff.inDays == 1) return l10n.home_loggedYesterday;
    return l10n.home_loggedDaysAgo(diff.inDays);
  }

  Widget _buildWeightEmpty(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return GestureDetector(
      onTap: () => _onWeightTap(context),
      behavior: HitTestBehavior.opaque,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.monitor_weight_outlined,
              size: 32,
              color: AppTheme.textDisabled(context),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.home_logWeight,
              style: TextStyle(
                color: AppTheme.textSecondary(context),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              l10n.home_tapToRecord,
              style: TextStyle(
                color: AppTheme.textTertiary(context),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
