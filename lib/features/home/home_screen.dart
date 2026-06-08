import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_theme.dart';
import '../../data/exercise.dart';
import '../../data/workout_log.dart';
import '../dialogs/achivment_dialog.dart';
import '../dialogs/exercise_progress_dialog.dart';

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
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

final todayExercises = [
  highKneeMarch,
  plank,
  deadBug,
  gluteBridge,
  birdDog,
  sideLyingLegRaise,
];

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  double get _hydrationLiters => widget.hydrationLiters ?? 0.0;
  int get _steps => widget.steps ?? 0;
  Set<String> get _completedUuids => widget.completedExerciseUuids;

  late final AnimationController _entranceController;
  late final AnimationController _barsController;
  late final AnimationController _hydrationTapController;
  late final AnimationController _stepsTapController;

  bool _reduceMotion = false;
  final Set<String> _completedViaDialog = {};
  DateTime? _workoutStartTime;

  String get _focus => getFocusForDay(widget.currentWeek, widget.currentDay);

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning!';
    if (hour < 17) return 'Good afternoon!';
    return 'Good evening!';
  }

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: AppTheme.kAnimEntrance,
    );
    _barsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 820),
    );
    _hydrationTapController = AnimationController(
      vsync: this,
      duration: AppTheme.kAnimFast,
    );
    _stepsTapController = AnimationController(
      vsync: this,
      duration: AppTheme.kAnimFast,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.of(context).disableAnimations;
    if (!_reduceMotion) {
      _entranceController.forward();
      _barsController.forward();
    } else {
      _entranceController.value = 1.0;
      _barsController.value = 1.0;
    }
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _barsController.dispose();
    _hydrationTapController.dispose();
    _stepsTapController.dispose();
    super.dispose();
  }

  Widget _buildStaggeredSection({required Widget child, required int index}) {
    if (_reduceMotion) return child;

    final double start = (index * 0.115).clamp(0.0, 0.7);
    final Animation<double> curved = CurvedAnimation(
      parent: _entranceController,
      curve: Interval(
        start,
        (start + 0.38).clamp(0.0, 1.0),
        curve: AppTheme.kEaseOut,
      ),
    );

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
    return Semantics(
      label: 'Home dashboard',
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStaggeredSection(child: _buildHeader(context), index: 0),
              const SizedBox(height: 24),
              _buildStaggeredSection(
                child: _buildAchievementCard(context),
                index: 1,
              ),
              const SizedBox(height: 8),
              _buildStaggeredSection(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _buildStepsCard(context)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildHydrationCard(context)),
                  ],
                ),
                index: 2,
              ),
              const SizedBox(height: 24),
              _buildStaggeredSection(
                child: _buildThisWeekSection(context),
                index: 3,
              ),
              const SizedBox(height: 24),
              _buildStaggeredSection(
                child: _buildTodaysWorkoutSection(context),
                index: 4,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(
                label: _greeting,
                child: Text(
                  _greeting,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary(context),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "Let's crush today's workout",
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppTheme.textSecondary(context),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        _TopAction(
          icon: Theme.of(context).brightness == Brightness.dark
              ? Icons.wb_sunny_rounded
              : Icons.nightlight_round,
          onTap: widget.onThemeToggle,
          semanticsLabel: 'Toggle theme',
        ),
      ],
    );
  }

  Widget _buildAchievementCard(BuildContext context) {
    final green = AppTheme.achievementGreen;

    return Semantics(
      label: 'Achievements: 1 of 12 unlocked. Latest: First Steps',
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
                        child: const Center(
                          child: Text(
                            '1',
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
                        '1 / 12 unlocked',
                        style: TextStyle(
                          color: AppTheme.textPrimary(context),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        'Latest: First Steps',
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

  Widget _buildStepsCard(BuildContext context) {
    final orange = AppTheme.stepsOrange;

    return Semantics(
      label: 'Steps: $_steps of 10000',
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _onStepsTap(context),
        child: AnimatedBuilder(
          animation: _stepsTapController,
          builder: (context, child) {
            final scale = _reduceMotion
                ? 1.0
                : 0.92 + (0.08 * _stepsTapController.value);
            return Transform.scale(
              scale: scale,
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: orange.withValues(alpha: 0.25),
                    width: 1,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: orange.withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                Icons.directions_run,
                                color: orange,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Steps',
                                      style: TextStyle(
                                        color: orange,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                      ),
                                    ),
                                    TweenAnimationBuilder<double>(
                                      key: ValueKey(_steps),
                                      tween: Tween(
                                        begin: 0.0,
                                        end: _steps.toDouble(),
                                      ),
                                      duration: AppTheme.kAnimMedium,
                                      curve: AppTheme.kEaseOut,
                                      builder: (context, animatedSteps, _) {
                                        return Text(
                                          animatedSteps.toInt().toString(),
                                          style: TextStyle(
                                            color: AppTheme.textPrimary(context),
                                            fontSize: 26,
                                            fontWeight: FontWeight.w800,
                                            height: 1.2,
                                          ),
                                        );
                                      },
                                    ),
                                    Text(
                                      'Tap to add',
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
                      _ProgressRing(
                        progress: (_steps / 10000.0).clamp(0.0, 1.0),
                        centerLabel: '${((_steps / 10000) * 100).round()}%',
                        bottomLabel: '10k',
                        color: orange,
                        size: 50,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _onStepsTap(BuildContext context) {
    HapticFeedback.lightImpact();
    final newVal = _steps + 200;
    widget.onStepsChanged?.call(newVal);
    if (!_reduceMotion) {
      _stepsTapController.forward(from: 0.0).then((_) {
        if (mounted) _stepsTapController.reverse();
      });
    }
  }

  void _onHydrationTap(BuildContext context) {
    HapticFeedback.lightImpact();
    final newVal = (_hydrationLiters + 0.25).clamp(0.0, 2.5);
    widget.onHydrationChanged?.call(newVal);
    if (!_reduceMotion) {
      _hydrationTapController.forward(from: 0.0).then((_) {
        if (mounted) _hydrationTapController.reverse();
      });
    }
  }

  Widget _buildHydrationCard(BuildContext context) {
    final blue = AppTheme.hydrationBlue;

    return Semantics(
      label: 'Hydration: ${_hydrationLiters.toStringAsFixed(1)} liters of 2.5',
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _onHydrationTap(context),
        child: AnimatedBuilder(
          animation: _hydrationTapController,
          builder: (context, child) {
            final scale = _reduceMotion
                ? 1.0
                : 0.92 + (0.08 * _hydrationTapController.value);
            return Transform.scale(
              scale: scale,
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: blue.withValues(alpha: 0.25),
                    width: 1,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: blue.withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                Icons.water_drop,
                                color: blue,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Hydration',
                                    style: TextStyle(
                                      color: blue,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                  TweenAnimationBuilder<double>(
                                    key: ValueKey(_hydrationLiters),
                                    tween: Tween(
                                      begin: 0.0,
                                      end: _hydrationLiters,
                                    ),
                                    duration: AppTheme.kAnimMedium,
                                    curve: AppTheme.kEaseOut,
                                    builder: (context, animatedLiters, _) {
                                      return Text(
                                        '${animatedLiters.toStringAsFixed(1)}L',
                                        style: TextStyle(
                                          color: AppTheme.textPrimary(context),
                                          fontSize: 26,
                                          fontWeight: FontWeight.w800,
                                          height: 1.2,
                                        ),
                                      );
                                    },
                                  ),
                                  Text(
                                    'Tap to add',
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
                      _ProgressRing(
                        progress: (_hydrationLiters / 2.5).clamp(0.0, 1.0),
                        centerLabel:
                            '${((_hydrationLiters / 2.5) * 100).round()}%',
                        bottomLabel: '2.5L',
                        color: blue,
                        size: 50,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildThisWeekSection(BuildContext context) {
    final days = ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su'];
    final levels = [0.55, 0.35, 0.65, 0.25, 0.0, 0.9, 0.35];

    return Semantics(
      label: 'This week activity chart',
      child: Card(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.bar_chart,
                    color: AppTheme.textSecondary(context),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'This Week',
                    style: TextStyle(
                      color: AppTheme.textPrimary(context),
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '4 workouts',
                    style: TextStyle(
                      color: AppTheme.textTertiary(context),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              AnimatedBuilder(
                animation: _barsController,
                builder: (context, _) {
                  final barAnims = List.generate(7, (i) {
                    final double start = 0.08 + (i * 0.065);
                    return Tween<double>(begin: 0.0, end: levels[i]).animate(
                      CurvedAnimation(
                        parent: _barsController,
                        curve: Interval(
                          start,
                          (start + 0.55).clamp(0.0, 1.0),
                          curve: AppTheme.kEaseOut,
                        ),
                      ),
                    );
                  });

                  return SizedBox(
                    height: 110,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: List.generate(7, (i) {
                        final h = barAnims[i].value;
                        final isActive = h > 0.05;
                        return Semantics(
                          label: '${days[i]}: ${(h * 100).round()}% activity',
                          child: Container(
                            width: 28,
                            height: 100 * h,
                            decoration: BoxDecoration(
                              color: isActive
                                  ? Theme.of(context).colorScheme.primary
                                  : AppTheme.subtleFill(context),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        );
                      }),
                    ),
                  );
                },
              ),
              const SizedBox(height: 8),
              Row(
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTodaysWorkoutSection(BuildContext context) {
    final completed = _completedUuids.length;

    return Semantics(
      label: "Today's workout",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                "Today's Workout",
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
                  label: '$completed of ${todayExercises.length} exercises completed',
                  child: Text(
                    '$completed/${todayExercises.length}',
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
            'Week ${widget.currentWeek} \u2014 Day ${widget.currentDay} \u2014 $_focus',
            style: TextStyle(
              color: AppTheme.textTertiary(context),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 16),

          ...List.generate(todayExercises.length, (i) {
            final ex = todayExercises[i];
            final isDone = _completedUuids.contains(ex.uuid);
            final isDoneViaDialog = _completedViaDialog.contains(ex.uuid);
              return Padding(
              padding: EdgeInsets.only(bottom: i < todayExercises.length - 1 ? 8 : 0),
              child: _buildExerciseTile(
                exercise: ex,
                isDone: isDone,
                isDoneViaDialog: isDoneViaDialog,
                onToggle: () {
                  final uuid = ex.uuid;
                  if (_completedUuids.contains(uuid)) {
                    setState(() => _completedViaDialog.remove(uuid));
                  }
                  widget.onExerciseToggled?.call(uuid);
                },
                onPlay: () => _startExercise(context, ex),
                onInfo: () => _showExerciseInfo(context, ex),
              ),
            );
          }),

        ],
      ),
    );
  }

  void _startExercise(BuildContext context, Exercise ex) {
    HapticFeedback.lightImpact();
    _workoutStartTime ??= DateTime.now();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ExerciseProgressDialog(
          exercise: ex,
          onComplete: () {
            widget.onExerciseCompleted?.call(ex.uuid);
            setState(() => _completedViaDialog.add(ex.uuid));
            _checkAutoComplete();
          },
        ),
      ),
    );
  }

  void _checkAutoComplete() {
    final allDone = todayExercises
        .every((e) => _completedViaDialog.contains(e.uuid));
    if (!allDone) return;

    final duration = _workoutStartTime != null
        ? DateTime.now().difference(_workoutStartTime!).inSeconds
        : 0;
    widget.onWorkoutComplete?.call(duration, _workoutStartTime ?? DateTime.now());
  }

  Widget _buildExerciseTile({
    required Exercise exercise,
    required bool isDone,
    required bool isDoneViaDialog,
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
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  onToggle();
                },
                behavior: HitTestBehavior.opaque,
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
                  label: isDoneViaDialog
                      ? '${exercise.name} completed'
                      : 'Start exercise ${exercise.name}',
                  child: GestureDetector(
                    onTap: isDoneViaDialog ? null : onPlay,
                    behavior: HitTestBehavior.opaque,
                    child: AnimatedContainer(
                      duration: AppTheme.kAnimFast,
                      curve: AppTheme.kEaseOut,
                      width: 44,
                      height: 44,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isDoneViaDialog
                            ? green.withValues(alpha: 0.15)
                            : AppTheme.subtleFill(context, 0.10),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        isDoneViaDialog
                            ? Icons.check_circle_rounded
                            : Icons.play_circle_outline,
                        size: 20,
                        color: isDoneViaDialog
                            ? green
                            : AppTheme.textSecondary(context),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Semantics(
                  label: 'Show exercise info for ${exercise.name}',
                  child: GestureDetector(
                    onTap: onInfo,
                    behavior: HitTestBehavior.opaque,
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
    final cat = ex.category;
    final muscle = ex.targetMuscle;
    final lvlColor = ex.recommendedLevel.color;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.subtleFill(context, 0.30),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              ex.name,
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            if (ex.description != null && ex.description!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  ex.description!,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppTheme.textSecondary(context),
                    height: 1.5,
                  ),
                ),
              ),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                _pill(context, ex.recommendedLevel.label, lvlColor),
                _pill(context, muscle.label, muscle.color),
                _pill(context, cat.label, cat.color),
              ],
            ),
            if (ex.equipment != null && ex.equipment!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Equipment: ${ex.equipment}',
                  style: TextStyle(color: AppTheme.textTertiary(context)),
                ),
              ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _launchYouTube(ex.name),
                icon: const Icon(Icons.play_circle_outline),
                label: const Text('Watch on YouTube'),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.4),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _launchYouTube(String query) async {
    final encoded = Uri.encodeComponent('$query workout');
    final url = 'https://www.youtube.com/results?search_query=$encoded';
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Widget _pill(BuildContext context, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

}

class _TopAction extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final String semanticsLabel;

  const _TopAction({required this.icon, this.onTap, this.semanticsLabel = ''});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticsLabel,
      child: Material(
        color: AppTheme.topActionBackground(context),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            width: 42,
            height: 42,
            child: Icon(icon, size: 20, color: AppTheme.textSecondary(context)),
          ),
        ),
      ),
    );
  }
}

class _ProgressRing extends StatelessWidget {
  final double progress;
  final String centerLabel;
  final String bottomLabel;
  final Color color;
  final double size;

  const _ProgressRing({
    required this.progress,
    required this.centerLabel,
    required this.bottomLabel,
    required this.color,
    this.size = 46,
  });

  @override
  Widget build(BuildContext context) {
    final innerSize = size - 4;
    final stroke = size > 48 ? 4.5 : 3.8;
    final centerFont = size > 48 ? 12.0 : 10.0;
    final bottomFont = size > 48 ? 9.0 : 8.0;

    return Semantics(
      label: '$centerLabel complete',
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: innerSize,
              height: innerSize,
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: progress.clamp(0.0, 1.0)),
                duration: AppTheme.kAnimProgress,
                curve: AppTheme.kEaseOut,
                builder: (context, animatedProgress, _) {
                  return CircularProgressIndicator(
                    value: animatedProgress,
                    strokeWidth: stroke,
                    backgroundColor: AppTheme.subtleFill(context),
                    color: color,
                  );
                },
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  centerLabel,
                  style: TextStyle(
                    color: color,
                    fontSize: centerFont,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  bottomLabel,
                  style: TextStyle(
                    color: AppTheme.textTertiary(context),
                    fontSize: bottomFont,
                    height: 1.0,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
