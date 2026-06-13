import 'dart:math';
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class StepChart extends StatelessWidget {
  final List<double> values;
  final List<String> labels;
  final double goal;
  final Color color;

  const StepChart({
    super.key,
    required this.values,
    required this.labels,
    required this.goal,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    if (values.isEmpty) {
      return SizedBox(
        height: 120,
        child: Center(
          child: Text(
            'No data',
            style: TextStyle(color: AppTheme.textTertiary(context)),
          ),
        ),
      );
    }

    final maxVal = values.reduce(max);
    final displayMax = max(maxVal, goal) * 1.1;

    return SizedBox(
      height: 160,
      child: CustomPaint(
        size: Size.infinite,
        painter: _StepChartPainter(
          values: values,
          labels: labels,
          goal: goal,
          maxVal: displayMax,
          barColor: color,
          context: context,
        ),
      ),
    );
  }
}

class _StepChartPainter extends CustomPainter {
  final List<double> values;
  final List<String> labels;
  final double goal;
  final double maxVal;
  final Color barColor;
  final BuildContext context;

  _StepChartPainter({
    required this.values,
    required this.labels,
    required this.goal,
    required this.maxVal,
    required this.barColor,
    required this.context,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final barCount = values.length;
    if (barCount == 0) return;

    final totalPadding = barCount * 8.0;
    final barWidth = (size.width - totalPadding) / barCount;
    final chartHeight = size.height - 30;

    final goalPaint = Paint()
      ..color = AppTheme.textTertiary(context).withValues(alpha: 0.3)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final goalY = chartHeight - (goal / maxVal * chartHeight);
    canvas.drawLine(
      Offset(0, goalY),
      Offset(size.width, goalY),
      goalPaint,
    );

    final goalTextPainter = TextPainter(
      text: TextSpan(
        text: '${(goal / 1000).round()}k',
        style: TextStyle(
          color: AppTheme.textTertiary(context),
          fontSize: 9,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    goalTextPainter.paint(canvas, Offset(size.width - goalTextPainter.width - 2, goalY - 12));

    for (int i = 0; i < barCount; i++) {
      final x = i * (barWidth + 8) + 4;
      final barHeight = maxVal > 0 ? (values[i] / maxVal * chartHeight) : 0.0;
      final y = chartHeight - barHeight;

      final reached = values[i] >= goal;
      final barPaint = Paint()
        ..color = reached ? AppTheme.achievementGreen : barColor
        ..style = PaintingStyle.fill;

      final rrect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, barWidth, barHeight),
        const Radius.circular(4),
      );
      canvas.drawRRect(rrect, barPaint);

      if (i < labels.length) {
        final labelPainter = TextPainter(
          text: TextSpan(
            text: labels[i],
            style: TextStyle(
              color: AppTheme.textTertiary(context),
              fontSize: 9,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        labelPainter.paint(
          canvas,
          Offset(x + (barWidth - labelPainter.width) / 2, chartHeight + 6),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _StepChartPainter oldDelegate) {
    return oldDelegate.values != values ||
        oldDelegate.goal != goal ||
        oldDelegate.maxVal != maxVal;
  }
}
