import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';
import '../models/achievement_result.dart';

class AchievementTileGrid extends StatelessWidget {
  final AchievementResult result;
  final VoidCallback? onTap;

  const AchievementTileGrid({
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
    final color = isUnlocked
        ? catColor
        : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38);
    final bgColor = isUnlocked
        ? catColor.withValues(alpha: 0.12)
        : Theme.of(context).brightness == Brightness.dark
            ? Colors.white.withValues(alpha: 0.06)
            : Colors.black.withValues(alpha: 0.06);
    final subtle06 = Theme.of(context).brightness == Brightness.dark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.black.withValues(alpha: 0.06);
    final subtle08 = Theme.of(context).brightness == Brightness.dark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.08);

    final displayTitle = isHidden ? '???' : def.localizedTitle(l10n);
    final displayLabel = isHidden ? '' : def.localizedProgressLabel(l10n);

    return Semantics(
      label: isHidden
          ? 'Hidden achievement'
          : '$displayTitle: ${isUnlocked ? "unlocked" : "locked"}'
              '${!isUnlocked ? ". ${result.progress?.display ?? ""} $displayLabel" : ""}',
      button: true,
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isUnlocked
                ? catColor.withValues(alpha: 0.25)
                : subtle06,
            width: 1,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHeader(context, isUnlocked, isHidden, def, color, bgColor),
                const SizedBox(height: 8),
                _buildTitle(context, isUnlocked, isHidden, def, displayTitle),
                const SizedBox(height: 6),
                _buildProgressBar(context, isUnlocked, isHidden, catColor, subtle06, subtle08),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isUnlocked, bool isHidden,
      dynamic def, Color color, Color bgColor) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            isHidden ? Icons.help_outline : def.icon,
            color: color,
            size: 20,
          ),
        ),
        const Spacer(),
        if (isUnlocked)
          Icon(Icons.check_circle_rounded, color: color, size: 18)
        else if (!isHidden)
          Text(
            result.progress?.display ?? "0",
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
      ],
    );
  }

  Widget _buildTitle(BuildContext context, bool isUnlocked, bool isHidden,
      dynamic def, String displayTitle) {
    return Text(
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
        fontSize: 13,
      ),
    );
  }

  Widget _buildProgressBar(BuildContext context, bool isUnlocked, bool isHidden,
      Color catColor, Color subtle06, Color subtle08) {
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
    final barColor = _progressColor(progressFraction);
    return ClipRRect(
      borderRadius: BorderRadius.circular(3),
      child: LinearProgressIndicator(
        value: progressFraction,
        backgroundColor: subtle08,
        color: barColor,
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
