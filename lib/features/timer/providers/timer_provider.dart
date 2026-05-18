import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/network/dio_client.dart';

enum TimerMode { focus, shortBreak, longBreak }
enum TimerStatus { idle, running, paused }

class TimerProvider extends ChangeNotifier {
  // Config (seconds)
  static const Map<TimerMode, int> _durations = {
    TimerMode.focus:      25 * 60,
    TimerMode.shortBreak: 5  * 60,
    TimerMode.longBreak:  15 * 60,
  };

  TimerMode   mode      = TimerMode.focus;
  TimerStatus status    = TimerStatus.idle;
  int         remaining = 25 * 60;
  int         sessions  = 0; // completed focus sessions today

  String? selectedTaskId;
  String? selectedTaskTitle;
  String? _currentSessionId;

  Timer? _ticker;
  final _dio = DioClient.instance;

  // ── Getters ──────────────────────────────────────────
  int get total    => _durations[mode]!;
  double get progress => 1 - (remaining / total);

  String get timeLabel {
    final m = (remaining ~/ 60).toString().padLeft(2, '0');
    final s = (remaining % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  String get modeLabel {
    switch (mode) {
      case TimerMode.focus:      return 'Focus';
      case TimerMode.shortBreak: return 'Short Break';
      case TimerMode.longBreak:  return 'Long Break';
    }
  }

  // ── Actions ──────────────────────────────────────────
  void setMode(TimerMode m) {
    if (status == TimerStatus.running) return;
    mode      = m;
    remaining = _durations[m]!;
    notifyListeners();
  }

  void selectTask(String? id, String? title) {
    selectedTaskId    = id;
    selectedTaskTitle = title;
    notifyListeners();
  }

  Future<void> start() async {
    try {
      final res = await _dio.post('/api/sessions/start', data: {
        'durationMinutes': _durations[mode]! ~/ 60,
        if (selectedTaskId != null) 'taskId': selectedTaskId,
      });
      _currentSessionId = res.data['id'];
    } catch (e) {
      print('=== Session start failed: $e');
      return;
    }
    status = TimerStatus.running;
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    notifyListeners();
  }

  void pause() {
    status = TimerStatus.paused;
    _ticker?.cancel();
    notifyListeners();
  }

  void resume() => start();

  Future<void> abandon() async {
    _ticker?.cancel();
    if (_currentSessionId != null) {
      try {
        await _dio.post('/api/sessions/end', data: {
          'sessionId': _currentSessionId,
          'status': 'ABANDONED',
        });
      } catch (_) {}
      _currentSessionId = null;
    }
    status = TimerStatus.idle;
    remaining = _durations[mode]!;
    notifyListeners();
  }

  void _tick() {
    if (remaining > 0) {
      remaining--;
      notifyListeners();
    } else {
      _onComplete();
    }
  }

  Future<void> _onComplete() async {
    _ticker?.cancel();
    status = TimerStatus.idle;

    if (mode == TimerMode.focus && _currentSessionId != null) {
      try {
        await _dio.post('/api/sessions/end', data: {
          'sessionId': _currentSessionId,
          'status': 'COMPLETED',
        });
        print('=== Solo session COMPLETED');
      } catch (e) {
        print('=== Solo session end failed: $e');
      }
      _currentSessionId = null;
      sessions++;
    }

    remaining = _durations[mode]!;
    notifyListeners();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}