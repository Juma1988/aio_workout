class UnlockedAchievement {
  final String achievementId;
  final DateTime unlockedAt;
  final String unlockedBy;
  final String? sessionId;

  const UnlockedAchievement({
    required this.achievementId,
    required this.unlockedAt,
    required this.unlockedBy,
    this.sessionId,
  });

  Map<String, dynamic> toJson() => {
    'achievementId': achievementId,
    'unlockedAt': unlockedAt.toIso8601String(),
    'unlockedBy': unlockedBy,
    if (sessionId != null) 'sessionId': sessionId,
  };

  factory UnlockedAchievement.fromJson(Map<String, dynamic> json) =>
      UnlockedAchievement(
        achievementId: json['achievementId'] as String,
        unlockedAt: DateTime.parse(json['unlockedAt'] as String),
        unlockedBy: json['unlockedBy'] as String? ?? 'unknown',
        sessionId: json['sessionId'] as String?,
      );
}
