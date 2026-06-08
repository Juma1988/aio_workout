import 'package:flutter/material.dart';

class ColoredIconBox extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;

  const ColoredIconBox({
    super.key,
    required this.icon,
    required this.color,
    this.size = 36,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: color, size: size * 0.6),
    );
  }
}
