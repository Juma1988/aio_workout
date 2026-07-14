import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/directional_icon.dart';
import '../../data/exercise.dart';
import '../notifications/services/notification_service.dart';

class ExerciseProgressDialog extends StatefulWidget {
  final Exercise exercise;
  final int restSeconds;
  final VoidCallback onComplete;

  const ExerciseProgressDialog({
    super.key,
    required this.exercise,
    this.restSeconds = 30,
    required this.onComplete,
  });

  @override
  State<ExerciseProgressDialog> createState() => _ExerciseProgressDialogState();
}

class _ExerciseProgressDialogState extends State<ExerciseProgressDialog>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  int _currentSet = 0;
  bool _isResting = false;
  int _restRemaining = 0;
  bool _isPaused = false;
  bool _isHolding = false;
  int _holdRemaining = 0;
  bool _isComplete = false;
  int _effectiveRestSeconds = 30;
  Timer? _timer;
  late final AnimationController _buttonScaleController;

  ExerciseLevel? get _level =>
      widget.exercise.getLevel(widget.exercise.recommendedLevel);
  int get _totalSets => _level?.sets ?? 3;
  bool get _isTimeBased => widget.exercise.isTimeBased;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _effectiveRestSeconds = widget.restSeconds;
    _loadRestTimer();
    if (_isTimeBased) _startHold();
    _buttonScaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      value: 1.0,
      lowerBound: 0.95,
      upperBound: 1.0,
    );
  }

  Future<void> _loadRestTimer() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _effectiveRestSeconds = prefs.getInt('rest_timer_seconds') ?? widget.restSeconds;
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _buttonScaleController.dispose();
    NotificationService().cancelRestTimerNotification();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      NotificationService().cancelRestTimerNotification();
      _checkExpiredTimers();
    } else if (state == AppLifecycleState.paused) {
      if (_isResting && _restRemaining > 0) {
        NotificationService().scheduleRestTimerComplete(_restRemaining);
      }
    }
  }

  void _checkExpiredTimers() {
    if (_isResting && _restRemaining <= 0) {
      _onRestComplete();
    }
    if (_isHolding && _holdRemaining <= 0) {
      _completeSet();
    }
  }

  void _startHold() {
    setState(() {
      _isHolding = true;
      _holdRemaining = _level?.durationSeconds ?? 30;
    });
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_isPaused) return;
      if (_isHolding) {
        if (_holdRemaining > 1) {
          setState(() => _holdRemaining--);
        } else {
          setState(() => _holdRemaining = 0);
          _completeSet();
        }
      } else if (_isResting) {
        if (_restRemaining > 1) {
          setState(() => _restRemaining--);
        } else {
          setState(() => _restRemaining = 0);
          _onRestComplete();
        }
      }
    });
  }

  void _completeSet() {
    HapticFeedback.mediumImpact();
    setState(() {
      _isHolding = false;
      _currentSet++;
      _timer?.cancel();
    });
    if (_currentSet >= _totalSets) {
      _finishWorkout();
    } else {
      _startRest();
    }
  }

  void _finishWorkout() {
    HapticFeedback.heavyImpact();
    setState(() => _isComplete = true);
    widget.onComplete();
  }

  void _startRest() {
    setState(() {
      _isResting = true;
      _isPaused = false;
      _restRemaining = _effectiveRestSeconds;
    });
    _startTimer();
  }

  void _onRestComplete() {
    HapticFeedback.heavyImpact();
    SystemSound.play(SystemSoundType.click);
    _timer?.cancel();
    NotificationService().cancelRestTimerNotification();
    setState(() {
      _isResting = false;
      _isPaused = false;
    });
    if (_isTimeBased) {
      _startHold();
    }
  }

  void _skipRest() {
    HapticFeedback.lightImpact();
    _timer?.cancel();
    NotificationService().cancelRestTimerNotification();
    setState(() {
      _isResting = false;
      _isPaused = false;
    });
    if (_isTimeBased) {
      _startHold();
    }
  }

  void _togglePause() {
    HapticFeedback.selectionClick();
    setState(() => _isPaused = !_isPaused);
  }

  String _formatTime(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  double get _restProgress =>
      _restRemaining / (_effectiveRestSeconds).clamp(1, double.infinity);
  double get _holdElapsed {
    final total = (_level?.durationSeconds ?? 1).clamp(1, double.infinity);
    return (total - _holdRemaining) / total;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final cat = widget.exercise.category;
    final muscle = widget.exercise.targetMuscle;
    final lvlColor = widget.exercise.recommendedLevel.color;

    return PopScope(
      canPop: !_isResting && !_isHolding,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmExit();
      },
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Spacer(),
                    Semantics(
                      label: 'Close',
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          if (_isResting || _isHolding || _currentSet > 0) {
                            _confirmExit();
                          } else {
                            Navigator.of(context).pop();
                          }
                        },
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppTheme.subtleFill(context, 0.10),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.close, color: AppTheme.textSecondary(context), size: 20),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Semantics(
                      label: 'Exercise info',
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => _showInfo(context),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppTheme.subtleFill(context, 0.10),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.info_outline_rounded, color: AppTheme.textSecondary(context), size: 20),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  widget.exercise.name,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppTheme.textPrimary(context),
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    _pill(context, widget.exercise.recommendedLevel.label, lvlColor),
                    _pill(context, muscle.label, muscle.color),
                    _pill(context, cat.label, cat.color),
                  ],
                ),
                const Spacer(),
                _buildProgressSection(context, colorScheme),
                const Spacer(),
                if (!_isComplete)
                  _buildAction(context, colorScheme)
                else
                  _buildCompleteState(context, colorScheme),
                const SizedBox(height: 12),
                _buildEndWorkoutButton(context, colorScheme),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressSection(BuildContext context, ColorScheme colorScheme) {
    final progress = _currentSet / _totalSets.clamp(1, double.infinity);
    final setLabel = 'SET ${_currentSet + 1}';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          label: 'Set $_currentSet of $_totalSets',
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: _currentSet.toDouble()),
            duration: AppTheme.kAnimProgress,
            curve: AppTheme.kEaseOut,
            builder: (context, animatedSet, _) {
              return Text(
                animatedSet.toInt().toString(),
                style: TextStyle(
                  color: AppTheme.textPrimary(context),
                  fontSize: 72,
                  fontWeight: FontWeight.w900,
                  height: 1.0,
                ),
              );
            },
          ),
        ),
        Text(
          'of $_totalSets',
          style: TextStyle(
            color: AppTheme.textSecondary(context),
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        if (!_isComplete)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.achievementGreen.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              setLabel,
              style: TextStyle(
                color: AppTheme.achievementGreen,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        const SizedBox(height: 16),
        SizedBox(
          width: 120,
          height: 120,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: progress),
            duration: AppTheme.kAnimProgress,
            curve: AppTheme.kEaseOut,
            builder: (context, animatedProgress, _) {
              return CircularProgressIndicator(
                value: animatedProgress,
                strokeWidth: 10,
                backgroundColor: AppTheme.subtleFill(context, 0.12),
                color: colorScheme.primary,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAction(BuildContext context, ColorScheme colorScheme) {
    if (_isHolding) {
      return _buildHoldTimer(context, colorScheme);
    }
    if (_isResting) {
      return _buildRestTimer(context, colorScheme);
    }
    return _buildCompleteButton(context, colorScheme);
  }

  Widget _buildCompleteButton(BuildContext context, ColorScheme colorScheme) {
    final isFirst = _currentSet == 0;
    final icon = isFirst ? Icons.fitness_center : Icons.check_circle;
    final label = isFirst ? 'START' : 'COMPLETE SET';
    final bgColor = isFirst ? colorScheme.primary : AppTheme.achievementGreen;

    return GestureDetector(
      onTapDown: (_) => _buttonScaleController.forward(),
      onTapUp: (_) {
        _buttonScaleController.reverse();
        _completeSet();
      },
      onTapCancel: () => _buttonScaleController.reverse(),
      child: AnimatedBuilder(
        animation: _buttonScaleController,
        builder: (context, child) {
          return Transform.scale(
            scale: _buttonScaleController.value,
            child: child,
          );
        },
        child: SizedBox(
          width: double.infinity,
          height: 72,
          child: Container(
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white, size: 28),
                const SizedBox(width: 10),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHoldTimer(BuildContext context, ColorScheme colorScheme) {
    final warning = _holdRemaining <= 5;
    final timerColor = warning ? AppTheme.stepsOrange : AppTheme.hydrationBlue;
    final progress = _holdElapsed;

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 24),
          decoration: BoxDecoration(
            color: AppTheme.hydrationBlue.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              Text(
                'HOLD',
                style: TextStyle(
                  color: timerColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: 160,
                height: 160,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: progress),
                      duration: const Duration(milliseconds: 300),
                      curve: AppTheme.kEaseOut,
                      builder: (context, animatedProgress, _) {
                        return CircularProgressIndicator(
                          value: animatedProgress,
                          strokeWidth: 8,
                          backgroundColor: AppTheme.subtleFill(context, 0.12),
                          color: timerColor,
                        );
                      },
                    ),
                    Text(
                      _formatTime(_holdRemaining),
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 64,
                        fontWeight: FontWeight.w700,
                        color: timerColor,
                        height: 1.0,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        TextButton.icon(
          onPressed: _completeSet,
          icon: DirectionalIcon(icon: Icons.skip_next_rounded, color: AppTheme.textSecondary(context)),
          label: Text(
            'Skip Hold',
            style: TextStyle(color: AppTheme.textSecondary(context)),
          ),
        ),
      ],
    );
  }

  Widget _buildRestTimer(BuildContext context, ColorScheme colorScheme) {
    final warning = _restRemaining <= 5;
    final timerColor = warning ? AppTheme.stepsOrange : AppTheme.hydrationBlue;
    final progress = _restProgress;

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 24),
          decoration: BoxDecoration(
            color: AppTheme.hydrationBlue.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              Text(
                'REST',
                style: TextStyle(
                  color: timerColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: 160,
                height: 160,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: progress),
                      duration: const Duration(milliseconds: 300),
                      curve: AppTheme.kEaseOut,
                      builder: (context, animatedProgress, _) {
                        return CircularProgressIndicator(
                          value: animatedProgress,
                          strokeWidth: 8,
                          backgroundColor: AppTheme.subtleFill(context, 0.12),
                          color: timerColor,
                        );
                      },
                    ),
                    Text(
                      _formatTime(_restRemaining),
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 64,
                        fontWeight: FontWeight.w700,
                        color: timerColor,
                        height: 1.0,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Semantics(
              label: _isPaused ? 'Resume' : 'Pause',
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: _togglePause,
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppTheme.subtleFill(context, 0.10),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                    color: AppTheme.textSecondary(context),
                    size: 24,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Semantics(
              label: 'Skip rest',
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: _skipRest,
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppTheme.subtleFill(context, 0.10),
                    shape: BoxShape.circle,
                  ),
                  child: DirectionalIcon(
                    icon: Icons.skip_next_rounded,
                    color: AppTheme.textSecondary(context),
                    size: 24,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCompleteState(BuildContext context, ColorScheme colorScheme) {
    return Column(
      children: [
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: AppTheme.kAnimEntrance,
          curve: AppTheme.kEaseOut,
          builder: (context, scale, _) {
            return Transform.scale(
              scale: scale,
              child: SizedBox(
                width: 120,
                height: 120,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: AppTheme.kAnimProgress,
                  curve: AppTheme.kEaseOut,
                  builder: (context, ringProgress, _) {
                    return CircularProgressIndicator(
                      value: ringProgress,
                      strokeWidth: 10,
                      backgroundColor: AppTheme.subtleFill(context, 0.12),
                      color: AppTheme.achievementGreen,
                    );
                  },
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        const Icon(Icons.check_circle, color: AppTheme.achievementGreen, size: 48),
        const SizedBox(height: 16),
        Text(
          'ALL SETS DONE!',
          style: TextStyle(
            color: AppTheme.achievementGreen,
            fontSize: 28,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Great work!',
          style: TextStyle(
            color: AppTheme.textSecondary(context),
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: FilledButton.icon(
            onPressed: () => Navigator.of(context).pop(),
            icon: const DirectionalIcon(icon: Icons.arrow_back_rounded, size: 22),
            label: const Text(
              'Back to Workout',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.achievementGreen,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEndWorkoutButton(BuildContext context, ColorScheme colorScheme) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton.icon(
        onPressed: () {
          if (_currentSet > 0 || _isResting || _isHolding) {
            _confirmExit();
          } else {
            Navigator.of(context).pop();
          }
        },
        icon: Icon(Icons.stop_circle_outlined, color: colorScheme.error, size: 20),
        label: Text(
          'End Workout',
          style: TextStyle(color: colorScheme.error, fontWeight: FontWeight.w500),
        ),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: colorScheme.error.withValues(alpha: 0.4)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  void _confirmExit() {
    HapticFeedback.lightImpact();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text('End Workout?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'You completed $_currentSet of $_totalSets sets.',
              style: TextStyle(color: AppTheme.textSecondary(context)),
            ),
            if (_isResting)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Rest timer is active.',
                  style: TextStyle(
                    color: AppTheme.stepsOrange,
                    fontSize: 13,
                  ),
                ),
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
            onPressed: () {
              HapticFeedback.mediumImpact();
              widget.onComplete();
              Navigator.of(ctx).pop();
              Navigator.of(context).pop();
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('End Workout'),
          ),
        ],
      ),
    );
  }

  void _showInfo(BuildContext context) {
    HapticFeedback.lightImpact();
    final ex = widget.exercise;
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
                _pill(ctx, ex.recommendedLevel.label, lvlColor),
                _pill(ctx, muscle.label, muscle.color),
                _pill(ctx, cat.label, cat.color),
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
