import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class TopAction extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final String semanticsLabel;

  const TopAction({
    super.key,
    required this.icon,
    this.onTap,
    this.semanticsLabel = '',
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticsLabel,
      child: Material(
        color: AppTheme.topActionBackground(context),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            width: 42,
            height: 42,
            child: Icon(icon, size: 20, color: AppTheme.textSecondary(context)),
          ),
        ),
      ),
    );
  }
}
