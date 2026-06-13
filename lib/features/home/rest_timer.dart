import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_theme.dart';

/// A countdown rest timer that appears after completing an exercise.
///
/// Shows a circular progress ring + remaining seconds. When the timer
/// expires it fires [onComplete] and triggers haptic feedback. The user
/// can tap to skip the rest early.
class RestTimer extends StatefulWidget {
  final int seconds;
  final VoidCallback onComplete;

  const RestTimer({
    super.key,
    required this.seconds,
    required this.onComplete,
  });

  @override
  State<RestTimer> createState() => _RestTimerState();
}

class _RestTimerState extends State<RestTimer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late int _remaining;
  Timer? _tickTimer;

  @override
  void initState() {
    super.initState();
    _remaining = widget.seconds;
    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: widget.seconds),
    )..forward();
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _onExpired();
      }
    });
    // Second-precision ticker for the label
    _tickTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final elapsed = (_controller.value * widget.seconds).floor();
      final remaining = widget.seconds - elapsed;
      if (remaining != _remaining) {
        setState(() => _remaining = remaining);
      }
    });
  }

  @override
  void dispose() {
    _tickTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onExpired() {
    _tickTimer?.cancel();
    HapticFeedback.heavyImpact();
    widget.onComplete();
  }

  void _skip() {
    _controller.stop();
    _tickTimer?.cancel();
    widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _skip,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.subtleFill(context, 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppTheme.subtleFill(context, 0.20),
          ),
        ),
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return Row(
              children: [
                SizedBox(
                  width: 36,
                  height: 36,
                  child: CircularProgressIndicator(
                    value: 1.0 - _controller.value,
                    strokeWidth: 3,
                    backgroundColor: AppTheme.subtleFill(context, 0.15),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _remaining <= 3 ? Colors.redAccent : AppTheme.weightPurple,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Rest',
                      style: TextStyle(
                        color: AppTheme.textSecondary(context),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '${_remaining}s',
                      style: TextStyle(
                        color: AppTheme.textPrimary(context),
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  'Tap to skip',
                  style: TextStyle(
                    color: AppTheme.textTertiary(context),
                    fontSize: 12,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
