import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/clock.dart';
import '../../core/theme/app_theme.dart';
import '../../data/weight_entry.dart';
import '../../data/workout_log.dart';
import '../../l10n/app_localizations.dart';
import '../../services/workout_storage_service.dart' show WorkoutStorageService, dateKey;
import '../../services/hydration_storage.dart';
import '../../services/step_counter_service.dart';
import '../../services/step_history_storage.dart';
import '../achievements/providers/achievement_provider.dart';
import '../achievements/widgets/achievement_celebration.dart';
import '../home/home_screen.dart';
import '../history/history_screen.dart';
import '../profile/home_settings_dialog.dart';
import '../profile/profile_screen.dart';
import '../notifications/services/notification_service.dart';

class MainShell extends StatefulWidget {
  final VoidCallback? onThemeToggle;

  const MainShell({super.key, this.onThemeToggle});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> with WidgetsBindingObserver {
  int _selectedIndex = 0;
  int _previousIndex = 0;

  double _hydrationLiters = 0.0;
  int _steps = 0;
  Set<String> _completedExerciseUuids = {};

  ProgramProgress _progress = const ProgramProgress();
  final _storageService = WorkoutStorageService();
  final _stepStorage = StepHistoryStorage();
  final _stepService = StepCounterService();
  late List<Widget> _screens;
  int _historyRefreshCounter = 0;
  List<WeightEntry> _weightEntries = [];
  double? _weightGoalKg;
  int _restTimerSeconds = 30;
  List<WorkoutSession> _recentSessions = [];

  bool _todayCompleted = false;
  int _stepsGoal = 10000;
  double _hydrationGoal = 2.5;
  bool _useSensor = true;
  StreamSubscription<int>? _stepSubscription;

  // Home per-click increments
  int _stepsPerClick = 200;
  int _hydrationMLPerClick = 250;

  // Home section visibility
  bool _showSteps = true;
  bool _showAchievements = true;
  bool _showHydration = true;
  bool _showWeightTrend = true;
  bool _showThisWeek = true;

  Timer? _dayCheckTimer;
  String _lastDateKey = '';

  /// Advances program progress for each calendar day that has passed since
  /// [lastAdvanceDate]. Called on midnight rollover and app cold-start.
  ///
  /// Before advancing, saves any partial workout progress from the previous
  /// day as a session so the user's effort appears in History.
  Future<void> _onNewDay(String today) async {
    _lastDateKey = today;

    // Save any partial workout from yesterday before advancing.
    await _savePartialWorkoutIfNeeded();

    final progress = await _storageService.loadProgramProgress();

    int daysToAdvance;
    if (progress.lastAdvanceDate == null) {
      // First launch or migration — just mark today as the baseline.
      daysToAdvance = 0;
    } else {
      final lastDate = DateTime.parse(progress.lastAdvanceDate!);
      final todayDate = DateTime.parse(today);
      daysToAdvance = todayDate.difference(lastDate).inDays;
    }
    daysToAdvance = daysToAdvance.clamp(0, 84); // Cap at 12 weeks

    if (daysToAdvance > 0) {
      ProgramProgress advanced = progress;
      for (int i = 0; i < daysToAdvance; i++) {
        advanced = advanced.advance();
      }
      final updated = ProgramProgress(
        currentWeek: advanced.currentWeek,
        currentDay: advanced.currentDay,
        lastAdvanceDate: today,
      );
      await _storageService.saveProgramProgress(updated);
    } else if (progress.lastAdvanceDate == null) {
      // First launch — set baseline date without advancing.
      final updated = ProgramProgress(
        currentWeek: progress.currentWeek,
        currentDay: progress.currentDay,
        lastAdvanceDate: today,
      );
      await _storageService.saveProgramProgress(updated);
    }

    // Force History to reload — yesterday's workout is now visible.
    _historyRefreshCounter++;
    await _loadAll();
  }

  /// Saves any partially-completed workout as a session so it appears in
  /// History. Called at midnight before the day advances.
  ///
  /// Falls back to raw SharedPreferences UUIDs on cold start, where the
  /// in-memory set is empty because loadTodayCompletedUuids() returns {}
  /// when the saved date doesn't match today.
  Future<void> _savePartialWorkoutIfNeeded() async {
    // Try in-memory set first (works when app was running at midnight).
    Set<String> uuids = _completedExerciseUuids;

    // On cold start the in-memory set is empty because loadTodayCompletedUuids()
    // returned {} (date mismatch).  Try the raw stored UUIDs as fallback.
    if (uuids.isEmpty) {
      uuids = await _storageService.loadRawCompletedUuids();
    }

    if (uuids.isEmpty) return;

    final exercises = getTodayExercises(_progress.currentDay);
    final completedExercises = exercises
        .where((e) => uuids.contains(e.uuid))
        .map((e) {
      final lvl = e.getLevel(e.recommendedLevel);
      return CompletedExercise(
        exerciseUuid: e.uuid,
        exerciseName: e.name,
        setsCompleted: lvl?.sets ?? 1,
        repsCompleted: lvl?.reps,
        durationSeconds: lvl?.durationSeconds,
      );
    }).toList();

    if (completedExercises.isEmpty) return;

    // Date the session as yesterday so it doesn't count as today's completed
    // workout (which would hide the new day's exercise list).
    final sessionDate = DateTime.now().subtract(const Duration(days: 1));
    final focus = getFocusForDay(
        _progress.currentWeek, _progress.currentDay);

    final session = WorkoutSession(
      uuid: 'ws-partial-${DateTime.now().millisecondsSinceEpoch}',
      date: sessionDate,
      weekNumber: _progress.currentWeek,
      dayNumber: _progress.currentDay,
      focus: focus,
      durationSeconds: 0,
      exercises: completedExercises,
      plannedExerciseUuids: exercises.map((e) => e.uuid).toList(),
      steps: _steps,
      hydrationLiters: _hydrationLiters,
      achievementsUnlocked: [],
    );

    await _storageService.addSession(session);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _rebuildScreens();
    _initStepCounter();
    _loadAll().then((_) {
      _lastDateKey = dateKey(DateTime.now());
      // On cold start, catch up on any missed day advances.
      _advanceDayIfNeeded();
    });
    _dayCheckTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      final today = dateKey(DateTime.now());
      if (today != _lastDateKey) {
        _onNewDay(today);
      }
    });
  }

  /// Checks whether program progress is behind the current calendar day
  /// and advances it if necessary.  Called once on cold start.
  Future<void> _advanceDayIfNeeded() async {
    final today = dateKey(DateTime.now());
    final progress = await _storageService.loadProgramProgress();
    if (progress.lastAdvanceDate != null && progress.lastAdvanceDate != today) {
      await _onNewDay(today);
    } else if (progress.lastAdvanceDate == null) {
      // First launch — set baseline date.
      await _onNewDay(today);
    }
  }

  Future<void> _initStepCounter() async {
    await _stepService.initialize();
    _stepSubscription = _stepService.stepStream.listen((steps) {
      if (mounted) {
        setState(() => _steps = steps);
      }
    });
    if (_useSensor) {
      await _requestActivityRecognition();
    }
  }

  /// Shows a rationale dialog before requesting ACTIVITY_RECOGNITION permission.
  Future<void> _requestActivityRecognition() async {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context);
    final proceed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Icon(Icons.directions_run,
                color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 10),
            Text(l10n.home_steps),
          ],
        ),
        content: const Text(
          'We use your device\'s motion sensor to track your daily steps. '
          'This helps you monitor your activity and earn step-based achievements.\n\n'
          'No location data is collected. Step data stays on this device.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.profile_resetCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Allow'),
          ),
        ],
      ),
    );
    if (proceed == true && mounted) {
      await _stepService.startListening();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _dayCheckTimer?.cancel();
    _stepSubscription?.cancel();
    _stepService.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      final today = dateKey(DateTime.now());
      if (today != _lastDateKey) {
        _onNewDay(today);
      } else {
        _loadAll();
      }
      if (_useSensor && !_stepService.isRunning) {
        _stepService.startListening();
      }
    } else if (state == AppLifecycleState.paused) {
      _stepService.stopListening();
    }
  }

  void _rebuildScreens() {
    _screens = [
      HomeScreen(
        onThemeToggle: widget.onThemeToggle,
        hydrationLiters: _hydrationLiters,
        steps: _steps,
        stepsPerClick: _stepsPerClick,
        hydrationMLPerClick: _hydrationMLPerClick,
        completedExerciseUuids: _completedExerciseUuids,
        currentWeek: _progress.currentWeek,
        currentDay: _progress.currentDay,
        onHydrationChanged: _onHydrationChanged,
        onStepsChanged: _onStepsChanged,
        onExerciseCompleted: _onExerciseCompleted,
        onExerciseToggled: _onExerciseToggled,
        onWorkoutComplete: _onWorkoutComplete,
        weightEntries: _weightEntries,
        weightGoalKg: _weightGoalKg,
        onWeightLogged: _onWeightLogged,
        clock: const SystemClock(),
        onRefresh: _loadAll,
        restTimerSeconds: _restTimerSeconds,
        recentSessions: _recentSessions,
        showSteps: _showSteps,
        showAchievements: _showAchievements,
        showHydration: _showHydration,
        showWeightTrend: _showWeightTrend,
        showThisWeek: _showThisWeek,
        isTodayCompleted: _todayCompleted,
        stepsGoal: _stepsGoal,
        hydrationGoal: _hydrationGoal,
        useSensor: _useSensor,
      ),
      HistoryScreen(
        key: ValueKey('$_historyRefreshCounter-${_progress.currentWeek}'),
        onRefresh: _loadAll,
      ),
      ProfileScreen(
        onHomeSettingsChanged: _onHomeSettingsChanged,
        onResetSteps: _onResetSteps,
        onResetHydration: _onResetHydration,
        onResetWorkout: _onResetWorkout,
      ),
    ];
  }

  Future<void> _loadAll() async {
    final progress = await _storageService.loadProgramProgress();
    final steps = await _stepStorage.loadTodaySteps();
    final hydration = await HydrationStorage().loadTodayHydration();
    final uuids = await _storageService.loadTodayCompletedUuids();
    final weightEntries = await _storageService.loadWeightEntries();
    final weightGoal = await _storageService.loadWeightGoal();
    final prefs = await SharedPreferences.getInstance();
    final restTimerSeconds = prefs.getInt('rest_timer_seconds') ?? 30;
    final sessions = await _storageService.loadSessions();
    final todayStr = dateKey(DateTime.now());
    final completedToday = sessions.any((s) => dateKey(s.date) == todayStr);
    final stepsGoal = await _stepStorage.loadDailyGoal();
    final useSensor = await _stepStorage.loadUseSensor();
    final hydrationGoal = await loadHydrationTarget();
    if (mounted) {
      setState(() {
        _progress = progress;
        _todayCompleted = completedToday;
        _steps = steps;
        _hydrationLiters = hydration;
        _completedExerciseUuids = uuids;
        _weightEntries = weightEntries;
        _weightGoalKg = weightGoal;
        _restTimerSeconds = restTimerSeconds;
        _recentSessions = sessions;
        _stepsGoal = stepsGoal;
        _useSensor = useSensor;
        _hydrationGoal = hydrationGoal;
      });
    }
    await _checkMissedWorkoutReminder(progress);
    await _loadHomeSettings();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Initialize provider after first frame (called once via post-frame)
    if (!_providerInitialized) {
      _providerInitialized = true;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final provider = context.read<AchievementProvider>();
        if (!provider.isInitialized) {
          await provider.initialize();
        }
        await provider.evaluateAll();
      });
    }
  }

  bool _providerInitialized = false;

  Future<void> _checkMissedWorkoutReminder(ProgramProgress progress) async {
    if (isRestDay(progress.currentDay)) return;
    final sessions = await _storageService.loadSessions();
    final todayStr = dateKey(DateTime.now());
    final hasTodaySession = sessions.any(
      (s) => dateKey(s.date) == todayStr,
    );
    if (!hasTodaySession) {
      final notifService = NotificationService();
      if (mounted) {
        notifService.setLocalizations(AppLocalizations.of(context));
      }
      await notifService.scheduleMissedWorkoutReminder();
    }
  }

  void _persistToday() {
    _storageService.saveTodayState(
      steps: _steps,
      hydration: _hydrationLiters,
      completedUuids: _completedExerciseUuids,
    );
    _stepStorage.saveTodaySteps(_steps);
  }

  void _onHydrationChanged(double v) {
    setState(() => _hydrationLiters = v);
    _storageService.saveTodayState(
      steps: _steps,
      hydration: v,
      completedUuids: _completedExerciseUuids,
    );
  }

  void _onStepsChanged(int v) {
    setState(() => _steps = v);
    _stepStorage.saveTodaySteps(v);
    _storageService.saveTodayState(
      steps: v,
      hydration: _hydrationLiters,
      completedUuids: _completedExerciseUuids,
    );
  }

  Future<void> _loadHomeSettings() async {
    final results = await Future.wait([
      loadHomeSectionVisibility(),
      loadStepsPerClick(),
      loadHydrationMLPerClick(),
    ]);
    final visibility = results[0] as Map<HomeSection, bool>;
    setState(() {
      _showSteps = visibility[HomeSection.steps] ?? true;
      _showAchievements = visibility[HomeSection.achievements] ?? true;
      _showHydration = visibility[HomeSection.hydration] ?? true;
      _showWeightTrend = visibility[HomeSection.weightTrend] ?? true;
      _showThisWeek = visibility[HomeSection.thisWeek] ?? true;
      _stepsPerClick = results[1] as int;
      _hydrationMLPerClick = results[2] as int;
    });
  }

  void _onHomeSettingsChanged() {
    _loadHomeSettings();
    _reloadHydrationGoal();
  }

  Future<void> _reloadHydrationGoal() async {
    final hydrationGoal = await loadHydrationTarget();
    if (mounted) {
      setState(() => _hydrationGoal = hydrationGoal);
    }
  }

  Future<void> _onResetSteps() async {
    await _stepStorage.saveTodaySteps(0);
    _loadAll();
  }

  Future<void> _onResetHydration() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('today_date', dateKey(DateTime.now()));
    await prefs.setDouble('today_hydration', 0.0);
    // Also clear all hydration entries for today
    final today = dateKey(DateTime.now());
    final allEntries = await HydrationStorage().loadAllEntries();
    allEntries.removeWhere((e) => e.date == today);
    await HydrationStorage().saveAllEntries(allEntries);
    _loadAll();
  }

  Future<void> _onResetWorkout() async {
    final prefs = await SharedPreferences.getInstance();
    final todayStr = dateKey(DateTime.now());
    await prefs.setString('today_date', todayStr);
    await prefs.setStringList('today_completed_uuids', []);
    // Also remove today's session so the "Workout Complete!" banner disappears
    final sessions = await _storageService.loadSessions();
    sessions.removeWhere((s) => dateKey(s.date) == todayStr);
    await _storageService.saveSessions(sessions);
    _loadAll();
  }

  Future<void> _onWeightLogged(WeightEntry entry) async {
    setState(() {
      final key = dateKey(entry.date);
      final idx = _weightEntries.indexWhere(
        (e) => dateKey(e.date) == key,
      );
      if (idx >= 0) {
        _weightEntries[idx] = entry;
      } else {
        _weightEntries.add(entry);
      }
    });
    await _storageService.addWeightEntry(entry);
  }

  void _onExerciseCompleted(String uuid) {
    if (_completedExerciseUuids.contains(uuid)) return; // no duplicates
    setState(() => _completedExerciseUuids.add(uuid));
    _persistToday();
  }

  void _onExerciseToggled(String uuid) {
    setState(() {
      if (_completedExerciseUuids.contains(uuid)) {
        _completedExerciseUuids.remove(uuid);
      } else {
        _completedExerciseUuids.add(uuid);
      }
    });
    _persistToday();
  }

  Future<void> _onWorkoutComplete(
      int durationSeconds, DateTime startTime) async {
    // Check if day changed mid-workout (e.g. workout started before midnight)
    final today = dateKey(DateTime.now());
    if (today != _lastDateKey) {
      await _onNewDay(today);
    }

    if (!mounted) return;
    final now = DateTime.now();
    final focus = getLocalizedFocus(
        AppLocalizations.of(context), _progress.currentWeek, _progress.currentDay);

    final currentExercises = getTodayExercises(_progress.currentDay);
    final completedExercises = currentExercises
        .where((e) => _completedExerciseUuids.contains(e.uuid))
        .map((e) {
      final lvl = e.getLevel(e.recommendedLevel);
      return CompletedExercise(
        exerciseUuid: e.uuid,
        exerciseName: e.name,
        setsCompleted: lvl?.sets ?? 1,
        repsCompleted: lvl?.reps,
        durationSeconds: lvl?.durationSeconds,
      );
    }).toList();

    final oldSessions = await _storageService.loadSessions();
    final oldProgress = _progress;

    final session = WorkoutSession(
      uuid: 'ws-${now.millisecondsSinceEpoch}',
      date: now,
      weekNumber: _progress.currentWeek,
      dayNumber: _progress.currentDay,
      focus: focus,
      durationSeconds: durationSeconds,
      exercises: completedExercises,
      plannedExerciseUuids: currentExercises.map((e) => e.uuid).toList(),
      steps: _steps,
      hydrationLiters: _hydrationLiters,
      achievementsUnlocked: [],
    );

    if (!mounted) return;
    final provider = context.read<AchievementProvider>();

    try {
      await _storageService.addSession(session);
      // Don't advance progress here — it will advance at midnight via
      // _onNewDay.  Mark lastAdvanceDate so _onNewDay knows progress
      // is current for today and won't double-advance.
      final updatedProgress = ProgramProgress(
        currentWeek: _progress.currentWeek,
        currentDay: _progress.currentDay,
        lastAdvanceDate: dateKey(DateTime.now()),
      );
      await _storageService.saveProgramProgress(updatedProgress);
      await _storageService.clearTodayState();

      // Evaluate new achievements via provider
      await provider.evaluateFromWorkout(oldSessions);
      final fresh = provider.pendingNewUnlocks;

      // Notification triggers
      final notifService = NotificationService();
      notifService.setLocalizations(AppLocalizations.of(context));
      await notifService.cancelAll();
      for (final id in fresh) {
        final def = provider.definitions.where((a) => a.id == id).firstOrNull;
        if (def != null) {
          await notifService.showAchievementNotification(
            def.title,
            def.description,
          );
        }
      }
      final newSessions = await _storageService.loadSessions();
      final consecutiveCount = _countConsecutiveWorkoutDays(newSessions);
      if (consecutiveCount >= 3) {
        await notifService.scheduleRecoverySuggestion();
      }

      setState(() {
        // Keep _progress at today's values so the "Today's Workout" section
        // shows a completion message rather than immediately advancing to
        // the next day's workout.  Progress will advance at midnight via
        // _onNewDay.
        _todayCompleted = true;
        _completedExerciseUuids = {};
        _steps = 0;
        _hydrationLiters = 0.0;
        _historyRefreshCounter++;
      });
      _rebuildScreens();
      _showCelebration(focus, completedExercises.length,
          durationSeconds, fresh);
    } catch (e) {
      debugPrint('Workout completion FAILED: $e');
      try {
        await _storageService.saveProgramProgress(oldProgress);
      } catch (_) {}
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).general_saveError),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showCelebration(String focus, int exerciseCount,
      int durationSeconds, List<String> newAchievementIds) async {
    HapticFeedback.heavyImpact();
    final provider = context.read<AchievementProvider>();
    final newResults = provider.pendingAchievementDetails();

    if (newResults.isEmpty) {
      // Workout-only celebration (no new achievements)
      final l10n = AppLocalizations.of(context);
      showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (ctx) => Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.subtleFill(context, 0.30),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppTheme.achievementGreen.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.emoji_events,
                  color: AppTheme.achievementGreen,
                  size: 40,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                l10n.celebration_workoutComplete,
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                focus,
                style: TextStyle(
                  color: AppTheme.textTertiary(context),
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _celebStat(context, '$exerciseCount', l10n.home_exercises),
                  _celebStat(context, '${durationSeconds ~/ 60}${l10n.home_min}',
                      l10n.home_duration),
                  _celebStat(context, 'W${_progress.currentWeek}',
                      l10n.home_completed),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(l10n.home_letsGo),
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      // Show elaborate celebration with confetti + achievement details
      provider.clearPendingUnlocks();
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => AchievementCelebration(
            newAchievements: newResults,
            exerciseCount: exerciseCount,
            durationSeconds: durationSeconds,
            completedWeek: _progress.currentWeek,
            focus: focus,
            onDismiss: () => Navigator.of(context).pop(),
          ),
        ),
      );
    }
  }

  Widget _celebStat(BuildContext context, String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: AppTheme.textPrimary(context),
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: AppTheme.textTertiary(context),
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    _rebuildScreens();
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: null,
      body: AnimatedSwitcher(
        duration: AppTheme.kAnimMedium,
        switchInCurve: AppTheme.kEaseOut,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (Widget child, Animation<double> animation) {
          final bool isForward = _selectedIndex > _previousIndex;
          final Offset begin = isForward
              ? const Offset(0.025, 0.0)
              : const Offset(-0.025, 0.0);
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(begin: begin, end: Offset.zero)
                  .animate(animation),
              child: child,
            ),
          );
        },
        child: KeyedSubtree(
          key: ValueKey(_selectedIndex),
          child: _screens[_selectedIndex],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (int index) {
          if (index != _selectedIndex) {
            HapticFeedback.selectionClick();
            _previousIndex = _selectedIndex;
            setState(() {
              _selectedIndex = index;
            });
          }
        },
        backgroundColor: Theme.of(context).colorScheme.surface,
        indicatorColor:
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.18),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home),
            label: l10n.nav_home,
          ),
          NavigationDestination(
            icon: const Icon(Icons.history_outlined),
            selectedIcon: const Icon(Icons.history),
            label: l10n.nav_history,
          ),
          NavigationDestination(
            icon: const Icon(Icons.person_outline),
            selectedIcon: const Icon(Icons.person),
            label: l10n.nav_profile,
          ),
        ],
      ),
    );
  }

  int _countConsecutiveWorkoutDays(List<WorkoutSession> sessions) {
    if (sessions.isEmpty) return 0;
    final sorted = List<WorkoutSession>.from(sessions)
      ..sort((a, b) => b.date.compareTo(a.date));
    int count = 1;
    for (int i = 1; i < sorted.length; i++) {
      final diff = sorted[i - 1].date.difference(sorted[i].date).inDays;
      if (diff <= 2) {
        count++;
      } else {
        break;
      }
    }
    return count;
  }
}
