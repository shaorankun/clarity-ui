import 'dart:async';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/notification_service.dart';
import '../../../core/storage/token_storage.dart';
import 'package:flutter/foundation.dart';

enum TimerMode { focus, shortBreak, longBreak }
enum TimerStatus { idle, running, paused }

class TimerProvider extends ChangeNotifier {
  static const Map<TimerMode, int> _durations = {
    TimerMode.focus:      25 * 60,
    TimerMode.shortBreak: 5  * 60,
    TimerMode.longBreak:  15 * 60,
  };

  // Storage keys
  static const _kSessions    = 'timer_sessions';
  static const _kFocusedSecs = 'timer_focused_seconds';
  static const _kSavedDate   = 'timer_saved_date';

  TimerMode   mode      = TimerMode.focus;
  TimerStatus status    = TimerStatus.idle;
  int         remaining = 25 * 60;
  int         sessions  = 0;
  int         focusedSeconds = 0;

  String? selectedTaskId;
  String? selectedTaskTitle;
  String? _currentSessionId;

  Timer? _ticker;
  final _dio = DioClient.instance;

  // ── Music ────────────────────────────────────────────────────────────────────

  static const List<Map<String, String>> tracks = [
    {'title': 'Lofi 1', 'asset': 'assets/audio/lofi_1.mp3'},
    // {'title': 'Lofi 2', 'asset': 'assets/audio/lofi_2.ogg'},
    // {'title': 'Lofi 3', 'asset': 'assets/audio/lofi_3.ogg'},
  ];

  final AudioPlayer _player = AudioPlayer();
  bool   isMusicEnabled = true;
  int    currentTrackIndex = 0;
  double musicVolume = 0.6;

  String get currentTrackTitle => tracks[currentTrackIndex]['title']!;

  Future<void> _initPlayer() async {
    try {
      print('=== Music: init player');
      await _player.setLoopMode(LoopMode.one);
      await _player.setVolume(musicVolume);
      await _player.setAsset(tracks[0]['asset']!);
      print('=== Music: asset loaded OK');

      // Log trạng thái player
      _player.playerStateStream.listen((state) {
        print('=== Music state: ${state.processingState} | playing: ${state.playing}');
      });
      _player.playbackEventStream.listen(
            (event) => print('=== Music event: $event'),
        onError: (e, st) => print('=== Music ERROR: $e'),
      );
    } catch (e, st) {
      print('=== Music init FAILED: $e');
      print(st);
    }
  }

  Future<void> _loadTrack(int index) async {
    try {
      await _player.setAsset(tracks[index]['asset']!);
    } catch (e) {
      print('=== Music load failed: $e');
    }
  }

  Future<void> toggleMusic() async {
    isMusicEnabled = !isMusicEnabled;
    if (isMusicEnabled && status == TimerStatus.running && mode == TimerMode.focus) {
      await _player.play();
    } else {
      await _player.pause();
    }
    notifyListeners();
  }

  Future<void> setTrack(int index) async {
    currentTrackIndex = index;
    final wasPlaying = _player.playing;
    await _loadTrack(index);
    if (wasPlaying) await _player.play();
    notifyListeners();
  }

  Future<void> setVolume(double v) async {
    musicVolume = v;
    await _player.setVolume(v);
    notifyListeners();
  }

  // ── Getters ──────────────────────────────────────────────────────────────────

  int get total => _durations[mode]!;
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

  // ── Persist helpers ──────────────────────────────────────────────────────────

  String _todayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  Future<void> loadPersistedStats() async {
    final savedDate = await TokenStorage.readRaw(_kSavedDate);
    final today = _todayKey();

    if (savedDate != today) {
      sessions       = 0;
      focusedSeconds = 0;
      await _persistStats();
    } else {
      final s = await TokenStorage.readRaw(_kSessions);
      final f = await TokenStorage.readRaw(_kFocusedSecs);
      sessions       = int.tryParse(s ?? '0') ?? 0;
      focusedSeconds = int.tryParse(f ?? '0') ?? 0;
    }
    await _initPlayer();
    notifyListeners();
  }

  Future<void> _persistStats() async {
    await TokenStorage.writeRaw(_kSessions,    sessions.toString());
    await TokenStorage.writeRaw(_kFocusedSecs, focusedSeconds.toString());
    await TokenStorage.writeRaw(_kSavedDate,   _todayKey());
  }

  // ── Timer logic ──────────────────────────────────────────────────────────────

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

  Future<void> start({bool inRoom = false}) async {
    if (inRoom) return;

    _ticker?.cancel();
    _ticker = null;

    if (mode == TimerMode.focus) {
      try {
        print('=== Session start: calling API');
        final res = await _dio.post('/api/sessions/start', data: {
          'durationMinutes': _durations[mode]! ~/ 60,
          if (selectedTaskId != null) 'taskId': selectedTaskId,
        });
        print('=== Session start: response ${res.statusCode} ${res.data}');
        _currentSessionId = res.data['id'];
      } catch (e) {
        print('=== Session start FAILED: $e');
        return;
      }
      // Không await — fire and forget
      if (isMusicEnabled) unawaited(_player.play());
    }

    status = TimerStatus.running;
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    notifyListeners();
  }

  void pause() {
    status = TimerStatus.paused;
    _ticker?.cancel();
    _player.pause();
    notifyListeners();
  }

  void resume() {
    status = TimerStatus.running;
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    if (isMusicEnabled && mode == TimerMode.focus) _player.play();
    notifyListeners();
  }

  Future<void> abandon() async {
    _ticker?.cancel();
    _ticker = null;
    await _player.pause();
    await _player.seek(Duration.zero);
    await _endSession('ABANDONED');
    status            = TimerStatus.idle;
    remaining         = _durations[mode]!;
    selectedTaskId    = null;
    selectedTaskTitle = null;
    notifyListeners();
  }

  void _tick() {
    if (remaining > 0) {
      remaining--;
      if (mode == TimerMode.focus) {
        focusedSeconds++;
        if (focusedSeconds % 30 == 0) _persistStats();
      }
      notifyListeners();
    } else {
      _onComplete();
    }
  }

  Future<void> _onComplete() async {
    _ticker?.cancel();
    _ticker = null;
    await _player.pause();
    await _player.seek(Duration.zero);
    status = TimerStatus.idle;
    if (mode == TimerMode.focus) {
      sessions++;
      await _endSession('COMPLETED');
      await NotificationService.showFocusComplete();
      await _persistStats();
      selectedTaskId    = null;
      selectedTaskTitle = null;
    } else {
      await NotificationService.showBreakComplete();
    }
    remaining = _durations[mode]!;
    notifyListeners();
  }

  Future<void> _endSession(String sessionStatus) async {
    if (_currentSessionId == null) return;
    try {
      await _dio.post('/api/sessions/end', data: {
        'id': _currentSessionId,
        'status': sessionStatus,
      });
      print('=== Solo session $sessionStatus');
    } catch (e) {
      print('=== Solo session end failed: $e');
    }
    _currentSessionId = null;
  }

  Future<void> cancelStaleSession() async {
    try {
      final res = await _dio.get('/api/sessions/history');
      final sessions = res.data as List;
      final stale = sessions.where((s) => s['status'] == 'IN_PROGRESS').toList();
      for (final s in stale) {
        await _dio.post('/api/sessions/end', data: {
          'id': s['id'],
          'status': 'ABANDONED',
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _player.dispose();
    if (status != TimerStatus.idle) {
      _endSession('ABANDONED');
    }
    super.dispose();
  }
}