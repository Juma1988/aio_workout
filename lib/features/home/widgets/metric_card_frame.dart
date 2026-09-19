import 'package:flutter/material.dart';

const double kMetricCardHeight = 220;
const double kMetricBodyHeight = 120;
const EdgeInsets kMetricPadding = EdgeInsets.fromLTRB(18, 18, 18, 20);

class MetricCardFrame extends StatelessWidget {
  final Widget child;
  final Color? accentColor;

  const MetricCardFrame({super.key, required this.child, this.accentColor});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: accentColor != null
            ? BoxDecoration(
                border: Border.all(
                  color: accentColor!.withValues(alpha: 0.15),
                  width: 1,
                ),
              )
            : null,
        child: SizedBox.expand(
          child: Padding(
            padding: kMetricPadding,
            child: child,
          ),
        ),
      ),
    );
  }
}
