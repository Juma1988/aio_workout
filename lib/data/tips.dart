import 'dart:math';
import 'package:flutter/material.dart';

class TipCategory {
  final String id;
  final String title;
  final IconData icon;
  final Color color;
  final List<String> tips;

  const TipCategory({
    required this.id,
    required this.title,
    required this.icon,
    required this.color,
    required this.tips,
  });
}

final List<TipCategory> tipCategories = [
  TipCategory(
    id: 'water',
    title: 'Drinking Water',
    icon: Icons.water_drop_rounded,
    color: const Color(0xFF3B82F6),
    tips: [
      'Multiply your body weight (kg) by 0.035 to calculate your daily water goal in liters.',
      'The danger isn\'t just how much you drink, but how fast you drink it — sip steadily throughout the day.',
      'Drink a glass of water first thing in the morning to kickstart your metabolism after a night of fasting.',
      'Feeling hungry? Drink water first — thirst is often mistaken for hunger by the brain.',
      'Dark yellow urine means you\'re dehydrated; pale straw means you\'re well hydrated.',
    ],
  ),
  TipCategory(
    id: 'steps',
    title: 'Steps',
    icon: Icons.directions_walk_rounded,
    color: const Color(0xFFF97316),
    tips: [
      'The 10,000 steps goal originated as a 1960s Japanese marketing campaign, not science — but it\'s still a great target.',
      'Walking after meals — even 5 minutes — helps regulate blood sugar and aids digestion.',
      'Take the stairs instead of the elevator. Just 3 minutes of stair climbing burns ~30 calories.',
      'Park farther from the entrance. Those extra 100 steps each way add up to over a mile per week.',
      'Use a standing desk with a walking pad — you can easily add 5,000 steps during a workday.',
    ],
  ),
  TipCategory(
    id: 'rest',
    title: 'Rest Days',
    icon: Icons.bedtime_rounded,
    color: const Color(0xFFA855F7),
    tips: [
      'Muscles grow during rest, not during workouts — recovery is when tissue repair and growth happen.',
      'Active recovery (light walking, stretching, yoga) is more effective than complete rest for reducing soreness.',
      'Sleep is the most powerful recovery tool — aim for 7-9 hours for optimal muscle repair and hormone regulation.',
      'Overtraining symptoms include persistent fatigue, irritability, decreased performance, and frequent illness.',
      'Schedule at least 2 rest days per week — your nervous system needs recovery as much as your muscles.',
    ],
  ),
  TipCategory(
    id: 'workouts',
    title: 'Workouts',
    icon: Icons.fitness_center_rounded,
    color: const Color(0xFF22C55E),
    tips: [
      'Form over weight every time — poor form with heavy weights leads to injury, not gains.',
      'Progressive overload is the key to growth: gradually increase weight, reps, or sets every 1-2 weeks.',
      'Always warm up for 5-10 minutes before exercise — cold muscles are 70% more likely to tear.',
      'Consistency beats intensity — a moderate workout you stick with beats an extreme one you quit.',
      'Track your workouts. People who log their exercises make 40% more progress than those who don\'t.',
    ],
  ),
  TipCategory(
    id: 'nutrition',
    title: 'Nutrition',
    icon: Icons.restaurant_rounded,
    color: const Color(0xFF14B8A6),
    tips: [
      'Eat protein within 2 hours after your workout to maximize muscle protein synthesis and recovery.',
      'Pre-workout meals should be eaten 1-3 hours before and focus on carbs with moderate protein.',
      'You cannot out-train a bad diet — 80% of body composition changes come from what you eat.',
      'Drink 500ml of water 30 minutes before your workout to ensure proper hydration during exercise.',
      'Whole foods beat supplements every time. Real food contains hundreds of beneficial compounds no pill can match.',
    ],
  ),
  TipCategory(
    id: 'motivation',
    title: 'Motivation & Habits',
    icon: Icons.psychology_rounded,
    color: const Color(0xFFF59E0B),
    tips: [
      'The 2-minute rule: make starting so easy you can\'t say no — put on your shoes, do one rep.',
      'Habit stacking: attach a new habit to an existing one — "After I brush my teeth, I\'ll do 5 pushups."',
      'Motivation follows action, not the other way around. Start moving and motivation will catch up.',
      'Don\'t break the chain: mark every day you work out on a calendar. Your only job is to not break the streak.',
      'Comparison is the thief of progress. Focus on being 1% better than yesterday, not better than anyone else.',
    ],
  ),
];

final _random = Random();

String getRandomTip() {
  final category = tipCategories[_random.nextInt(tipCategories.length)];
  return category.tips[_random.nextInt(category.tips.length)];
}
