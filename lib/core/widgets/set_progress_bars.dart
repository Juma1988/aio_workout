import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class SetProgressBars extends StatefulWidget {
  final int currentSet;
  final int totalSets;
  final bool isHolding;
  final bool isResting;
  final bool isComplete;
  final double holdProgress;
  final String? label;
  final String? semanticsLabel;

  const SetProgressBars({
    super.key,
    required this.currentSet,
    required this.totalSets,
    this.isHolding = false,
    this.isResting = false,
    this.isComplete = false,
    this.holdProgress = 0.0,
    this.label,
    this.semanticsLabel,
  });

  @override
  State<SetProgressBars> createState() => _SetProgressBarsState();
}

class _SetProgressBarsState extends State<SetProgressBars>
    with SingleTickerProviderStateMixin {
  late AnimationController _bounceCtrl;
  late Animation<double> _bounceAnim;

  @override
  void initState() {
    super.initState();
    _bounceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _bounceAnim = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 1.0),
        weight: 45,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.0),
        weight: 55,
      ),
    ]).animate(CurvedAnimation(
      parent: _bounceCtrl,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void didUpdateWidget(SetProgressBars oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.isComplete && widget.isComplete) {
      _bounceCtrl.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _bounceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final green = AppTheme.achievementGreen;
    const barHeight = 52.0;
    final segmentCount = widget.totalSets.clamp(1, 6);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          label: widget.semanticsLabel ?? '',
          child: Text(
            widget.label ??
                'Set ${widget.currentSet + 1} of ${widget.totalSets}',
            style: TextStyle(
              color: AppTheme.textPrimary(context),
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 16),
        AnimatedBuilder(
          animation: _bounceAnim,
          builder: (context, child) {
            final scale = 1.0 + (_bounceAnim.value * 0.14);
            return Transform.scale(scale: scale, child: child);
          },
          child: SizedBox(
            height: barHeight,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Row(
                children: List.generate(segmentCount, (i) {
                  final isCompleted = i < widget.currentSet || widget.isComplete;
                  final isCurrent = i == widget.currentSet && !widget.isComplete;
                  final isInProgress = isCurrent && widget.isHolding;
                  final isActive =
                      isCurrent && !widget.isHolding && !widget.isResting;
                  final isPending = i > widget.currentSet && !widget.isComplete;

                  final fillFraction = isCompleted
                      ? 1.0
                      : (isInProgress
                          ? widget.holdProgress.clamp(0.0, 1.0)
                          : (isActive ? 0.06 : 0.0));

                  final fillColor = isCompleted
                      ? green
                      : (isInProgress
                          ? green.withValues(alpha: 0.6)
                          : (isActive
                              ? green.withValues(alpha: 0.25)
                              : Colors.transparent));

                  final bgColor = isPending
                      ? AppTheme.subtleFill(context, 0.20)
                      : AppTheme.subtleFill(context, 0.08);

                  final labelColor = isCompleted || isInProgress
                      ? green
                      : AppTheme.textTertiary(context);

                  return Expanded(
                    child: Container(
                      decoration: i < segmentCount - 1
                          ? BoxDecoration(
                              border: Border(
                                right: BorderSide(
                                  color: AppTheme.subtleFill(context, 0.15),
                                  width: 1,
                                ),
                              ),
                            )
                          : null,
                      child: Stack(
                        children: [
                          Container(color: bgColor),
                          TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0.0, end: fillFraction),
                            duration: AppTheme.kAnimMedium,
                            curve: AppTheme.kEaseOut,
                            builder: (context, frac, _) {
                              return FractionallySizedBox(
                                widthFactor: frac,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: fillColor,
                                  ),
                                ),
                              );
                            },
                          ),
                          Align(
                            alignment: Alignment.bottomCenter,
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (isCompleted && i < widget.currentSet)
                                    Padding(
                                      padding:
                                          const EdgeInsets.only(right: 3),
                                      child: Icon(
                                        Icons.check,
                                        size: 13,
                                        color: green,
                                      ),
                                    ),
                                  Text(
                                    '${i + 1}',
                                    style: TextStyle(
                                      color: labelColor,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
