import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../../core/network/dio_client.dart';
import '../models/stats_model.dart';

class StatsProvider extends ChangeNotifier {
  StatsOverview? overview;
  bool isLoading = false;
  String? errorMessage;

  final _dio = DioClient.instance;

  Future<void> fetchStats() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _dio.get('/api/stats/streak'),
        _dio.get('/api/stats/weekly'),
        _dio.get('/api/stats/daily'),
      ]);

      final streak = results[0].data;
      final weeklyList = results[1].data as List;
      final today = results[2].data;

      overview = StatsOverview(
        currentStreak: streak['currentStreak'] ?? 0,
        longestStreak: streak['longestStreak'] ?? 0,
        totalMinutes:  today['totalMinutes']   ?? 0,
        totalSessions: today['sessionCount']   ?? 0,
        weekly: weeklyList.map((e) => DailyStats.fromJson(e)).toList(),
      );
    } on DioException catch (e) {
      errorMessage = e.response?.data['message'] ?? 'Failed to load stats';
      overview = StatsOverview(
        currentStreak: 0,
        longestStreak: 0,
        totalMinutes:  0,
        totalSessions: 0,
        weekly: [],
      );
    } catch (_) {
      overview = StatsOverview(
        currentStreak: 0,
        longestStreak: 0,
        totalMinutes:  0,
        totalSessions: 0,
        weekly: [],
      );
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  String formatMinutes(int minutes) {
    if (minutes < 60) return '${minutes}m';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return m == 0 ? '${h}h' : '${h}h ${m}m';
  }
}