import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/storage/token_storage.dart';
import '../models/room_model.dart';

class RoomProvider extends ChangeNotifier {
  StudyRoom? currentRoom;
  RoomSession? roomSession;
  bool isLoading = false;
  String? errorMessage;

  // Countdown timer
  int remainingSeconds = 0;
  Timer? _countdown;

  // WebSocket
  StompClient? _stompClient;
  bool isConnected = false;

  final _dio = DioClient.instance;

  // ── REST API ─────────────────────────────────────────

  Future<bool> createRoom(String name) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      final res = await _dio.post('/api/rooms', data: {'name': name});
      currentRoom = StudyRoom.fromJson(res.data);
      notifyListeners();
      return true;
    } on DioException catch (e) {
      errorMessage = e.response?.data['message'] ?? 'Failed to create room';
      notifyListeners();
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> joinRoom(String inviteCode) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      await _dio.post('/api/rooms/join', data: {'inviteCode': inviteCode});
      notifyListeners();
      return true;
    } on DioException catch (e) {
      errorMessage = e.response?.data['message'] ?? 'Failed to join room';
      notifyListeners();
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchRoom(String roomId) async {
    isLoading = true;
    notifyListeners();
    try {
      final results = await Future.wait([
        _dio.get('/api/rooms/$roomId'),
        _dio.get('/api/rooms/$roomId/state'),
      ]);
      currentRoom  = StudyRoom.fromJson(results[0].data);
      roomSession  = RoomSession.fromJson(results[1].data);
      _syncCountdown();
    } on DioException catch (e) {
      errorMessage = e.response?.data['message'] ?? 'Failed to load room';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> leaveRoom() async {
    if (currentRoom == null) return;
    try {
      await _dio.delete('/api/rooms/${currentRoom!.id}/leave');
    } catch (_) {}
    _cleanup();
  }

  // ── WebSocket ─────────────────────────────────────────

  Future<void> connectWebSocket(String roomId) async {
    final token = await TokenStorage.getAccessToken();
    if (token == null) return;

    _stompClient = StompClient(
      config: StompConfig(
        url: '${DioClient.baseUrl.replaceFirst('https', 'ws')}/ws',
        onConnect: (frame) {
          isConnected = true;
          notifyListeners();

          _stompClient!.subscribe(
            destination: '/topic/room/$roomId',
            callback: (frame) {
              if (frame.body == null) return;
              final data = jsonDecode(frame.body!);
              roomSession = RoomSession.fromJson(data);
              _syncCountdown();
              notifyListeners();
            },
          );
        },
        onDisconnect: (_) {
          isConnected = false;
          notifyListeners();
        },
        onWebSocketError: (_) {
          isConnected = false;
          notifyListeners();
        },
        stompConnectHeaders: {'Authorization': 'Bearer $token'},
        webSocketConnectHeaders: {'Authorization': 'Bearer $token'},
      ),
    );
    _stompClient!.activate();
  }

  // ── Owner controls ────────────────────────────────────

  void startFocus(int durationMinutes) {
    if (currentRoom == null) return;
    _stompClient?.send(
      destination: '/app/room/${currentRoom!.id}/start',
      body: jsonEncode({'durationMinutes': durationMinutes}),
    );
  }

  void startBreak(int durationMinutes) {
    if (currentRoom == null) return;
    _stompClient?.send(
      destination: '/app/room/${currentRoom!.id}/break',
      body: jsonEncode({'durationMinutes': durationMinutes}),
    );
  }

  void endSession() {
    if (currentRoom == null) return;
    _stompClient?.send(
      destination: '/app/room/${currentRoom!.id}/end',
      body: jsonEncode({}),
    );
  }

  // ── Countdown ─────────────────────────────────────────

  void _syncCountdown() {
    _countdown?.cancel();
    if (roomSession == null || roomSession!.status == 'IDLE') {
      remainingSeconds = 0;
      notifyListeners();
      return;
    }

    remainingSeconds = roomSession!.remainingSeconds;

    _countdown = Timer.periodic(const Duration(seconds: 1), (_) {
      if (remainingSeconds > 0) {
        remainingSeconds--;
        notifyListeners();
      } else {
        _countdown?.cancel();
      }
    });
  }

  String get countdownLabel {
    final m = (remainingSeconds ~/ 60).toString().padLeft(2, '0');
    final s = (remainingSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  // ── Helpers ───────────────────────────────────────────

  bool isOwner(String userId) => currentRoom?.ownerId == userId;

  void _cleanup() {
    _countdown?.cancel();
    _stompClient?.deactivate();
    currentRoom      = null;
    roomSession      = null;
    remainingSeconds = 0;
    isConnected      = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _cleanup();
    super.dispose();
  }
}