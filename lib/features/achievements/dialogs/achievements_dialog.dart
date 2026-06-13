import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/exercise_localizer.dart';
import '../../../l10n/app_localizations.dart';
import '../models/achievement_category.dart';
import '../models/achievement_result.dart';
import '../providers/achievement_provider.dart';
import '../widgets/achievement_category_section.dart';
import 'achievement_detail_sheet.dart';

class AchievementsDialog extends StatefulWidget {
  const AchievementsDialog({super.key});

  @override
  State<AchievementsDialog> createState() => _AchievementsDialogState();
}

class _AchievementsDialogState extends State<AchievementsDialog>
    with SingleTickerProviderStateMixin {
  Set<AchievementCategory> _selectedCategories = {};
  late AnimationController _staggerController;

  AchievementCategory? get _activeFilter =>
      _selectedCategories.length == 1 ? _selectedCategories.first : null;

  @override
  void initState() {
    super.initState();
    _staggerController = AnimationController(
      vsync: this,
      duration: AppTheme.kAnimEntrance,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _staggerController.forward();
  }

  @override
  void dispose() {
    _staggerController.dispose();
    super.dispose();
  }

  void _toggleFilter(AchievementCategory cat) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_selectedCategories.contains(cat)) {
        _selectedCategories.remove(cat);
      } else {
        _selectedCategories = {cat};
      }
    });
  }

  void _showDetail(BuildContext context, AchievementResult result) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => AchievementDetailSheet(result: result),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final provider = context.watch<AchievementProvider>();
    final allResults = provider.results;
    final unlockedCount = provider.unlockedCount;
    final totalCount = provider.totalCount;

    final filtered = _activeFilter != null
        ? provider.resultsFor(_activeFilter!)
        : allResults;
    final sections = AchievementCategory.values.map((cat) {
      final catResults = _activeFilter != null
          ? filtered.where((r) => r.definition.category == cat).toList()
          : provider.resultsFor(cat);
      return (cat, catResults);
    }).where((e) => e.$2.isNotEmpty).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.dialog_achievementsTitle),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          _buildHeader(context, unlockedCount, totalCount),
          _buildFilterChips(context, l10n),
          Expanded(
            child: filtered.isEmpty
                ? _buildEmptyState(context)
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    itemCount: sections.length,
                    itemBuilder: (context, index) {
                      final (cat, results) = sections[index];
                      final catUnlocked = _activeFilter != null
                          ? results.where((r) => r.isUnlocked).length
                          : provider.unlockedFor(cat);
                      final catTotal = _activeFilter != null
                          ? results.length
                          : provider.totalFor(cat);
                      return Padding(
                        padding: EdgeInsets.only(top: index > 0 ? 8 : 0),
                        child: AchievementCategorySection(
                          category: cat,
                          results: results,
                          unlockedCount: catUnlocked,
                          totalCount: catTotal,
                          onTileTap: (r) => _showDetail(context, r),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, int unlocked, int total) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
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
          const SizedBox(height: 8),
          SizedBox(
            width: 160,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 160,
                  height: 160,
                  child: CircularProgressIndicator(
                    value: total > 0 ? unlocked / total : 0.0,
                    strokeWidth: 6,
                    backgroundColor: AppTheme.subtleFill(context, 0.1),
                    color: AppTheme.achievementGreen,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$unlocked / $total',
                      style: TextStyle(
                        color: AppTheme.achievementGreen,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        height: 1.0,
                      ),
                    ),
                    Text(
                      l10n.dialog_achievementsUnlocked,
                      style: TextStyle(
                        color: AppTheme.textSecondary(context),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips(BuildContext context, AppLocalizations l10n) {
    final cats = AchievementCategory.values;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _filterChip(context, l10n.dialog_allFilter, null, _activeFilter == null),
            const SizedBox(width: 8),
            ...cats.map((cat) => Padding(
                  padding: const EdgeInsetsDirectional.only(end: 8),
                  child: _filterChip(
                    context,
                    ExerciseLocalizer.focusName(l10n, cat.label),
                    cat,
                    _selectedCategories.contains(cat),
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(
      BuildContext context, String label, AchievementCategory? cat, bool selected) {
    final color = cat?.color ?? AppTheme.achievementGreen;
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) {
        if (cat != null) {
          _toggleFilter(cat);
        } else {
          setState(() => _selectedCategories = {});
        }
      },
      selectedColor: color.withValues(alpha: 0.2),
      checkmarkColor: color,
      labelStyle: TextStyle(
        color: selected ? color : AppTheme.textPrimary(context),
        fontWeight: FontWeight.w500,
        fontSize: 13,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: selected
              ? color.withValues(alpha: 0.4)
              : AppTheme.subtleFill(context, 0.2),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off, size: 48,
              color: AppTheme.textDisabled(context)),
          const SizedBox(height: 12),
          Text(
            l10n.dialog_noAchievements,
            style: TextStyle(
              color: AppTheme.textSecondary(context),
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}
