class DailyStats {
  final String date;
  final int totalMinutes;    // backend trả "totalMinutes"
  final int sessionCount;    // backend trả "sessionCount"
  final int tasksCompleted;

  DailyStats({
    required this.date,
    required this.totalMinutes,
    required this.sessionCount,
    required this.tasksCompleted,
  });

  factory DailyStats.fromJson(Map<String, dynamic> json) => DailyStats(
    date:           json['date']           ?? '',
    totalMinutes:   json['totalMinutes']   ?? 0,
    sessionCount:   json['sessionCount']   ?? 0,
    tasksCompleted: json['tasksCompleted'] ?? 0,
  );
}

class StatsOverview {
  final int currentStreak;
  final int longestStreak;
  final int totalMinutes;
  final int totalSessions;
  final List<DailyStats> weekly;

  StatsOverview({
    required this.currentStreak,
    required this.longestStreak,
    required this.totalMinutes,
    required this.totalSessions,
    required this.weekly,
  });
}