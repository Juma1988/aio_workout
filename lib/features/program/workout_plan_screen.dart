import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_theme.dart';
import '../../data/exercise.dart';
import '../../data/exercise_localizer.dart';
import '../../data/workout.dart';
import '../../data/workout_log.dart';
import '../../l10n/app_localizations.dart';
import '../../services/workout_storage_service.dart';
import 'workout_builder_screen.dart';

// ── Phase enum (locale-independent, replaces translated-string map keys) ──

enum ProgramPhase {
  foundation,
  building,
  peak;

  int get colorIndex {
    switch (this) {
      case ProgramPhase.foundation:
        return 0; // green
      case ProgramPhase.building:
        return 1; // orange
      case ProgramPhase.peak:
        return 2; // blue
    }
  }

  Color get color {
    const colors = [
      AppTheme.achievementGreen,
      AppTheme.stepsOrange,
      AppTheme.hydrationBlue,
    ];
    return colors[colorIndex];
  }

  String label(AppLocalizations l10n) {
    switch (this) {
      case ProgramPhase.foundation:
        return l10n.dialog_foundation;
      case ProgramPhase.building:
        return l10n.dialog_building;
      case ProgramPhase.peak:
        return l10n.dialog_peak;
    }
  }

  String fullLabel(AppLocalizations l10n) {
    switch (this) {
      case ProgramPhase.foundation:
        return l10n.dialog_foundationPhase;
      case ProgramPhase.building:
        return l10n.dialog_buildingPhase;
      case ProgramPhase.peak:
        return l10n.dialog_peakPhase;
    }
  }

  static ProgramPhase forWeek(int week) {
    if (week <= 4) return ProgramPhase.foundation;
    if (week <= 8) return ProgramPhase.building;
    return ProgramPhase.peak;
  }
}

// ── Main Screen ──

class WorkoutPlanScreen extends StatefulWidget {
  const WorkoutPlanScreen({super.key});

  @override
  State<WorkoutPlanScreen> createState() => _WorkoutPlanScreenState();
}

class _WorkoutPlanScreenState extends State<WorkoutPlanScreen> {
  ProgramProgress _progress = const ProgramProgress();
  List<WorkoutSession> _sessions = [];
  List<Workout> _customWorkouts = [];
  bool _loading = true;
  String? _error;
  int _expandedWeek = -1; // -1 = none expanded

  // Completion data: week number → count of completed workout days
  final Map<int, int> _completedPerWeek = {};

  final ScrollController _scrollController = ScrollController();
  final GlobalKey _currentWeekKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final service = WorkoutStorageService();
      final results = await Future.wait([
        service.loadProgramProgress(),
        service.loadSessions(),
        service.loadCustomWorkouts(),
      ]);
      if (!mounted) return;
      final progress = results[0] as ProgramProgress;
      final sessions = results[1] as List<WorkoutSession>;
      final customWorkouts = results[2] as List<Workout>;

      // Compute per-week completion counts
      final completed = <int, int>{};
      for (final s in sessions) {
        final existing = completed[s.weekNumber] ?? 0;
        completed[s.weekNumber] = existing + 1;
      }

      setState(() {
        _progress = progress;
        _sessions = sessions;
        _customWorkouts = customWorkouts;
        _completedPerWeek.addAll(completed);
        _expandedWeek = progress.currentWeek; // Start with current week expanded
        _loading = false;
      });

