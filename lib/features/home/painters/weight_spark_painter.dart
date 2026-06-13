import 'package:flutter/material.dart';

import '../../../data/weight_entry.dart';

class WeightSparkPainter extends CustomPainter {
  final List<WeightEntry> entries;
  final Color lineColor;
  final double animationValue;

  WeightSparkPainter({
    required this.entries,
    required this.lineColor,
    required this.animationValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (entries.isEmpty) return;

    final weights = entries.map((e) => e.weightKg).toList();
    final minW = weights.reduce((a, b) => a < b ? a : b) - 0.5;
    final maxW = weights.reduce((a, b) => a > b ? a : b) + 0.5;
    final range = maxW - minW;
    if (range == 0) return;

    final padding = const EdgeInsets.symmetric(horizontal: 4, vertical: 4);
    final chartW = size.width - padding.left - padding.right;
    final chartH = size.height - padding.top - padding.bottom;
    final count = entries.length;

    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    for (int i = 0; i < count; i++) {
      final x = padding.left + (i / (count - 1)) * chartW * animationValue;
      final y = padding.top + chartH - ((entries[i].weightKg - minW) / range) * chartH;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, paint);

    if (animationValue > 0.99) {
      final lastIdx = count - 1;
      final lx = padding.left + (lastIdx / (count - 1)) * chartW;
      final ly = padding.top + chartH - ((entries[lastIdx].weightKg - minW) / range) * chartH;
      canvas.drawCircle(Offset(lx, ly), 4.0, paint);
    }
  }

  @override
  bool shouldRepaint(WeightSparkPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.entries.length != entries.length ||
        (entries.isNotEmpty && oldDelegate.entries.first != entries.first) ||
        (entries.isNotEmpty && oldDelegate.entries.last != entries.last);
  }
}
