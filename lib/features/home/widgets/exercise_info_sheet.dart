import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/exercise.dart';

class ExerciseInfoSheet extends StatelessWidget {
  final Exercise exercise;

  const ExerciseInfoSheet({super.key, required this.exercise});

  @override
  Widget build(BuildContext context) {
    final cat = exercise.category;
    final muscle = exercise.targetMuscle;
    final lvlColor = exercise.recommendedLevel.color;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.subtleFill(context, 0.30),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            exercise.name,
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          if (exercise.description != null && exercise.description!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                exercise.description!,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppTheme.textSecondary(context),
                  height: 1.5,
                ),
              ),
            ),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              _pill(context, exercise.recommendedLevel.label, lvlColor),
              _pill(context, muscle.label, muscle.color),
              _pill(context, cat.label, cat.color),
            ],
          ),
          if (exercise.equipment != null && exercise.equipment!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Equipment: ${exercise.equipment}',
                style: TextStyle(color: AppTheme.textTertiary(context)),
              ),
            ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _launchYouTube(context, exercise.name),
              icon: const Icon(Icons.play_circle_outline),
              label: const Text('Watch on YouTube'),
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.4),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _launchYouTube(BuildContext context, String query) async {
    final encoded = Uri.encodeComponent('$query workout');
    final url = 'https://www.youtube.com/results?search_query=$encoded';
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Widget _pill(BuildContext context, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
