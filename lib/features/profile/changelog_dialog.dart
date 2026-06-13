import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_theme.dart';
import '../../data/changelog.dart';

/// Shows the full update history from `The Plan.md`.
///
/// Every entry in [changelog] is rendered as a card with date, title,
/// and description. Newest entries appear first.
void showChangelogDialog(BuildContext context) {
  HapticFeedback.lightImpact();
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => const _ChangelogSheet(),
  );
}

class _ChangelogSheet extends StatelessWidget {
  const _ChangelogSheet();

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d, yyyy');

    return DraggableScrollableSheet(
      initialChildSize: 0.72,
      minChildSize: 0.40,
      maxChildSize: 0.92,
      expand: false,
      builder: (context, scrollController) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(
            children: [
              // Drag handle
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.subtleFill(context, 0.30),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),

              // Title row
              Row(
                children: [
                  Icon(
                    Icons.update_rounded,
                    color: AppTheme.textPrimary(context),
                    size: 24,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Log & Updates',
                    style: TextStyle(
                      color: AppTheme.textPrimary(context),
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${changelog.length} entries',
                    style: TextStyle(
                      color: AppTheme.textTertiary(context),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Every feature, fix, and improvement we ship is logged '
                'here and in The Plan.md — our living changelog.',
                style: TextStyle(
                  color: AppTheme.textSecondary(context),
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),

              // Scrollable entry list
              Expanded(
                child: ListView.separated(
                  controller: scrollController,
                  physics: const BouncingScrollPhysics(),
                  itemCount: changelog.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final entry = changelog[index];
                    return _EntryCard(
                      date: dateFormat.format(entry.date),
                      title: entry.title,
                      description: entry.description,
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _EntryCard extends StatelessWidget {
  final String date;
  final String title;
  final String description;

  const _EntryCard({
    required this.date,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.cardColor(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppTheme.subtleFill(context, 0.12),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  date,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              color: AppTheme.textPrimary(context),
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: TextStyle(
              color: AppTheme.textSecondary(context),
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
