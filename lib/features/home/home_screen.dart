import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/clock.dart';
import '../../core/theme/app_theme.dart';
import '../../core/analytics/home_analytics.dart';
import '../../data/weight_entry.dart';
import '../../data/workout_log.dart';
import '../../l10n/app_localizations.dart';
import '../dialogs/weight_log_sheet.dart';
import 'models/trend_info.dart';
import 'widgets/achievement_metric_card.dart';
import 'widgets/hydration_metric_card.dart';
import 'widgets/metric_card_frame.dart';
import 'widgets/this_week_card.dart';
import 'widgets/steps_metric_card.dart';
import 'widgets/today_workout_section.dart';
import 'widgets/weight_trend_card.dart';
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

  List<_HomeMetric> get _availableMetrics {
    final metrics = <_HomeMetric>[];
    if (widget.showAchievements) metrics.add(_HomeMetric.achievements);
    if (widget.showThisWeek) metrics.add(_HomeMetric.thisWeek);
    if (widget.showWeightTrend) metrics.add(_HomeMetric.weight);
    if (widget.showSteps) metrics.add(_HomeMetric.steps);
    if (widget.showHydration) metrics.add(_HomeMetric.hydration);
    return metrics;
  }

  Widget _buildMetricsStack(BuildContext context, List<_HomeMetric> metrics) {
    final metric = _effectiveMetric;
    return Column(
      children: [
        // Metric rail
        SizedBox(
          height: 48,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: metrics.map((m) {
              final isSelected = m == metric;
              final icon = _metricIcon(m);
              final color = _metricColor(m);
              final label = _metricLabel(m);
              return GestureDetector(
                onTap: () => setState(() => _selectedMetric = m),
                child: AnimatedContainer(
                  duration: AppTheme.kAnimFast,
                  curve: AppTheme.kEaseOut,
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? color.withValues(alpha: 0.15)
                        : AppTheme.subtleFill(context, 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? color.withValues(alpha: 0.4)
                          : Colors.transparent,
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, size: 18, color: isSelected ? color : AppTheme.textSecondary(context)),
                      const SizedBox(width: 6),
                      Text(
                        label,
                        style: TextStyle(
                          color: isSelected ? color : AppTheme.textSecondary(context),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 12),
        // Content
        AnimatedSwitcher(
          duration: AppTheme.kAnimMedium,
          child: _buildMetricBody(context, metric, key: ValueKey(metric)),
        ),
      ],
    );
  }

  IconData _metricIcon(_HomeMetric m) => switch (m) {
    _HomeMetric.achievements => Icons.emoji_events_rounded,
    _HomeMetric.thisWeek => Icons.bar_chart_rounded,
    _HomeMetric.weight => Icons.monitor_weight_outlined,
    _HomeMetric.steps => Icons.directions_walk_rounded,
    _HomeMetric.hydration => Icons.water_drop_rounded,
  };

  Color _metricColor(_HomeMetric m) => switch (m) {
    _HomeMetric.achievements => AppTheme.achievementGreen,
    _HomeMetric.thisWeek => AppTheme.stepsOrange,
    _HomeMetric.weight => AppTheme.weightPurple,
    _HomeMetric.steps => AppTheme.stepsOrange,
    _HomeMetric.hydration => AppTheme.hydrationBlue,
  };

  String _metricLabel(_HomeMetric m) {
    final l10n = AppLocalizations.of(context);
    return switch (m) {
      _HomeMetric.achievements => l10n.dialog_achievementsTitle,
      _HomeMetric.thisWeek => l10n.home_thisWeek,
      _HomeMetric.weight => l10n.home_weight,
      _HomeMetric.steps => l10n.home_steps,
      _HomeMetric.hydration => l10n.home_hydration,
    };
  }

  Widget _buildMetricBody(BuildContext context, _HomeMetric metric, {Key? key}) {
    final content = switch (metric) {
      _HomeMetric.achievements => AchievementMetricCard(),
      _HomeMetric.thisWeek => ThisWeekCard(
          barHeights: _computeWeeklyLevels(),
          totalExercises: _computeTotalExercises(),
          barAnimation: _barsController,
          barCurves: _cachedBarCurves,
          reduceMotion: _reduceMotion,
        ),
      _HomeMetric.weight => WeightTrendCard(
          entries: _weightEntries,
          goalKg: _weightGoalKg,
          trend: _computeTrend(),
          chartAnimation: _weightChartAnim,
          reduceMotion: _reduceMotion,
          onTap: () => _onWeightTap(context),
          clock: widget.clock,
        ),
      _HomeMetric.steps => StepsMetricCard(
          steps: widget.steps ?? 0,
          stepsGoal: widget.stepsGoal,
          stepsPerClick: widget.stepsPerClick,
          onStepsChanged: widget.onStepsChanged,
        ),
      _HomeMetric.hydration => HydrationMetricCard(
          liters: widget.hydrationLiters ?? 0.0,
          goal: widget.hydrationGoal,
          mlPerClick: widget.hydrationMLPerClick,
          onChanged: widget.onHydrationChanged,
        ),
    };
    return SizedBox(
      height: kMetricCardHeight,
      width: double.infinity,
      child: content,
    );
  }

  Widget _buildTodaysWorkoutSection(BuildContext context) {
    return TodayWorkoutSection(
      currentWeek: widget.currentWeek,
      currentDay: widget.currentDay,
      completedUuids: _completedUuids,
      isTodayCompleted: widget.isTodayCompleted,
      restTimerSeconds: widget.restTimerSeconds,
      restTimerExerciseUuid: _restTimerExerciseUuid,
      onExerciseToggled: widget.onExerciseToggled,
      onExerciseCompleted: widget.onExerciseCompleted,
      onFinishWorkout: _finishWorkout,
      onStartRestTimer: () {
        if (widget.restTimerSeconds <= 0) return;
        setState(() => _restTimerExerciseUuid = 'current');
      },
      onDismissRestTimer: () {
        if (mounted) setState(() => _restTimerExerciseUuid = null);
      },
      clock: widget.clock,
      allExercisesDone: _allExercisesDone,
    );
  }

  void _finishWorkout() {
    final duration = _workoutStartTime != null
        ? widget.clock.now().difference(_workoutStartTime!).inSeconds
        : 0;
    widget.onWorkoutComplete?.call(duration, _workoutStartTime ?? widget.clock.now());
  }

  bool get _allExercisesDone {
    return HomeAnalytics.areAllExercisesDone(
      currentDay: widget.currentDay,
      completedUuids: _completedUuids,
    );
  }

  List<double> _computeWeeklyLevels() {
    return HomeAnalytics.computeWeeklyLevels(
      sessions: widget.recentSessions,
      clock: widget.clock,
    );
  }

  int _computeTotalExercises() {
    return HomeAnalytics.computeTotalExercises(
      sessions: widget.recentSessions,
      clock: widget.clock,
    );
  }

  TrendInfo _computeTrend() {
    return HomeAnalytics.computeTrend(
      entries: _weightEntries,
      clock: widget.clock,
    );
  }

  void _onWeightTap(BuildContext context) {
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
}
