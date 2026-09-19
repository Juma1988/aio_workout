import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../dialogs/achivment_dialog.dart';
import '../../achievements/providers/achievement_provider.dart';
import 'metric_card_frame.dart';
import 'metric_header.dart';
import 'progress_ring.dart';

class AchievementMetricCard extends StatelessWidget {
  const AchievementMetricCard({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final provider = context.watch<AchievementProvider>();
    final green = AppTheme.achievementGreen;
    final count = provider.unlockedCount;
    final total = provider.totalCount;
    final progress = total > 0 ? count / total : 0.0;
    final latest = provider.results
        .where((r) => r.isUnlocked)
        .toList()
        .lastOrNull
        ?.definition
        .localizedTitle(l10n);
    final closest = provider.closestToUnlock;

    return Semantics(
      label: 'Achievements: $count of $total unlocked',
      button: true,
      child: MetricCardFrame(
        accentColor: green,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const AchievementsDialog(),
              ),
            );
          },
          borderRadius: BorderRadius.circular(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MetricHeader(
                icon: Icons.emoji_events_rounded,
                title: l10n.dialog_achievementsTitle,
                iconColor: green,
                trailing: Text(
                  '$count / $total',
                  style: TextStyle(
                    color: green,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            latest != null && latest.isNotEmpty
                                ? latest
                                : l10n.dialog_achievementsTitle,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: AppTheme.textPrimary(context),
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 6),
                          if (closest != null && !closest.isUnlocked)
                            Text(
                              closest.definition.localizedTitle(l10n),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: AppTheme.textTertiary(context),
                                fontSize: 13,
                              ),
                            )
                          else
                            Text(
                              '$count unlocked',
                              style: TextStyle(
                                color: AppTheme.textTertiary(context),
                                fontSize: 13,
                              ),
                            ),
                          const SizedBox(height: 10),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: progress.clamp(0.0, 1.0),
                              minHeight: 8,
                              backgroundColor: AppTheme.subtleFill(context),
                              color: green,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    ProgressRing(
                      progress: progress,
                      centerLabel: '${(progress * 100).round()}%',
                      bottomLabel: l10n.dialog_achievementsUnlocked,
                      color: green,
                      size: 76,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                latest != null ? 'Latest: $latest' : '',
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
      ),
    );
  }
}
