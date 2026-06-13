import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/directional_icon.dart';
import '../../../l10n/app_localizations.dart';
import '../models/achievement_result.dart';
import 'achievement_badge.dart';

class AchievementPreviewCard extends StatelessWidget {
  final int count;
  final int totalCount;
  final String? latestAchievement;
  final AchievementResult? closest;
  final Map<String, int> categoryState;
  final VoidCallback onTap;

  const AchievementPreviewCard({
    super.key,
    required this.count,
    required this.totalCount,
    this.latestAchievement,
    this.closest,
    required this.categoryState,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final green = AppTheme.achievementGreen;
    final l10n = AppLocalizations.of(context);

    return Semantics(
      label: 'Achievements: $count of $totalCount unlocked. '
          '${latestAchievement != null ? "Latest: $latestAchievement" : ""}',
      button: true,
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: green.withValues(alpha: 0.25), width: 1),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            HapticFeedback.lightImpact();
            onTap();
          },
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHeaderRow(context),
                if (closest != null && !closest!.isUnlocked)
                  _buildClosestProgress(context, l10n),
                const SizedBox(height: 8),
                _buildCategoryDots(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderRow(BuildContext context) {
    return Row(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.achievementGreen.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(10),
              ),
              child:
                  const Icon(Icons.emoji_events, color: AppTheme.achievementGreen, size: 24),
            ),
            if (count > 0)
              Positioned(
                top: -4,
                right: -4,
                child: AchievementBadge(count: count, size: 16),
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Achievements',
                style: TextStyle(
                  color: AppTheme.achievementGreen,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              Text(
                '$count / $totalCount unlocked',
                style: TextStyle(
                  color: AppTheme.textPrimary(context),
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                ),
              ),
              if (latestAchievement != null && latestAchievement!.isNotEmpty)
                Text(
                  'Latest: $latestAchievement',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppTheme.textTertiary(context),
                    fontSize: 12,
                  ),
                ),
            ],
          ),
        ),
        DirectionalIcon(
          icon: Icons.chevron_right,
          color: AppTheme.textDisabled(context),
          size: 20,
        ),
      ],
    );
  }

  Widget _buildClosestProgress(BuildContext context, AppLocalizations l10n) {
    final fraction = closest!.progressFraction;

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.trending_up,
                  size: 14, color: AppTheme.textTertiary(context)),
              const SizedBox(width: 4),
              Text(
                'Next: ${closest!.definition.localizedTitle(l10n)}',
                style: TextStyle(
                  color: AppTheme.textTertiary(context),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Text(
                '${(fraction * 100).round()}%',
                style: TextStyle(
                  color: AppTheme.stepsOrange,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: fraction,
              backgroundColor: AppTheme.subtleFill(context, 0.1),
              color: AppTheme.stepsOrange,
              minHeight: 4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryDots(BuildContext context) {
    final cats = categoryState.entries.toList();
    return Row(
      children: cats.map((e) {
        final filled = e.value > 0;
        final catLabel = e.key;
        return Padding(
          padding: const EdgeInsetsDirectional.only(end: 6),
          child: Semantics(
            label: '$catLabel: ${e.value} unlocked',
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: filled
                    ? _catColor(catLabel).withValues(alpha: 0.8)
                    : AppTheme.subtleFill(context, 0.15),
                border: filled
                    ? null
                    : Border.all(
                        color: AppTheme.subtleFill(context, 0.2), width: 1),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Color _catColor(String label) {
    switch (label) {
      case 'Workout':
        return const Color(0xFF22C55E);
      case 'Consistency':
        return const Color(0xFFF59E0B);
      case 'Steps':
        return const Color(0xFFF97316);
      case 'Hydration':
        return const Color(0xFF3B82F6);
      case 'Weight':
        return const Color(0xFFA855F7);
      case 'Special':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF9CA3AF);
    }
  }
}
