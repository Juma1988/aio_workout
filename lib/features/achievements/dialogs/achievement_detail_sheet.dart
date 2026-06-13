import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../../data/exercise_localizer.dart';
import '../models/achievement_result.dart';

class AchievementDetailSheet extends StatelessWidget {
  final AchievementResult result;

  const AchievementDetailSheet({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final def = result.definition;
    final catColor = def.category.color;
    final isUnlocked = result.isUnlocked;

    final displayTitle = def.localizedTitle(l10n);
    final displayDescription = def.localizedDescription(l10n);

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.subtleFill(context, 0.30),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: isUnlocked
                  ? catColor.withValues(alpha: 0.15)
                  : AppTheme.subtleFill(context, 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isUnlocked ? def.category.icon : Icons.lock_outline,
              color: isUnlocked ? catColor : AppTheme.textDisabled(context),
              size: 32,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            displayTitle,
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            displayDescription,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppTheme.textSecondary(context),
              fontSize: 14,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          _buildCategoryChip(
              context, ExerciseLocalizer.focusName(l10n, def.category.label),
              catColor),
          const SizedBox(height: 20),
          if (isUnlocked && result.unlockedAt != null)
            _buildUnlockedInfo(context, result.unlockedAt!)
          else if (result.progress != null)
            _buildProgressSection(context),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text('Close'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(BuildContext context, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildUnlockedInfo(BuildContext context, DateTime unlockedAt) {
    final diff = DateTime.now().difference(unlockedAt);
    String ago;
    if (diff.inDays > 0) {
      ago = '${diff.inDays}d ago';
    } else if (diff.inHours > 0) {
      ago = '${diff.inHours}h ago';
    } else if (diff.inMinutes > 0) {
      ago = '${diff.inMinutes}m ago';
    } else {
      ago = 'Just now';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.achievementGreen.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_rounded,
              color: AppTheme.achievementGreen, size: 18),
          const SizedBox(width: 8),
          Text(
            'Unlocked $ago',
            style: TextStyle(
              color: AppTheme.achievementGreen,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressSection(BuildContext context) {
    final progress = result.progress!;
    final l10n = AppLocalizations.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress.fraction,
            backgroundColor: AppTheme.subtleFill(context, 0.1),
            color: result.definition.category.color,
            minHeight: 6,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${progress.display} ${result.definition.localizedProgressLabel(l10n)}',
          style: TextStyle(
            color: AppTheme.textSecondary(context),
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}
