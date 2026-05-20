import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../../core/network/dio_client.dart';
import '../models/stats_model.dart';

class StatsProvider extends ChangeNotifier {
  StatsOverview? overview;
  bool isLoading = false;
  String? errorMessage;

  final _dio = DioClient.instance;

  // Weekly totals tính từ list — không cần API call thêm
  int get weeklyTotalMinutes =>
      overview?.weekly.fold(0, (sum, d) => sum! + d.totalMinutes) ?? 0;

  int get weeklyTotalSessions =>
      overview?.weekly.fold(0, (sum, d) => sum! + d.sessionCount) ?? 0;

  Future<void> fetchStats() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _dio.get('/api/stats/streak'),
        _dio.get('/api/stats/weekly'),
      ]);

      final streak     = results[0].data;
      final weeklyList = results[1].data as List;
      final weekly     = weeklyList.map((e) => DailyStats.fromJson(e)).toList();

      // today = phần tử cuối của weekly (backend trả đủ 7 ngày theo UTC)
      final today = weekly.isNotEmpty ? weekly.last : null;

      overview = StatsOverview(
        currentStreak: streak['currentStreak'] ?? 0,
        longestStreak: streak['longestStreak'] ?? 0,
        totalMinutes:  today?.totalMinutes  ?? 0,
        totalSessions: today?.sessionCount  ?? 0,
        weekly:        weekly,
      );
    } on DioException catch (e) {
      errorMessage = e.response?.data['message'] ?? 'Failed to load stats';
      _setEmpty();
    } catch (_) {
      _setEmpty();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void _setEmpty() {
    overview = StatsOverview(
      currentStreak: 0,
      longestStreak: 0,
      totalMinutes:  0,
      totalSessions: 0,
      weekly:        [],
    );
  }

  String formatMinutes(int minutes) {
    if (minutes < 60) return '${minutes}m';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return m == 0 ? '${h}h' : '${h}h ${m}m';
  }
}