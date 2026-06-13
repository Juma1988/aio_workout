import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';
import '../models/achievement_result.dart';

class AchievementListTile extends StatelessWidget {
  final AchievementResult result;
  final VoidCallback? onTap;

  const AchievementListTile({
    super.key,
    required this.result,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isUnlocked = result.isUnlocked;
    final isHidden = result.definition.isHidden && !isUnlocked;
    final def = result.definition;
    final catColor = def.category.color;
    final catIcon = def.category.icon;
    final color = isUnlocked
        ? catColor
        : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38);
    final bgColor = isUnlocked
        ? catColor.withValues(alpha: 0.12)
        : Theme.of(context).brightness == Brightness.dark
            ? Colors.white.withValues(alpha: 0.06)
            : Colors.black.withValues(alpha: 0.06);

    final displayTitle = isHidden ? '???' : def.localizedTitle(l10n);
    final displayLabel = isHidden ? '' : def.localizedProgressLabel(l10n);

    return Semantics(
      label: isHidden
          ? 'Hidden achievement'
          : '$displayTitle: ${isUnlocked ? "unlocked" : "locked"}'
              '${!isUnlocked ? ". ${result.progress?.display ?? ""} $displayLabel" : ""}',
      button: true,
      child: Card(
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(
            color: isUnlocked
                ? catColor.withValues(alpha: 0.25)
                : bgColor,
            width: 1,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isUnlocked
                        ? catColor.withValues(alpha: 0.15)
                        : bgColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    isHidden ? Icons.help_outline : catIcon,
                    color: color,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        displayTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: isUnlocked
                              ? Theme.of(context).colorScheme.onSurface
                              : isHidden
                                  ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38)
                                  : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.70),
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      _buildProgressBar(context, isUnlocked, isHidden, catColor),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (isUnlocked)
                  Icon(Icons.check_circle_rounded, color: catColor, size: 20)
                else if (!isHidden)
                  Text(
                    result.progress?.display ?? "0",
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressBar(BuildContext context, bool isUnlocked, bool isHidden, Color catColor) {
    final subtle06 = Theme.of(context).brightness == Brightness.dark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.black.withValues(alpha: 0.06);

    if (isUnlocked) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(3),
        child: LinearProgressIndicator(
          value: 1.0,
          backgroundColor: catColor.withValues(alpha: 0.15),
          color: catColor,
          minHeight: 4,
        ),
      );
    }
    if (isHidden) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(3),
        child: LinearProgressIndicator(
          value: 0.0,
          backgroundColor: subtle06,
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38),
          minHeight: 4,
        ),
      );
    }
    final progressFraction = result.progressFraction;
    return ClipRRect(
      borderRadius: BorderRadius.circular(3),
      child: LinearProgressIndicator(
        value: progressFraction,
        backgroundColor: subtle06,
        color: _progressColor(progressFraction),
        minHeight: 4,
      ),
    );
  }

  Color _progressColor(double fraction) {
    if (fraction >= 1.0) return const Color(0xFF22C55E);
    if (fraction >= 0.75) return const Color(0xFF3B82F6);
    if (fraction >= 0.5) return const Color(0xFFF97316);
    return const Color(0xFF9CA3AF);
  }
}
