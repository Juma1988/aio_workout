import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../data/workout_log.dart';
import '../../services/workout_storage_service.dart';

class AchievementsDialog extends StatefulWidget {
  const AchievementsDialog({super.key});

  @override
  State<AchievementsDialog> createState() => _AchievementsDialogState();
}

class _AchievementsDialogState extends State<AchievementsDialog> {
  List<Achievement> _unlocked = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final sessions =
        await WorkoutStorageService().loadSessions();
    final unlocked = evaluateAchievements(sessions);
    if (mounted) {
      setState(() {
        _unlocked = unlocked;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Achievements'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    final unlockedIds = _unlocked.map((a) => a.id).toSet();
    final unlockedCount = unlockedIds.length;
    final totalCount = allAchievementDefinitions.length;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Column(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppTheme.achievementGreen.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.emoji_events,
                    color: AppTheme.achievementGreen,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '$unlockedCount / $totalCount',
                  style: Theme.of(context)
                      .textTheme
                      .headlineMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  'Achievements Unlocked',
                  style: TextStyle(
                    color: AppTheme.textSecondary(context),
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          ...allAchievementDefinitions.map(
            (def) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _buildAchievementTile(
                context,
                def: def,
                isUnlocked: unlockedIds.contains(def.id),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementTile(
    BuildContext context, {
    required AchievementData def,
    required bool isUnlocked,
  }) {
    final color =
        isUnlocked ? AppTheme.achievementGreen : AppTheme.textDisabled(context);

    return Semantics(
      label: '${def.title}: ${isUnlocked ? "unlocked" : "locked"}',
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isUnlocked
                ? AppTheme.achievementGreen.withValues(alpha: 0.25)
                : AppTheme.subtleFill(context, 0.08),
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: isUnlocked
                      ? AppTheme.achievementGreen.withValues(alpha: 0.15)
                      : AppTheme.subtleFill(context, 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isUnlocked ? def.icon : Icons.lock_outline,
                  color: color,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      def.title,
                      style: TextStyle(
                        color: isUnlocked
                            ? AppTheme.textPrimary(context)
                            : AppTheme.textDisabled(context),
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      def.description,
                      style: TextStyle(
                        color: isUnlocked
                            ? AppTheme.textSecondary(context)
                            : AppTheme.textDisabled(context),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                isUnlocked
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked,
                color: color,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
