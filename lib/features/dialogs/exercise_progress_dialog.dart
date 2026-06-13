import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/directional_icon.dart';
import '../../core/widgets/set_progress_bars.dart';
import '../../data/exercise.dart';
import '../../l10n/app_localizations.dart';
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
    with WidgetsBindingObserver {
  int _currentSet = 0;
  bool _isResting = false;
  int _restRemaining = 0;
  bool _isPaused = false;
  bool _isHolding = false;
  int _holdRemaining = 0;
  bool _isComplete = false;
  int _effectiveRestSeconds = 30;
  Timer? _timer;

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
    final l10n = AppLocalizations.of(context);
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
        appBar: AppBar(
          title: Text(
            widget.exercise.name,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary(context),
            ),
          ),
          leading: IconButton(
            icon: Icon(Icons.close, color: AppTheme.textSecondary(context)),
            onPressed: () {
              if (_isResting || _isHolding || _currentSet > 0) {
                _confirmExit();
              } else {
                Navigator.of(context).pop();
              }
            },
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.info_outline_rounded, color: AppTheme.textSecondary(context)),
              onPressed: () => _showInfo(context),
            ),
          ],
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const Spacer(flex: 1),

                // ── Exercise name (large, bold) ──
                Text(
                  widget.exercise.name,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppTheme.textPrimary(context),
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),

                // ── Pills row ──
                Wrap(
                  spacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    _pill(context, widget.exercise.recommendedLevel.label, lvlColor),
                    _pill(context, muscle.label, muscle.color),
                    _pill(context, cat.label, cat.color),
                  ],
                ),
                const SizedBox(height: 32),

                // ── Progress ring ──
                _buildProgressSection(context, colorScheme),

                const SizedBox(height: 24),

                // ── Target info ──
                if (!_isComplete && _targetInfo(l10n).isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppTheme.subtleFill(context, 0.06),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _targetInfo(l10n),
                      style: TextStyle(
                        color: AppTheme.textSecondary(context),
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                const Spacer(flex: 1),

                // ── Main action area ──
                if (!_isComplete)
                  _buildAction(context, colorScheme)
                else
                  _buildCompleteState(context, colorScheme),

                const SizedBox(height: 12),

                // ── End Workout ──
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
    final l10n = AppLocalizations.of(context);
    if (_isComplete) {
      return _buildCompleteBars(context);
    }

    return SetProgressBars(
      currentSet: _currentSet,
      totalSets: _totalSets,
      isHolding: _isHolding,
      isResting: _isResting,
      holdProgress: _holdElapsed,
      label: '${l10n.dialog_setLabel(_currentSet + 1)} ${l10n.dialog_ofTotal(_totalSets)}',
      semanticsLabel: l10n.dialog_setOfSemantics(_currentSet + 1, _totalSets),
    );
  }

  String _targetInfo(AppLocalizations l10n) {
    if (_isTimeBased) {
      return l10n.dialog_secondsHold(_level?.durationSeconds ?? 0);
    }
    final parts = <String>[];
    if (_level?.reps != null) parts.add(l10n.dialog_repsCount(_level!.reps!));
    if (_level?.weightKg != null) parts.add(l10n.dialog_weightKgLabel(_level!.weightKg!));
    return parts.join(' · ');
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
    final l10n = AppLocalizations.of(context);
    return SizedBox(
      width: double.infinity,
      height: 64,
      child: FilledButton.icon(
        onPressed: _completeSet,
        icon: _currentSet == 0
            ? DirectionalIcon(icon: Icons.play_arrow_rounded, size: 28)
            : const Icon(Icons.check_circle_outline, size: 28),
        label: Text(
          _currentSet == 0 ? l10n.dialog_startSet(_currentSet + 1) : l10n.dialog_completeSet,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  Widget _buildHoldTimer(BuildContext context, ColorScheme colorScheme) {
    final l10n = AppLocalizations.of(context);
    final warning = _holdRemaining <= 5;
    final timerColor = warning ? AppTheme.stepsOrange : AppTheme.hydrationBlue;

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 24),
          decoration: BoxDecoration(
            color: timerColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              Text(
                l10n.dialog_hold,
                style: TextStyle(
                  color: AppTheme.textSecondary(context),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _formatTime(_holdRemaining),
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 56,
                  fontWeight: FontWeight.w700,
                  color: timerColor,
                  height: 1.0,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: 200,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: 1.0 - _holdElapsed,
                    backgroundColor: AppTheme.subtleFill(context, 0.15),
                    color: timerColor,
                    minHeight: 6,
                  ),
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
            l10n.dialog_skipHold,
            style: TextStyle(color: AppTheme.textSecondary(context)),
          ),
        ),
      ],
    );
  }

  Widget _buildRestTimer(BuildContext context, ColorScheme colorScheme) {
    final l10n = AppLocalizations.of(context);
    final warning = _restRemaining <= 5;
    final timerColor = warning ? AppTheme.stepsOrange : AppTheme.hydrationBlue;

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: timerColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              Text(
                l10n.dialog_rest,
                style: TextStyle(
                  color: AppTheme.textSecondary(context),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _formatTime(_restRemaining),
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 48,
                  fontWeight: FontWeight.w700,
                  color: timerColor,
                  height: 1.0,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: 180,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: _restProgress,
                    backgroundColor: AppTheme.subtleFill(context, 0.15),
                    color: timerColor,
                    minHeight: 5,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: DirectionalIcon(
                icon: _isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                color: AppTheme.textSecondary(context),
              ),
              onPressed: _togglePause,
              style: IconButton.styleFrom(
                backgroundColor: AppTheme.subtleFill(context, 0.10),
              ),
            ),
            const SizedBox(width: 16),
            IconButton(
          icon: DirectionalIcon(icon: Icons.skip_next_rounded, color: AppTheme.textSecondary(context)),
              onPressed: _skipRest,
              style: IconButton.styleFrom(
                backgroundColor: AppTheme.subtleFill(context, 0.10),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCompleteBars(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final green = AppTheme.achievementGreen;

    return Column(
      children: [
        SetProgressBars(
          currentSet: _totalSets,
          totalSets: _totalSets,
          isComplete: true,
          label: l10n.dialog_allSetsDone,
          semanticsLabel: l10n.dialog_allSetsDone,
        ),
        const SizedBox(height: 16),
        Icon(Icons.check_circle, color: green, size: 48),
        const SizedBox(height: 8),
        Text(
          l10n.dialog_greatWork,
          style: TextStyle(
            color: AppTheme.textSecondary(context),
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildCompleteState(BuildContext context, ColorScheme colorScheme) {
    final l10n = AppLocalizations.of(context);
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 56,
          child: FilledButton.icon(
            onPressed: () => Navigator.of(context).pop(),
            icon: const DirectionalIcon(icon: Icons.arrow_back_rounded, size: 22),
            label: Text(
              l10n.dialog_backToWorkout,
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
    final l10n = AppLocalizations.of(context);
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
          l10n.dialog_endWorkout,
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
    final l10n = AppLocalizations.of(context);
    HapticFeedback.lightImpact();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(l10n.dialog_endWorkoutTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.dialog_endWorkoutBody(_currentSet, _totalSets),
              style: TextStyle(color: AppTheme.textSecondary(context)),
            ),
            if (_isResting)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  l10n.dialog_restTimerActive,
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
              l10n.dialog_cancel,
              style: TextStyle(color: AppTheme.textSecondary(context)),
            ),
          ),
          FilledButton(
            onPressed: () {
              HapticFeedback.mediumImpact();
              // Mark the exercise as completed so the user gets credit
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
            child: Text(l10n.dialog_endWorkout),
          ),
        ],
      ),
    );
  }

  void _showInfo(BuildContext context) {
    final l10n = AppLocalizations.of(context);
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
                  l10n.dialog_equipment(ex.equipment!),
                  style: TextStyle(color: AppTheme.textTertiary(context)),
                ),
              ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _launchYouTube(ex.name),
                icon: const Icon(Icons.play_circle_outline),
                label: Text(l10n.dialog_watchOnYoutube),
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
