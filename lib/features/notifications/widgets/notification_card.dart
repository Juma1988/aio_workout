import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/colored_icon_box.dart';
import '../../../core/widgets/directional_icon.dart';

class NotificationCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final Color iconColor;
  final bool isEnabled;
  final bool hasSettings;
  final VoidCallback? onTap;

  const NotificationCard({
    super.key,
    required this.title,
    this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.isEnabled,
    this.hasSettings = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Theme.of(context)
              .colorScheme
              .primary
              .withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      elevation: 0,
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap != null
            ? () {
                HapticFeedback.lightImpact();
                onTap!();
              }
            : null,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 72),
          child: Padding(
            padding: const EdgeInsetsDirectional.only(
              start: 16,
              end: 16,
            ),
            child: Row(
              children: [
                ColoredIconBox(
                  icon: icon,
                  color: iconColor,
                  size: 36,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: AppTheme.textPrimary(context),
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if ((subtitle ?? '').isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            subtitle ?? '',
                            style: TextStyle(
                              color: AppTheme.textTertiary(context),
                              fontSize: 13,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                if (isEnabled)
                  Container(
                    margin: const EdgeInsetsDirectional.only(end: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.achievementGreen.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      'ON',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.achievementGreen,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                if (hasSettings)
                  DirectionalIcon(
                    icon: Icons.chevron_right,
                    size: 20,
                    color: AppTheme.textTertiary(context),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
