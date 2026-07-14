import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../models/hydration_data.dart';
import '../../services/hydration_storage.dart';
import '../dialogs/hydration_goal_dialog.dart';
import 'widgets/hydration_chart.dart';

class HydrationHistoryScreen extends StatefulWidget {
  const HydrationHistoryScreen({super.key});

  @override
  State<HydrationHistoryScreen> createState() => _HydrationHistoryScreenState();
}

class _HydrationHistoryScreenState extends State<HydrationHistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final HydrationStorage _storage = HydrationStorage();

  WeeklyHydrationData? _weekData;
  MonthlyHydrationData? _monthData;
  double _dailyGoal = 2.5;
  bool _loading = true;
  DateTime _selectedWeekStart = DateTime.now();
  DateTime _selectedMonth = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    _dailyGoal = await _storage.loadDailyGoal();
    final now = DateTime.now();
    _selectedWeekStart = now.subtract(Duration(days: now.weekday - 1));
    _selectedMonth = now;
    _weekData = await _storage.loadWeekData(referenceDate: _selectedWeekStart.add(const Duration(days: 3)));
    _monthData = await _storage.loadMonthData(referenceDate: _selectedMonth);
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _previousWeek() async {
    _selectedWeekStart = _selectedWeekStart.subtract(const Duration(days: 7));
    _weekData = await _storage.loadWeekData(referenceDate: _selectedWeekStart.add(const Duration(days: 3)));
    if (mounted) setState(() {});
  }

  Future<void> _nextWeek() async {
    final next = _selectedWeekStart.add(const Duration(days: 7));
    if (next.isAfter(DateTime.now())) return;
    _selectedWeekStart = next;
    _weekData = await _storage.loadWeekData(referenceDate: _selectedWeekStart.add(const Duration(days: 3)));
    if (mounted) setState(() {});
  }

  Future<void> _previousMonth() async {
    _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1, 1);
    _monthData = await _storage.loadMonthData(referenceDate: _selectedMonth);
    if (mounted) setState(() {});
  }

  Future<void> _nextMonth() async {
    final next = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 1);
    if (next.isAfter(DateTime.now())) return;
    _selectedMonth = next;
    _monthData = await _storage.loadMonthData(referenceDate: _selectedMonth);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final blue = AppTheme.hydrationBlue;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.home_hydration,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary(context),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: AppTheme.textPrimary(context)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.water_drop_rounded, color: blue),
            onPressed: _openGoalDialog,
            tooltip: 'Daily Goal',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: blue,
          unselectedLabelColor: AppTheme.textTertiary(context),
          indicatorColor: blue,
          tabs: const [
            Tab(text: 'Week'),
            Tab(text: 'Month'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildWeekView(context),
                _buildMonthView(context),
              ],
            ),
    );
  }

  Widget _buildWeekView(BuildContext context) {
    if (_weekData == null) return const Center(child: Text('No data'));
    final blue = AppTheme.hydrationBlue;

    final dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final weekEnd = _selectedWeekStart.add(const Duration(days: 6));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: _previousWeek,
                color: AppTheme.textSecondary(context),
              ),
              Text(
                '${_formatDate(_selectedWeekStart)} - ${_formatDate(weekEnd)}',
                style: TextStyle(
                  color: AppTheme.textPrimary(context),
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: _nextWeek,
                color: AppTheme.textSecondary(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildStatsRow(
            context,
            '${(_weekData!.totalLiters).toStringAsFixed(1)}L',
            '${(_weekData!.averageDailyLiters).toStringAsFixed(1)}L avg',
            '${_weekData!.daysMetGoal}/7 days',
            '${(_weekData!.totalGoalLiters - _weekData!.totalLiters).toStringAsFixed(1)}L remaining',
          ),
          const SizedBox(height: 24),
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: blue.withValues(alpha: 0.25),
                width: 1,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: HydrationChart(
                values: _weekData!.days.map((d) => d.totalLiters).toList(),
                labels: dayLabels,
                goal: _dailyGoal,
                color: blue,
              ),
            ),
          ),
          const SizedBox(height: 16),
          ...List.generate(7, (i) {
            final day = _weekData!.days[i];
            final reached = day.goalProgress >= 1.0;
            return _buildDayTile(context, dayLabels[i], day, reached);
          }),
        ],
      ),
    );
  }

  Widget _buildMonthView(BuildContext context) {
    if (_monthData == null) return const Center(child: Text('No data'));
    final blue = AppTheme.hydrationBlue;
    final monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: _previousMonth,
                color: AppTheme.textSecondary(context),
              ),
              Text(
                '${monthNames[_selectedMonth.month - 1]} ${_selectedMonth.year}',
                style: TextStyle(
                  color: AppTheme.textPrimary(context),
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: _nextMonth,
                color: AppTheme.textSecondary(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildStatsRow(
            context,
            '${(_monthData!.totalLiters).toStringAsFixed(1)}L',
            '${(_monthData!.averageDailyLiters).toStringAsFixed(1)}L avg',
            '${_monthData!.activeDays} days',
            '${_monthData!.daysMetGoal}/${_monthData!.activeDays} met goal',
          ),
          const SizedBox(height: 24),
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: blue.withValues(alpha: 0.25),
                width: 1,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: HydrationChart(
                values: _monthData!.weeks.map((w) => w.averageDailyLiters).toList(),
                labels: List.generate(_monthData!.weeks.length, (i) => 'W${i + 1}'),
                goal: _dailyGoal,
                color: blue,
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildMonthlySummaryCard(context),
        ],
      ),
    );
  }

  Widget _buildStatsRow(
    BuildContext context,
    String total,
    String avg,
    String days,
    String remaining,
  ) {
    return Row(
      children: [
        _statItem(context, Icons.water_drop, total, 'Total'),
        const SizedBox(width: 8),
        _statItem(context, Icons.timeline, avg, 'Daily Avg'),
        const SizedBox(width: 8),
        _statItem(context, Icons.calendar_today, days, 'Days'),
        const SizedBox(width: 8),
        _statItem(context, Icons.add_circle, remaining, 'Remaining'),
      ],
    );
  }

  Widget _statItem(BuildContext context, IconData icon, String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(
          color: AppTheme.subtleFill(context, 0.06),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, size: 16, color: AppTheme.hydrationBlue),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                color: AppTheme.textPrimary(context),
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
            ),
            if (label.isNotEmpty)
              Text(
                label,
                style: TextStyle(
                  color: AppTheme.textTertiary(context),
                  fontSize: 10,
                ),
                textAlign: TextAlign.center,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDayTile(BuildContext context, String label, DailyHydrationSummary day, bool reached) {
    final progress = day.goalProgress;
    final blue = AppTheme.hydrationBlue;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.subtleFill(context, 0.04),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 36,
            child: Text(
              label,
              style: TextStyle(
                color: AppTheme.textTertiary(context),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: AppTheme.subtleFill(context, 0.1),
                valueColor: AlwaysStoppedAnimation<Color>(
                  reached ? AppTheme.achievementGreen : blue,
                ),
                minHeight: 6,
              ),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 60,
            child: Text(
              '${day.totalLiters.toStringAsFixed(1)}L',
              style: TextStyle(
                color: AppTheme.textPrimary(context),
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
              textAlign: TextAlign.right,
            ),
          ),
          const SizedBox(width: 8),
          if (reached)
            Icon(Icons.check_circle, size: 16, color: AppTheme.achievementGreen)
          else
            Icon(Icons.circle_outlined, size: 16, color: AppTheme.textDisabled(context)),
        ],
      ),
    );
  }

  Widget _buildMonthlySummaryCard(BuildContext context) {
    final blue = AppTheme.hydrationBlue;
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: blue.withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Monthly Summary',
              style: TextStyle(
                color: AppTheme.textPrimary(context),
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 12),
            _summaryRow(context, 'Total Liters', '${_monthData!.totalLiters.toStringAsFixed(1)}L'),
            _summaryRow(context, 'Goal Met', '${_monthData!.daysMetGoal} days'),
            _summaryRow(context, 'Active Days', '${_monthData!.activeDays}'),
            _summaryRow(context, 'Daily Average', '${_monthData!.averageDailyLiters.toStringAsFixed(1)}L'),
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: AppTheme.textSecondary(context),
              fontSize: 13,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: AppTheme.textPrimary(context),
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}';
  }

  Future<void> _openGoalDialog() async {
    HapticFeedback.lightImpact();
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    final weight = prefs.getDouble('profile_weight_kg');
    final result = await showHydrationGoalDialog(
      context,
      currentGoalLiters: _dailyGoal,
      isAutoCalculated: false,
      weightKg: weight,
    );
    if (result != null && result.$1 != _dailyGoal) {
      await _storage.saveDailyGoal(result.$1);
      _dailyGoal = result.$1;
      _loadData();
    }
  }
}
