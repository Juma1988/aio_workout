import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_theme.dart';
import '../../data/workout_log.dart';
import '../../services/workout_storage_service.dart';
import '../home/home_screen.dart';
import '../history/history_screen.dart';
import '../profile/profile_screen.dart';
import '../notifications/services/notification_service.dart';

class MainShell extends StatefulWidget {
  final VoidCallback? onThemeToggle;

  const MainShell({super.key, this.onThemeToggle});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;
  int _previousIndex = 0;

  double _hydrationLiters = 0.0;
  int _steps = 0;
  Set<String> _completedExerciseUuids = {};

  ProgramProgress _progress = const ProgramProgress();
  final _storageService = WorkoutStorageService();
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _loadAll();
    _screens = [
      HomeScreen(
        onThemeToggle: widget.onThemeToggle,
        hydrationLiters: _hydrationLiters,
        steps: _steps,
        completedExerciseUuids: _completedExerciseUuids,
        currentWeek: _progress.currentWeek,
        currentDay: _progress.currentDay,
        onHydrationChanged: _onHydrationChanged,
        onStepsChanged: _onStepsChanged,
        onExerciseCompleted: _onExerciseCompleted,
        onExerciseToggled: _onExerciseToggled,
        onWorkoutComplete: _onWorkoutComplete,
      ),
      HistoryScreen(
        key: ValueKey(_progress.currentWeek),
      ),
      const ProfileScreen(),
    ];
  }

  Future<void> _loadAll() async {
    final progress = await _storageService.loadProgramProgress();
    final steps = await _storageService.loadTodaySteps();
    final hydration = await _storageService.loadTodayHydration();
    final uuids = await _storageService.loadTodayCompletedUuids();
    if (mounted) {
      setState(() {
        _progress = progress;
        _steps = steps;
        _hydrationLiters = hydration;
        _completedExerciseUuids = uuids;
      });
    }
    await _checkMissedWorkoutReminder(progress);
  }

  Future<void> _checkMissedWorkoutReminder(ProgramProgress progress) async {
    if (progress.currentDay > 4) return;
    final sessions = await _storageService.loadSessions();
    final todayStr = DateTime.now().toIso8601String().substring(0, 10);
    final hasTodaySession = sessions.any(
      (s) => s.date.toIso8601String().substring(0, 10) == todayStr,
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
  }

  void _onHydrationChanged(double v) {
    setState(() => _hydrationLiters = v);
    _persistToday();
  }

  void _onStepsChanged(int v) {
    setState(() => _steps = v);
    _persistToday();
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

    final completedExercises = todayExercises
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
    final oldUnlocked =
        evaluateAchievements(oldSessions).map((a) => a.id).toSet();

    final session = WorkoutSession(
      uuid: 'ws-${now.millisecondsSinceEpoch}',
      date: now,
      weekNumber: _progress.currentWeek,
      dayNumber: _progress.currentDay,
      focus: focus,
      durationSeconds: durationSeconds,
      exercises: completedExercises,
      plannedExerciseUuids: todayExercises.map((e) => e.uuid).toList(),
      steps: _steps,
      hydrationLiters: _hydrationLiters,
      achievementsUnlocked: [],
    );

    final next = _progress.advance();

    await _storageService.addSession(session);
    await _storageService.saveProgramProgress(next);
    await _storageService.clearTodayState();

    final newSessions = await _storageService.loadSessions();
    final newUnlocked =
        evaluateAchievements(newSessions).map((a) => a.id).toSet();
    final fresh = newUnlocked.difference(oldUnlocked).toList();

    // ── Notification triggers ──
    final notifService = NotificationService();
    await notifService.cancelAll();
    for (final id in fresh) {
      final def = allAchievementDefinitions
          .where((a) => a.id == id)
          .firstOrNull;
      if (def != null) {
        await notifService.showAchievementNotification(
          def.title,
          def.description,
        );
      }
    }
    // Schedule recovery suggestion if 3+ consecutive days
    final consecutiveCount = _countConsecutiveWorkoutDays(newSessions);
    if (consecutiveCount >= 3) {
      await notifService.scheduleRecoverySuggestion();
    }

    setState(() {
      _progress = next;
      _completedExerciseUuids = {};
      _steps = 0;
      _hydrationLiters = 0.0;
    });

    _screens[0] = HomeScreen(
      onThemeToggle: widget.onThemeToggle,
      hydrationLiters: _hydrationLiters,
      steps: _steps,
      completedExerciseUuids: _completedExerciseUuids,
      currentWeek: _progress.currentWeek,
      currentDay: _progress.currentDay,
      onHydrationChanged: _onHydrationChanged,
      onStepsChanged: _onStepsChanged,
      onExerciseCompleted: _onExerciseCompleted,
      onExerciseToggled: _onExerciseToggled,
      onWorkoutComplete: _onWorkoutComplete,
    );

    _screens[1] = HistoryScreen(
      key: ValueKey(_progress.currentWeek),
    );

    _showCelebration(now, focus, completedExercises.length,
        durationSeconds, fresh);
  }

  void _showCelebration(DateTime date, String focus, int exerciseCount,
      int durationSeconds, List<String> newAchievements) {
    HapticFeedback.heavyImpact();
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
              'Workout Complete!',
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
                _celebStat(context, '$exerciseCount', 'Exercises'),
                _celebStat(context, '${durationSeconds ~/ 60}min',
                    'Duration'),
                _celebStat(context, 'W${_progress.currentWeek - 1}',
                    'Completed'),
              ],
            ),
            if (newAchievements.isNotEmpty) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppTheme.achievementGreen.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.emoji_events,
                        color: AppTheme.achievementGreen, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${newAchievements.length} new achievement${newAchievements.length > 1 ? 's' : ''} unlocked!',
                        style: TextStyle(
                          color: AppTheme.achievementGreen,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
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
                child: const Text('Let\'s Go!'),
              ),
            ),
          ],
        ),
      ),
    );
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
    _screens[0] = HomeScreen(
      onThemeToggle: widget.onThemeToggle,
      hydrationLiters: _hydrationLiters,
      steps: _steps,
      completedExerciseUuids: _completedExerciseUuids,
      currentWeek: _progress.currentWeek,
      currentDay: _progress.currentDay,
      onHydrationChanged: _onHydrationChanged,
      onStepsChanged: _onStepsChanged,
      onExerciseCompleted: _onExerciseCompleted,
      onExerciseToggled: _onExerciseToggled,
      onWorkoutComplete: _onWorkoutComplete,
    );

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
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history),
            label: 'History',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
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
