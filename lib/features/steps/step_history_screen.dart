import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../models/step_data.dart';
import '../../services/step_history_storage.dart';
import 'widgets/step_chart.dart';
import '../dialogs/step_goal_dialog.dart';

class StepHistoryScreen extends StatefulWidget {
  const StepHistoryScreen({super.key});

  @override
  State<StepHistoryScreen> createState() => _StepHistoryScreenState();
}

class _StepHistoryScreenState extends State<StepHistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final StepHistoryStorage _storage = StepHistoryStorage();

  WeeklyStepData? _weekData;
  MonthlyStepData? _monthData;
  int _dailyGoal = 10000;
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
    final orange = AppTheme.stepsOrange;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.home_steps,
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
            icon: Icon(Icons.flag_outlined, color: orange),
            onPressed: _openGoalDialog,
            tooltip: 'Daily Goal',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: orange,
          unselectedLabelColor: AppTheme.textTertiary(context),
          indicatorColor: orange,
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
    final orange = AppTheme.stepsOrange;

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
            _weekData!.totalSteps.toString(),
            '${(_weekData!.totalDistanceKm).toStringAsFixed(1)} km',
            '${_weekData!.totalCaloriesBurned} kcal',
            '${_weekData!.averageSteps.round()} avg',
          ),
          const SizedBox(height: 24),
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: orange.withValues(alpha: 0.25),
                width: 1,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: StepChart(
                values: _weekData!.days.map((d) => d.steps.toDouble()).toList(),
                labels: dayLabels,
                goal: _dailyGoal.toDouble(),
                color: orange,
              ),
            ),
          ),
          const SizedBox(height: 16),
          ...List.generate(7, (i) {
            final day = _weekData!.days[i];
            final reached = day.steps >= _dailyGoal;
            return _buildDayTile(context, dayLabels[i], day, reached);
          }),
        ],
      ),
    );
  }

  Widget _buildMonthView(BuildContext context) {
    if (_monthData == null) return const Center(child: Text('No data'));
    final orange = AppTheme.stepsOrange;
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
            _monthData!.totalSteps.toString(),
            '${(_monthData!.totalDistanceKm).toStringAsFixed(1)} km',
            '${_monthData!.totalCaloriesBurned} kcal',
            '${_monthData!.activeDays} days',
          ),
          const SizedBox(height: 24),
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: orange.withValues(alpha: 0.25),
                width: 1,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: StepChart(
                values: _monthData!.weeks.map((w) => w.averageSteps).toList(),
                labels: List.generate(_monthData!.weeks.length, (i) => 'W${i + 1}'),
                goal: _dailyGoal.toDouble(),
                color: orange,
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
    String steps,
    String distance,
    String calories,
    String extra,
  ) {
    return Row(
      children: [
        _statItem(context, Icons.directions_run, steps, 'Steps'),
        const SizedBox(width: 8),
        _statItem(context, Icons.straighten, distance, 'Distance'),
        const SizedBox(width: 8),
        _statItem(context, Icons.local_fire_department, calories, 'Calories'),
        const SizedBox(width: 8),
        _statItem(context, Icons.calendar_today, extra, ''),
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
            Icon(icon, size: 16, color: AppTheme.stepsOrange),
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
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDayTile(BuildContext context, String label, DailyStepSummary day, bool reached) {
    final progress = _dailyGoal > 0 ? (day.steps / _dailyGoal).clamp(0.0, 1.0) : 0.0;
    final orange = AppTheme.stepsOrange;

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
                  reached ? AppTheme.achievementGreen : orange,
                ),
                minHeight: 6,
              ),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 60,
            child: Text(
              '${day.steps}',
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
    final orange = AppTheme.stepsOrange;
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: orange.withValues(alpha: 0.25),
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
            _summaryRow(context, 'Total Steps', _monthData!.totalSteps.toString()),
            _summaryRow(context, 'Total Distance', '${_monthData!.totalDistanceKm.toStringAsFixed(1)} km'),
            _summaryRow(context, 'Total Calories', '${_monthData!.totalCaloriesBurned} kcal'),
            _summaryRow(context, 'Daily Average', '${_monthData!.averageSteps.round()} steps'),
            _summaryRow(context, 'Active Days', '${_monthData!.activeDays}'),
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
    final newGoal = await showDialog<int>(
      context: context,
      builder: (_) => StepGoalDialog(currentGoal: _dailyGoal),
    );
    if (newGoal != null && newGoal != _dailyGoal) {
      await _storage.saveDailyGoal(newGoal);
      _dailyGoal = newGoal;
      _loadData();
    }
  }
}
