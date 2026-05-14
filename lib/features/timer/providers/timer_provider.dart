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

  void start() {
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

  void abandon() {
    _ticker?.cancel();
    status    = TimerStatus.idle;
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

    if (mode == TimerMode.focus) {
      sessions++;
      // Log session to backend
      try {
        await _dio.post('/api/sessions', data: {
          'durationMinutes': _durations[TimerMode.focus]! ~/ 60,
          if (selectedTaskId != null) 'taskId': selectedTaskId,
        });
      } catch (_) {}
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