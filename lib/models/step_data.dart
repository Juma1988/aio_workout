class StepEntry {
  final String date;
  final int steps;
  final double distanceKm;
  final int caloriesBurned;

  const StepEntry({
    required this.date,
    required this.steps,
    this.distanceKm = 0.0,
    this.caloriesBurned = 0,
  });

  Map<String, dynamic> toJson() => {
    'date': date,
    'steps': steps,
    'distanceKm': distanceKm,
    'caloriesBurned': caloriesBurned,
  };

  factory StepEntry.fromJson(Map<String, dynamic> json) => StepEntry(
    date: json['date'] as String,
    steps: json['steps'] as int,
    distanceKm: (json['distanceKm'] as num?)?.toDouble() ?? 0.0,
    caloriesBurned: json['caloriesBurned'] as int? ?? 0,
  );

  static double stepsToDistanceKm(int steps) => steps * 0.000762;

  static int stepsToCalories(int steps) => (steps * 0.04).round();
}

class DailyStepSummary {
  final String date;
  final int steps;
  final double distanceKm;
  final int caloriesBurned;
  final double goalProgress;

  const DailyStepSummary({
    required this.date,
    required this.steps,
    required this.distanceKm,
    required this.caloriesBurned,
    required this.goalProgress,
  });
}

class WeeklyStepData {
  final List<DailyStepSummary> days;
  final int totalSteps;
  final double totalDistanceKm;
  final int totalCaloriesBurned;
  final double averageSteps;

  const WeeklyStepData({
    required this.days,
    required this.totalSteps,
    required this.totalDistanceKm,
    required this.totalCaloriesBurned,
    required this.averageSteps,
  });
}

class MonthlyStepData {
  final List<WeeklyStepData> weeks;
  final int totalSteps;
  final double totalDistanceKm;
  final int totalCaloriesBurned;
  final double averageSteps;
  final int activeDays;

  const MonthlyStepData({
    required this.weeks,
    required this.totalSteps,
    required this.totalDistanceKm,
    required this.totalCaloriesBurned,
    required this.averageSteps,
    required this.activeDays,
  });
}
