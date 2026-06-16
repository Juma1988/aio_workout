import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;

import '../../../core/theme/app_theme.dart' as theme;

class FaqItemWidget extends StatefulWidget {
  final IconData icon;
  final Color color;
  final String question;
  final String answer;
  final bool isExpanded;
  final VoidCallback onToggle;

  const FaqItemWidget({
    super.key,
    required this.icon,
    required this.color,
    required this.question,
    required this.answer,
    required this.isExpanded,
    required this.onToggle,
  });

  @override
  State<FaqItemWidget> createState() => _FaqItemWidgetState();
}

class _FaqItemWidgetState extends State<FaqItemWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _arrowController;
  late Animation<double> _arrowAnimation;

  @override
  void initState() {
    super.initState();
    _arrowController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _arrowAnimation = Tween<double>(begin: 0.0, end: 0.5).animate(
      CurvedAnimation(parent: _arrowController, curve: Curves.easeInOut),
    );
    if (widget.isExpanded) _arrowController.value = 1.0;
  }

  @override
  void didUpdateWidget(FaqItemWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isExpanded && !oldWidget.isExpanded) {
      _arrowController.forward();
    } else if (!widget.isExpanded && oldWidget.isExpanded) {
      _arrowController.reverse();
    }
  }

  @override
  void dispose() {
    _arrowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: theme.AppTheme.cardColor(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: widget.isExpanded
              ? widget.color.withValues(alpha: 0.3)
              : theme.AppTheme.subtleFill(context, 0.12),
        ),
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () {
              HapticFeedback.selectionClick();
              widget.onToggle();
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: widget.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(widget.icon, color: widget.color, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.question,
                      style: TextStyle(
                        color: theme.AppTheme.textPrimary(context),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  AnimatedBuilder(
                    animation: _arrowAnimation,
                    builder: (context, _) {
                      return Transform.rotate(
                        angle: _arrowAnimation.value * math.pi,
                        child: Icon(
                          Icons.expand_more_rounded,
                          color: theme.AppTheme.textTertiary(context),
                          size: 22,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 200),
            crossFadeState: widget.isExpanded
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            firstChild: Column(
              children: [
                Divider(
                    height: 1,
                    color: widget.color.withValues(alpha: 0.12)),
                Padding(
                  padding:
                      const EdgeInsets.fromLTRB(14, 10, 14, 12),
                  child: Text(
                    widget.answer,
                    style: TextStyle(
                      color: theme.AppTheme.textSecondary(context),
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
            secondChild: const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}