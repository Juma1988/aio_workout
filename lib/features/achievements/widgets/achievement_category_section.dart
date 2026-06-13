import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../../data/exercise_localizer.dart';
import '../models/achievement_category.dart';
import '../models/achievement_result.dart';
import 'achievement_list_tile.dart';

class AchievementCategorySection extends StatelessWidget {
  final AchievementCategory category;
  final List<AchievementResult> results;
  final int unlockedCount;
  final int totalCount;
  final void Function(AchievementResult)? onTileTap;

  const AchievementCategorySection({
    super.key,
    required this.category,
    required this.results,
    required this.unlockedCount,
    required this.totalCount,
    this.onTileTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final color = category.color;
    final ratio = totalCount > 0 ? unlockedCount / totalCount : 0.0;
    final displayLabel = ExerciseLocalizer.focusName(l10n, category.label);

    return Semantics(
      headingLevel: 2,
      label: '$displayLabel: $unlockedCount of $totalCount unlocked',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.only(start: 4, bottom: 8),
            child: Row(
              children: [
                Icon(category.icon, color: color, size: 18),
                const SizedBox(width: 8),
                Text(
                  displayLabel,
                  style: TextStyle(
                    color: AppTheme.textPrimary(context),
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                const Spacer(),
                SizedBox(
                  width: 34,
                  height: 34,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: ratio,
                        strokeWidth: 3,
                        backgroundColor: AppTheme.subtleFill(context, 0.1),
                        color: color,
                      ),
                      Text(
                        '$unlockedCount',
                        style: TextStyle(
                          color: color,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          ...List.generate(results.length, (i) {
            return Padding(
              padding: EdgeInsets.only(bottom: i < results.length - 1 ? 6 : 0),
              child: AchievementListTile(
                result: results[i],
                onTap: onTileTap != null
                    ? () => onTileTap!(results[i])
                    : null,
              ),
            );
          }),
        ],
      ),
    );
  }
}
