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

  Future<void> _onNewDay(String today) async {
    _lastDateKey = today;

    final progress = await _storageService.loadProgramProgress();
    final sessions = await _storageService.loadSessions();

    bool alreadyAdvanced = sessions.any((s) {
      final next = ProgramProgress(
        currentWeek: s.weekNumber,
        currentDay: s.dayNumber,
      ).advance();
      return next.currentWeek == progress.currentWeek &&
          next.currentDay == progress.currentDay;
    });

    if (!alreadyAdvanced) {
      final next = progress.advance();
      await _storageService.saveProgramProgress(next);
    }

    _loadAll();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _rebuildScreens();
    _initStepCounter();
    _loadAll().then((_) {
      _lastDateKey = dateKey(DateTime.now());
    });
    _dayCheckTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      final today = dateKey(DateTime.now());
      if (today != _lastDateKey) {
        _onNewDay(today);
      }
    });
  }

  Future<void> _initStepCounter() async {
    await _stepService.initialize();
    _stepSubscription = _stepService.stepStream.listen((steps) {
      if (mounted) {
        setState(() => _steps = steps);
      }
    });
    if (_useSensor) {
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
    final hydration = await _storageService.loadTodayHydration();
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
      await NotificationService().scheduleMissedWorkoutReminder();
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
    _persistToday();
  }

  void _onStepsChanged(int v) {
    setState(() => _steps = v);
    _stepStorage.saveTodaySteps(v);
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
  }

  Future<void> _onResetSteps() async {
    await _stepStorage.saveTodaySteps(0);
    _loadAll();
  }

  Future<void> _onResetHydration() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('today_date', dateKey(DateTime.now()));
    await prefs.setDouble('today_hydration', 0.0);
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
    final now = DateTime.now();
    final focus = getFocusForDay(
        _progress.currentWeek, _progress.currentDay);

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

    final next = _progress.advance();
    final provider = context.read<AchievementProvider>();

    try {
      await _storageService.addSession(session);
      await _storageService.saveProgramProgress(next);
      await _storageService.clearTodayState();

      // Evaluate new achievements via provider
      await provider.evaluateFromWorkout(oldSessions);
      final fresh = provider.pendingNewUnlocks;

      // Notification triggers
      final notifService = NotificationService();
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
        // the next day's workout. The advanced progress is already saved
        // to storage above — it will be loaded on the next calendar day.
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
