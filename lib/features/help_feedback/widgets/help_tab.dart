import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_theme.dart' as theme;
import '../../../l10n/app_localizations.dart';
import '../../../features/profile/tips_dialog.dart' as tips;
import '../../../features/profile/changelog_dialog.dart' as changelog;
import '../../../features/profile/exersise_dialog.dart';
import '../../../features/notifications/notification_settings_screen.dart';
import 'faq_item.dart';

class _QuickLinkData {
  final IconData icon;
  final Color color;
  final String Function(AppLocalizations) title;
  final String Function(AppLocalizations) subtitle;
  final VoidCallback onTap;
  _QuickLinkData(this.icon, this.color, this.title, this.subtitle, this.onTap);
}

class _FaqData {
  final IconData icon;
  final Color color;
  final String Function(AppLocalizations) question;
  final String Function(AppLocalizations) answer;
  _FaqData(this.icon, this.color, this.question, this.answer);
}

class HelpTab extends StatefulWidget {
  const HelpTab({super.key});

  @override
  State<HelpTab> createState() => _HelpTabState();
}

class _HelpTabState extends State<HelpTab> {
  int _expandedFaqIndex = -1;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildQuickLinks(context, l10n),
          const SizedBox(height: 20),
          _buildFaqSection(context, l10n),
        ],
      ),
    );
  }

  Widget _buildQuickLinks(BuildContext context, AppLocalizations l10n) {
    final links = [
      _QuickLinkData(
        Icons.fitness_center_outlined,
        theme.AppTheme.achievementGreen,
        (l) => l.helpFeedback_exerciseGuide,
        (l) => l.helpFeedback_exerciseGuideDesc,
        () {
          HapticFeedback.lightImpact();
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const ExerciseDialog()),
          );
        },
      ),
      _QuickLinkData(
        Icons.update_rounded,
        theme.AppTheme.achievementGreen,
        (l) => l.helpFeedback_changelog,
        (l) => l.helpFeedback_changelogDesc,
        () => changelog.showChangelogDialog(context),
      ),
      _QuickLinkData(
        Icons.notifications_outlined,
        theme.AppTheme.stepsOrange,
        (l) => l.helpFeedback_notificationTips,
        (l) => l.helpFeedback_notificationTipsDesc,
        () {
          HapticFeedback.lightImpact();
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const NotificationSettingsScreen()),
          );
        },
      ),
      _QuickLinkData(
        Icons.lightbulb_outline,
        Colors.amber.shade700,
        (l) => l.helpFeedback_tips,
        (l) => l.helpFeedback_tipsDesc,
        () => tips.showTipsDialog(context),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.only(start: 4, bottom: 8),
          child: Row(
            children: [
              Icon(Icons.explore_outlined, size: 18, color: theme.AppTheme.textSecondary(context)),
              const SizedBox(width: 8),
              Text(
                l10n.helpFeedback_quickLinks,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
              width: 1,
            ),
          ),
          elevation: 0,
          child: Column(
            children: List.generate(links.length * 2 - 1, (i) {
              if (i.isOdd) {
                return Divider(
                  height: 1,
                  indent: 56,
                  color: theme.AppTheme.subtleFill(context),
                );
              }
              final link = links[i ~/ 2];
              return _buildQuickLinkTile(
                context,
                icon: link.icon,
                title: link.title(l10n),
                subtitle: link.subtitle(l10n),
                color: link.color,
                onTap: link.onTap,
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickLinkTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: theme.AppTheme.textPrimary(context),
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: theme.AppTheme.textTertiary(context),
          fontSize: 12,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: theme.AppTheme.textDisabled(context),
        size: 20,
      ),
      onTap: onTap,
    );
  }

  Widget _buildFaqSection(BuildContext context, AppLocalizations l10n) {
    final faqs = [
      _FaqData(Icons.fitness_center, theme.AppTheme.achievementGreen, (l) => l.faq_howToLogWorkouts, (l) => l.faq_howToLogWorkoutsAnswer),
      _FaqData(Icons.directions_run, theme.AppTheme.stepsOrange, (l) => l.faq_howToTrackSteps, (l) => l.faq_howToTrackStepsAnswer),
      _FaqData(Icons.water_drop, theme.AppTheme.hydrationBlue, (l) => l.faq_howToLogWater, (l) => l.faq_howToLogWaterAnswer),
      _FaqData(Icons.emoji_events, theme.AppTheme.achievementGreen, (l) => l.faq_howAchievementsWork, (l) => l.faq_howAchievementsWorkAnswer),
      _FaqData(Icons.route_outlined, theme.AppTheme.hydrationBlue, (l) => l.faq_howToChangePlan, (l) => l.faq_howToChangePlanAnswer),
      _FaqData(Icons.track_changes, theme.AppTheme.stepsOrange, (l) => l.faq_howToSetGoals, (l) => l.faq_howToSetGoalsAnswer),
      _FaqData(Icons.notifications_active, theme.AppTheme.weightPurple, (l) => l.faq_howNotificationsWork, (l) => l.faq_howNotificationsWorkAnswer),
      _FaqData(Icons.monitor_weight_outlined, theme.AppTheme.weightPurple, (l) => l.faq_howToLogWeight, (l) => l.faq_howToLogWeightAnswer),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.only(start: 4, bottom: 4),
          child: Row(
            children: [
              Icon(Icons.help_outline, size: 18, color: theme.AppTheme.textSecondary(context)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.helpFeedback_faq,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          l10n.helpFeedback_faqSubtitle,
          style: TextStyle(
            color: theme.AppTheme.textTertiary(context),
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 12),
        ...List.generate(faqs.length, (index) {
          final faq = faqs[index];
          return Padding(
            padding: EdgeInsets.only(bottom: index < faqs.length - 1 ? 8 : 0),
            child: FaqItemWidget(
              icon: faq.icon,
              color: faq.color,
              question: faq.question(l10n),
              answer: faq.answer(l10n),
              isExpanded: _expandedFaqIndex == index,
              onToggle: () {
                HapticFeedback.selectionClick();
                setState(() {
                  _expandedFaqIndex = _expandedFaqIndex == index ? -1 : index;
                });
              },
            ),
          );
        }),
        const SizedBox(height: 24),
      ],
    );
  }
}