      // Scroll to current week after first frame
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToCurrentWeek();
      });
    } catch (e, s) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load workout plan: $e';
        _loading = false;
      });
      debugPrint('WorkoutPlanScreen load error: $e\n$s');
    }
  }

  void _scrollToCurrentWeek() {
    if (!_scrollController.hasClients) return;
    // Each week card is approximately 56px collapsed + 8px padding
    // Current week is at index (currentWeek - 1) in the list
    // Plus progress card (~200px) + header (~60px) + heading (~40px)
    final targetIndex = _progress.currentWeek - 1;
    final estimatedOffset = 200.0 + 60.0 + 40.0 + (targetIndex * 64.0);
    _scrollController.animateTo(
      estimatedOffset.clamp(0.0, _scrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
    );
  }

  void _openWorkoutBuilder({Workout? existing}) async {
    HapticFeedback.lightImpact();
    final result = await showModalBottomSheet<Workout>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _CustomWorkoutsBottomSheet(
        customWorkouts: _customWorkouts,
        onEdit: (w) async {
          Navigator.of(context).pop();
          final result = await Navigator.of(context).push<Workout>(
            MaterialPageRoute(builder: (_) => WorkoutBuilderScreen(initial: w)),
          );
          if (result != null && mounted) {
            final workouts = await WorkoutStorageService().loadCustomWorkouts();
            setState(() => _customWorkouts = workouts);
          }
        },
        onDelete: (w) async {
          await WorkoutStorageService().deleteCustomWorkout(w.uuid);
          final updated = await WorkoutStorageService().loadCustomWorkouts();
          if (mounted) setState(() => _customWorkouts = updated);
        },
        onCreateNew: () async {
          Navigator.of(context).pop();
          final result = await Navigator.of(context).push<Workout>(
            MaterialPageRoute(builder: (_) => const WorkoutBuilderScreen()),
          );
          if (result != null && mounted) {
            final workouts = await WorkoutStorageService().loadCustomWorkouts();
            setState(() => _customWorkouts = workouts);
          }
        },
        onCreateFromTemplate: (template) async {
          Navigator.of(context).pop();
          final result = await Navigator.of(context).push<Workout>(
            MaterialPageRoute(builder: (_) => WorkoutBuilderScreen(initial: template)),
          );
          if (result != null && mounted) {
            final workouts = await WorkoutStorageService().loadCustomWorkouts();
            setState(() => _customWorkouts = workouts);
          }
        },
      ),
    );
    if (result != null && mounted) {
      final workouts = await WorkoutStorageService().loadCustomWorkouts();
      setState(() => _customWorkouts = workouts);
    }
  }

  void _toggleWeek(int week) {
    HapticFeedback.lightImpact();
    setState(() {
      _expandedWeek = _expandedWeek == week ? -1 : week;
    });
  }

  int get _totalCompletedWorkouts => _sessions.length;

  double get _planProgress {
    // Day-level granularity: ((week-1)*7 + (day-1)) / (12*7)
    final totalDays = 12 * 7;
    final currentDay = (_progress.currentWeek - 1) * 7 + (_progress.currentDay - 1);
    return (currentDay / totalDays).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      floatingActionButton: _loading || _error != null
          ? null
          : FloatingActionButton.extended(
              onPressed: _openWorkoutBuilder,
              icon: const Icon(Icons.add, size: 20),
              label: const Text('Create Workout'),
              backgroundColor: AppTheme.achievementGreen,
              foregroundColor: Colors.white,
            ),
      body: _loading
          ? _buildSkeleton(context)
          : _error != null
              ? _buildError(context)
              : _buildContent(context),
      appBar: _loading || _error != null
          ? AppBar(
              title: Text(l10n.dialog_workoutPlanTitle),
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            )
          : null,
    );
  }

  // ── App Bar (SliverAppBar) ──

  Widget _buildAppBar(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final phase = ProgramPhase.forWeek(_progress.currentWeek);

    return SliverAppBar(
      pinned: true,
      expandedHeight: 80,
      leading: IconButton(
        icon: const Icon(Icons.close),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Text(
        '${l10n.dialog_weekDayDisplay(_progress.currentWeek, _progress.currentDay)} — ${phase.fullLabel(l10n)}',
        style: const TextStyle(fontSize: 14),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.info_outline),
          onPressed: () => _showProgramInfo(context),
          tooltip: 'Program Info',
        ),
      ],
    );
  }

  // ── Hero Section ──

  Widget _buildHero(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final phase = ProgramPhase.forWeek(_progress.currentWeek);
    final phaseColor = phase.color;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            phaseColor.withValues(alpha: isDark ? 0.20 : 0.10),
            phaseColor.withValues(alpha: isDark ? 0.05 : 0.03),
          ],
        ),
        border: Border.all(
          color: phaseColor.withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Progress ring
              SizedBox(
                width: 72,
                height: 72,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 72,
                      height: 72,
                      child: CircularProgressIndicator(
                        value: _planProgress,
                        strokeWidth: 6,
                        backgroundColor: AppTheme.subtleFill(context),
                        color: phaseColor,
                        strokeCap: StrokeCap.round,
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${(_planProgress * 100).round()}%',
                          style: TextStyle(
                            color: phaseColor,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          l10n.dialog_workoutsLabel,
                          style: TextStyle(
                            color: AppTheme.textTertiary(context),
                            fontSize: 9,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // Week/day info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.dialog_weekDayDisplay(_progress.currentWeek, _progress.currentDay),
                      style: TextStyle(
                        color: AppTheme.textPrimary(context),
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: phaseColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        phase.fullLabel(l10n),
                        style: TextStyle(
                          color: phaseColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Total workouts
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$_totalCompletedWorkouts',
                    style: TextStyle(
                      color: AppTheme.textPrimary(context),
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    l10n.dialog_workoutsLabel,
                    style: TextStyle(
                      color: AppTheme.textTertiary(context),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Linear progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: _planProgress,
              minHeight: 6,
              backgroundColor: AppTheme.subtleFill(context),
              color: phaseColor,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.dialog_weekLabel(1),
                style: TextStyle(color: AppTheme.textTertiary(context), fontSize: 10),
              ),
              Text(
                l10n.dialog_weekLabel(12),
                style: TextStyle(color: AppTheme.textTertiary(context), fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Content ──

  Widget _buildContent(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        _buildAppBar(context),
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHero(context),
              // Section heading
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  l10n.dialog_12WeekProgram,
                  style: TextStyle(
                    color: AppTheme.textPrimary(context),
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
        // Phase dividers + week cards
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              // Insert phase dividers
              if (index == 0) return _buildPhaseDivider(context, ProgramPhase.foundation, 1, 4);
              if (index == 5) return _buildPhaseDivider(context, ProgramPhase.building, 5, 8);
              if (index == 10) return _buildPhaseDivider(context, ProgramPhase.peak, 9, 12);

              // Map index to week number (accounting for 3 dividers)
              int week;
              if (index < 5) {
                week = index; // 1-4
              } else if (index < 10) {
                week = index - 1; // 5-8
              } else {
                week = index - 2; // 9-12
              }

              return _WeekCard(
                key: week == _progress.currentWeek ? _currentWeekKey : null,
                week: week,
                isCurrentWeek: week == _progress.currentWeek,
                isExpanded: _expandedWeek == week,
                completedCount: _completedPerWeek[week] ?? 0,
                currentWeek: _progress.currentWeek,
                currentDay: _progress.currentDay,
                onTap: () => _toggleWeek(week),
                onDayTap: (day) => _showDayDetail(context, week, day),
              );
            },
            childCount: 15, // 12 weeks + 3 phase dividers
          ),
        ),
        const SliverPadding(padding: EdgeInsets.only(bottom: 40)),
      ],
    );
  }

  // ── Phase Divider ──

  Widget _buildPhaseDivider(BuildContext context, ProgramPhase phase, int fromWeek, int toWeek) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 16,
            decoration: BoxDecoration(
              color: phase.color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${phase.fullLabel(l10n)}  •  ${l10n.dialog_weekLabel(fromWeek)} – ${l10n.dialog_weekLabel(toWeek)}',
            style: TextStyle(
              color: AppTheme.textTertiary(context),
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  // ── Day Detail Bottom Sheet ──

  void _showDayDetail(BuildContext context, int week, int day) {
    final l10n = AppLocalizations.of(context);
    final rest = isRestDay(day);
    final focus = getFocusForDay(week, day);
    final defaultExercises = rest ? <Exercise>[] : _getDefaultExercises();
    final phase = ProgramPhase.forWeek(week);

    // Find custom workouts matching this focus
    final matchingWorkouts = _customWorkouts.where((w) => w.focus == focus).toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.85,
        expand: false,
        builder: (ctx, scrollController) => Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.subtleFill(context),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: phase.color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        'D$day',
                        style: TextStyle(
                          color: phase.color,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ExerciseLocalizer.focusName(l10n, focus),
                          style: TextStyle(
                            color: AppTheme.textPrimary(context),
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          '${l10n.dialog_weekLabel(week)} • ${rest ? "Rest Day" : "${defaultExercises.length} exercises"}',
                          style: TextStyle(
                            color: AppTheme.textTertiary(context),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Create workout button
                  if (!rest)
                    IconButton(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        _openWorkoutBuilder();
                      },
                      icon: const Icon(Icons.add_circle_outline, size: 22),
                      tooltip: 'Create custom workout',
                      color: AppTheme.achievementGreen,
                    ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Content
            Expanded(
              child: rest
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.nightlight_round, size: 48, color: AppTheme.textDisabled(context)),
                          const SizedBox(height: 8),
                          Text(
                            ExerciseLocalizer.focusName(l10n, 'Rest Day'),
                            style: TextStyle(
                              color: AppTheme.textTertiary(context),
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Recovery is progress!',
                            style: TextStyle(
                              color: AppTheme.textDisabled(context),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      children: [
                        // Custom workouts section
                        if (matchingWorkouts.isNotEmpty) ...[
                          _sectionHeader(context, 'Custom Workouts', AppTheme.achievementGreen),
                          const SizedBox(height: 8),
                          ...matchingWorkouts.map((w) => _customWorkoutCard(context, w, phase)),
                          const SizedBox(height: 16),
                        ],
                        // Default exercises section
                        _sectionHeader(context, 'Default Exercises', phase.color),
                        const SizedBox(height: 8),
                        ...defaultExercises.map((ex) => _exerciseCard(context, ex, phase)),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(BuildContext context, String title, Color color) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 14,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            color: AppTheme.textSecondary(context),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _customWorkoutCard(BuildContext context, Workout workout, ProgramPhase phase) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.achievementGreen.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.achievementGreen.withValues(alpha: 0.2), width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppTheme.achievementGreen.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.star, size: 18, color: AppTheme.achievementGreen),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  workout.name,
                  style: TextStyle(
                    color: AppTheme.textPrimary(context),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${workout.exercises.length} exercises • ${workout.level}',
                  style: TextStyle(
                    color: AppTheme.textTertiary(context),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppTheme.achievementGreen.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Text(
              'Custom',
              style: TextStyle(
                color: AppTheme.achievementGreen,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _exerciseCard(BuildContext context, Exercise ex, ProgramPhase phase) {
    final display = ex.getRecommendedDisplay();
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.cardColor(context),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: phase.color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              exerciseCategoryIcons[ex.categoryKey] ?? Icons.fitness_center,
              size: 18,
              color: phase.color,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ExerciseLocalizer.exerciseName(AppLocalizations.of(context), ex.uuid),
                  style: TextStyle(
                    color: AppTheme.textPrimary(context),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (display.isNotEmpty)
                  Text(
                    display,
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
    );
  }

  List<Exercise> _getDefaultExercises() {
    return [highKneeMarch, plank, deadBug, gluteBridge, birdDog, sideLyingLegRaise];
  }

  // ── Error State ──

  Widget _buildError(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
            const SizedBox(height: 16),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textSecondary(context), fontSize: 14),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _load,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  // ── Skeleton Loading ──

  Widget _buildSkeleton(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Workout Plan'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Hero skeleton
          _skeletonBox(context, height: 180, borderRadius: 20),
          const SizedBox(height: 20),
          _skeletonBox(context, height: 24, width: 160, borderRadius: 6),
          const SizedBox(height: 12),
          // Week card skeletons
          ...List.generate(5, (i) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _skeletonBox(context, height: 56, borderRadius: 12),
          )),
        ],
      ),
    );
  }

  Widget _skeletonBox(BuildContext context, {double? height, double? width, double borderRadius = 8}) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: AppTheme.subtleFill(context, 0.06),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }

  // ── Program Info Dialog ──

  void _showProgramInfo(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(l10n.dialog_12WeekProgram),
        content: const Text(
          'This 12-week program is divided into three phases:\n\n'
          '• Foundation (Weeks 1–4): Build core strength and establish habits\n'
          '• Building (Weeks 5–8): Increase intensity and endurance\n'
          '• Peak (Weeks 9–12): Push your limits with advanced training\n\n'
          'Each week has 5 training days and 2 rest days.',
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}

// ── Week Card (Collapsible Accordion) ──

class _WeekCard extends StatelessWidget {
  final int week;
  final bool isCurrentWeek;
  final bool isExpanded;
  final int completedCount;
  final int currentWeek;
  final int currentDay;
  final VoidCallback onTap;
  final void Function(int day) onDayTap;

  const _WeekCard({
    super.key,
    required this.week,
    required this.isCurrentWeek,
    required this.isExpanded,
    required this.completedCount,
    required this.currentWeek,
    required this.currentDay,
    required this.onTap,
    required this.onDayTap,
  });

  static const int _totalTrainingDays = 5; // days 1,2,3,5,6

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final phase = ProgramPhase.forWeek(week);
    final color = phase.color;
    final isPast = week < currentWeek ||
        (week == currentWeek && !isCurrentWeek);
    final isFuture = week > currentWeek;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isExpanded
                  ? color.withValues(alpha: 0.5)
                  : isCurrentWeek
                      ? color.withValues(alpha: 0.25)
                      : AppTheme.subtleFill(context, 0.08),
              width: isExpanded ? 1.5 : 1,
            ),
            color: AppTheme.cardColor(context),
          ),
          child: Column(
            children: [
              // ── Collapsed Header ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  children: [
                    // Week badge
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: isExpanded
                            ? color.withValues(alpha: 0.15)
                            : isCurrentWeek
                                ? color.withValues(alpha: 0.10)
                                : AppTheme.subtleFill(context, 0.06),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(
                          'W$week',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isExpanded || isCurrentWeek
                                ? color
                                : AppTheme.textSecondary(context),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Week label
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.dialog_weekLabel(week),
                            style: TextStyle(
                              color: isPast
                                  ? AppTheme.textTertiary(context)
                                  : AppTheme.textPrimary(context),
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          if (!isExpanded)
                            Text(
                              isPast
                                  ? '$completedCount/$_totalTrainingDays ${l10n.dialog_workoutsLabel}'
                                  : isFuture
                                      ? 'Upcoming'
                                      : _getDaySummary(l10n),
                              style: TextStyle(
                                color: AppTheme.textTertiary(context),
                                fontSize: 11,
                              ),
                            ),
                        ],
                      ),
                    ),
                    // Current pill
                    if (isCurrentWeek) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          l10n.dialog_current,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: color,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                    // Phase pill
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.subtleFill(context, 0.06),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        phase.label(l10n),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textTertiary(context),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    // Expand/collapse chevron
                    AnimatedRotation(
                      turns: isExpanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 250),
                      child: Icon(
                        Icons.keyboard_arrow_down,
                        size: 20,
                        color: AppTheme.textTertiary(context),
                      ),
                    ),
                  ],
                ),
              ),
              // ── Expandable Day List ──
              AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                child: isExpanded
                    ? Column(
                        children: [
                          Divider(height: 1, color: AppTheme.subtleFill(context, 0.08)),
                          ...List.generate(7, (i) {
                            final day = i + 1;
                            return _DayRow(
                              week: week,
                              day: day,
                              isCurrentDay: isCurrentWeek && day == currentDay,
                              isPast: isPast || (isCurrentWeek && day < currentDay),
                              phaseColor: color,
                              onTap: () => onDayTap(day),
                            );
                          }),
                        ],
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getDaySummary(AppLocalizations l10n) {
    // Show what today's focus is if current week
    return '';
  }
}

// ── Day Row ──

class _DayRow extends StatelessWidget {
  final int week;
  final int day;
  final bool isCurrentDay;
  final bool isPast;
  final Color phaseColor;
  final VoidCallback onTap;

  const _DayRow({
    required this.week,
    required this.day,
    required this.isCurrentDay,
    required this.isPast,
    required this.phaseColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final rest = isRestDay(day);
    final focus = getFocusForDay(week, day);
    final completed = isPast && !rest;
    final exercises = rest ? <Exercise>[] : _getDefaultExercises();

    return Semantics(
      label: 'Week $week, Day $day: ${ExerciseLocalizer.focusName(l10n, focus)}${rest ? " (Rest Day)" : ""}',
      button: true,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: isCurrentDay
              ? BoxDecoration(
                  color: phaseColor.withValues(alpha: 0.06),
                  border: Border(
                    left: BorderSide(color: phaseColor, width: 3),
                  ),
                )
              : null,
          child: Row(
            children: [
              // Day badge
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: completed
                      ? AppTheme.achievementGreen.withValues(alpha: 0.15)
                      : rest
                          ? AppTheme.subtleFill(context, 0.04)
                          : isCurrentDay
                              ? phaseColor.withValues(alpha: 0.12)
                              : AppTheme.subtleFill(context, 0.08),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: completed
                    ? const Icon(Icons.check, size: 14, color: AppTheme.achievementGreen)
                    : Text(
                        'D$day',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: rest
                              ? AppTheme.textDisabled(context)
                              : isCurrentDay
                                  ? phaseColor
                                  : AppTheme.textSecondary(context),
                        ),
                      ),
              ),
              const SizedBox(width: 10),
              // Focus name
              Expanded(
                child: Text(
                  ExerciseLocalizer.focusName(l10n, focus),
                  style: TextStyle(
                    fontSize: 13,
                    color: rest
                        ? AppTheme.textDisabled(context)
                        : AppTheme.textPrimary(context),
                    fontStyle: rest ? FontStyle.italic : FontStyle.normal,
                    fontWeight: isCurrentDay ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
              // Exercise count or rest icon
              if (rest)
                Icon(Icons.nightlight_round, size: 14, color: AppTheme.textDisabled(context))
              else
                Text(
                  '${exercises.length}',
                  style: TextStyle(
                    color: AppTheme.textTertiary(context),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              const SizedBox(width: 4),
              Icon(
                Icons.chevron_right,
                size: 16,
                color: AppTheme.textDisabled(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Exercise> _getDefaultExercises() {
    return [highKneeMarch, plank, deadBug, gluteBridge, birdDog, sideLyingLegRaise];
  }
}

// ── Custom Workouts Bottom Sheet (Cyber-Green Anime-Tech Vibe) ──

class _CustomWorkoutsBottomSheet extends StatefulWidget {
  final List<Workout> customWorkouts;
  final void Function(Workout) onEdit;
  final void Function(Workout) onDelete;
  final VoidCallback onCreateNew;
  final void Function(Workout) onCreateFromTemplate;

  const _CustomWorkoutsBottomSheet({
    required this.customWorkouts,
    required this.onEdit,
    required this.onDelete,
    required this.onCreateNew,
    required this.onCreateFromTemplate,
  });

  @override
  State<_CustomWorkoutsBottomSheet> createState() => _CustomWorkoutsBottomSheetState();
}

class _CustomWorkoutsBottomSheetState extends State<_CustomWorkoutsBottomSheet> {
  static const _accent = Color(0xFF00E676);
  static const _bg = Color(0xFF0D1117);
  static const _cardBg = Color(0xFF161B22);
  static const _cardBorder = Color(0xFF21262D);

  // ── Sample templates ──
  static final _templates = [
    _TemplatePlan(
      name: 'Core Foundation',
      focus: 'core',
      level: 'beginner',
      exercises: ['ex-plank-001', 'ex-deadbug-001', 'ex-birddog-001', 'ex-cocoons-001'],
      tag: 'FOUNDATION',
      color: Color(0xFF2196F3),
    ),
    _TemplatePlan(
      name: 'Upper Blast',
      focus: 'upperbody',
      level: 'intermediate',
      exercises: ['ex-pushups-001', 'ex-overheadpress-001', 'ex-bicepcurls-001'],
      tag: 'BUILDING',
      color: Color(0xFFFF9800),
    ),
    _TemplatePlan(
      name: 'Leg Day Power',
      focus: 'lowerbody',
      level: 'intermediate',
      exercises: ['ex-squats-001', 'ex-glutebridge-001', 'ex-sidelyinglegraise-001'],
      tag: 'BUILDING',
      color: Color(0xFF00BCD4),
    ),
    _TemplatePlan(
      name: 'Cardio Burn',
      focus: 'cardio',
      level: 'beginner',
      exercises: ['ex-jumpingjacks-001', 'ex-highkneemarch-001'],
      tag: 'CARDIO',
      color: Color(0xFFE91E63),
    ),
    _TemplatePlan(
      name: 'Full Body Shred',
      focus: 'fullbody',
      level: 'advanced',
      exercises: ['ex-pushups-001', 'ex-squats-001', 'ex-plank-001', 'ex-overheadpress-001', 'ex-glutebridge-001'],
      tag: 'PEAK',
      color: Color(0xFFF44336),
    ),
    _TemplatePlan(
      name: 'Strength Base',
      focus: 'strength',
      level: 'beginner',
      exercises: ['ex-pushups-001', 'ex-squats-001', 'ex-bicepcurls-001'],
      tag: 'FOUNDATION',
      color: Color(0xFFFF5722),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dateStr = '${now.day}/${now.month}/${now.year}';

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // ── Drag Handle ──
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: _accent.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // ── Hero Card ──
          _buildHeroCard(context, dateStr),

          // ── Section Title ──
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Row(
              children: [
                Container(
                  width: 3,
                  height: 14,
                  decoration: BoxDecoration(
                    color: _accent,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'CUSTOM WORKOUTS',
                  style: TextStyle(
                    color: _accent,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                  ),
                ),
                const Spacer(),
                if (widget.customWorkouts.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '${widget.customWorkouts.length}',
                      style: TextStyle(color: _accent, fontSize: 11, fontWeight: FontWeight.w700),
                    ),
                  ),
              ],
            ),
          ),

          // ── Workout Grid ──
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                // Custom workouts grid
                if (widget.customWorkouts.isNotEmpty) ...[
                  _buildWorkoutGrid(context, widget.customWorkouts, isCustom: true),
                  const SizedBox(height: 20),
                ],

                // ── Sample Plans Section ──
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Container(
                        width: 3,
                        height: 14,
                        decoration: BoxDecoration(
                          color: _accent.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'STARTER PLANS',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildWorkoutGrid(context, [], isCustom: false),

                const SizedBox(height: 20),

                // ── Create From Scratch Button ──
                _buildCreateFromScratchCard(context),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroCard(BuildContext context, String dateStr) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _accent.withValues(alpha: 0.15),
            _accent.withValues(alpha: 0.05),
          ],
        ),
        border: Border.all(
          color: _accent.withValues(alpha: 0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: _accent.withValues(alpha: 0.1),
            blurRadius: 20,
            spreadRadius: -5,
          ),
        ],
      ),
      child: Row(
        children: [
          // Glow circle
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _accent.withValues(alpha: 0.15),
              boxShadow: [
                BoxShadow(
                  color: _accent.withValues(alpha: 0.3),
                  blurRadius: 16,
                  spreadRadius: -2,
                ),
              ],
            ),
            child: Icon(Icons.bolt, size: 28, color: _accent),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'My Custom Plan',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$dateStr  •  ${widget.customWorkouts.length} plans',
                  style: TextStyle(
                    color: _accent.withValues(alpha: 0.7),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          // Workout count badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: _accent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${widget.customWorkouts.length}',
              style: TextStyle(
                color: _accent,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkoutGrid(BuildContext context, List<Workout> workouts, {required bool isCustom}) {
    if (isCustom && workouts.isEmpty) return const SizedBox.shrink();

    final items = isCustom
        ? workouts
        : _templates;

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: items.map((item) {
        if (isCustom) {
          final w = item as Workout;
          return _buildExistingWorkoutCard(context, w);
        } else {
          final t = item as _TemplatePlan;
          return _buildTemplateCard(context, t);
        }
      }).toList(),
    );
  }

  Widget _buildExistingWorkoutCard(BuildContext context, Workout workout) {
    final cat = exerciseCategories[workout.focus];
    final color = cat?.color ?? _accent;

    return GestureDetector(
      onTap: () => widget.onEdit(workout),
      onLongPress: () => _showDeleteDialog(context, workout),
      child: Container(
        width: (MediaQuery.of(context).size.width - 42) / 2,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _accent.withValues(alpha: 0.3), width: 1),
          boxShadow: [
            BoxShadow(
              color: _accent.withValues(alpha: 0.08),
              blurRadius: 12,
              spreadRadius: -3,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: icon + edit
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: _accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.bolt, size: 18, color: _accent),
                ),
                const Spacer(),
                Icon(Icons.edit_outlined, size: 16, color: Colors.white.withValues(alpha: 0.3)),
              ],
            ),
            const SizedBox(height: 12),
            // Name
            Text(
              workout.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            // Tags
            Row(
              children: [
                _tag('${workout.exercises.length} ex', _accent),
                const SizedBox(width: 6),
                _tag(workout.level, color),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTemplateCard(BuildContext context, _TemplatePlan template) {
    return GestureDetector(
      onTap: () {
        // Convert template to Workout and open builder
        final workout = Workout(
          uuid: 'template-${template.name.toLowerCase().replaceAll(' ', '-')}',
          name: template.name,
          isDefault: false,
          focus: template.focus,
          level: template.level,
          exercises: template.exercises.map((id) => ExerciseRef(exerciseId: id)).toList(),
          estimatedDurationMinutes: template.exercises.length * 5,
          createdAt: DateTime.now(),
        );
        widget.onCreateFromTemplate(workout);
      },
      child: Container(
        width: (MediaQuery.of(context).size.width - 42) / 2,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _cardBorder, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: big + button
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: template.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.add, size: 20, color: template.color),
                ),
                const Spacer(),
                Icon(Icons.arrow_forward_ios, size: 12, color: Colors.white.withValues(alpha: 0.2)),
              ],
            ),
            const SizedBox(height: 12),
            // Name
            Text(
              template.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            // Tags
            Row(
              children: [
                _tag('${template.exercises.length} ex', template.color),
                const SizedBox(width: 6),
                _tag(template.tag, template.color),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCreateFromScratchCard(BuildContext context) {
    return GestureDetector(
      onTap: widget.onCreateNew,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _accent.withValues(alpha: 0.2),
            width: 1,
            strokeAlign: BorderSide.strokeAlignInside,
          ),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              _accent.withValues(alpha: 0.06),
              Colors.transparent,
            ],
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(Icons.add_circle_outline, size: 24, color: _accent),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Create From Scratch',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Build your own custom workout routine',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.4),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 14, color: _accent.withValues(alpha: 0.5)),
          ],
        ),
      ),
    );
  }

  Widget _tag(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, Workout workout) {
    HapticFeedback.mediumImpact();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Delete "${workout.name}"?',
          style: const TextStyle(color: Colors.white),
        ),
        content: Text(
          'This will permanently remove this custom workout.',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cancel', style: TextStyle(color: Colors.white.withValues(alpha: 0.5))),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              widget.onDelete(workout);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }
}

class _TemplatePlan {
  final String name;
  final String focus;
  final String level;
  final List<String> exercises;
  final String tag;
  final Color color;

  const _TemplatePlan({
    required this.name,
    required this.focus,
    required this.level,
    required this.exercises,
    required this.tag,
    required this.color,
  });
}
