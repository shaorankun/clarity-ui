import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/notification_service.dart';
import '../../../core/storage/token_storage.dart';
import '../models/room_model.dart';

class RoomProvider extends ChangeNotifier {
  StudyRoom? currentRoom;
  RoomSession? roomSession;
  bool isLoading = false;
  String? errorMessage;
  List<StudyRoom> publicRooms = [];
  bool isLoadingPublic = false;

  // Countdown timer
  int remainingSeconds = 0;
  Timer? _countdown;
  Timer? _pollingTimer;

  String? _currentSessionId;

  // Flag để tránh race condition khi đang leave
  bool _isLeaving = false;

  // WebSocket
  StompClient? _stompClient;
  bool isConnected = false;

  final _dio = DioClient.instance;

  // ── REST API ─────────────────────────────────────────

  Future<bool> createRoom(String name, {bool isPublic = false}) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      final res = await _dio.post('/api/rooms', data: {
        'name': name,
        'isPublic': isPublic,
      });
      print('=== createRoom data: name=$name, isPublic=$isPublic');
      print('=== createRoom response: ${res.data}');
      final roomId = StudyRoom.fromJson(res.data).id;
      await fetchRoom(roomId);
      await TokenStorage.saveRoomId(currentRoom!.id);
      // BUG FIX: Refresh public room list sau khi tạo để Active Rooms cập nhật ngay
      if (isPublic) {
        await fetchPublicRooms();
      }
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
      final res = await _dio.post('/api/rooms/join', data: {'inviteCode': inviteCode});
      final roomId = StudyRoom.fromJson(res.data).id;
      await fetchRoom(roomId);
      await TokenStorage.saveRoomId(currentRoom!.id);
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

  Future<bool> joinPublicRoom(String roomId) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      await _dio.post('/api/rooms/$roomId/join');
      await fetchRoom(roomId);
      await TokenStorage.saveRoomId(currentRoom!.id);
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

  Future<void> fetchPublicRooms() async {
    isLoadingPublic = true;
    notifyListeners();
    try {
      final res = await _dio.get('/api/rooms/public');
      publicRooms = (res.data as List).map((e) => StudyRoom.fromJson(e)).toList();
    } catch (_) {}
    isLoadingPublic = false;
    notifyListeners();
  }

  Future<void> refreshPublicRoomsSilently() async {
    try {
      final res = await _dio.get('/api/rooms/public');
      final newData = (res.data as List).map((e) => StudyRoom.fromJson(e)).toList();

      publicRooms = newData;
      notifyListeners();
    } catch (_) {
    }
  }

  Future<void> leaveRoom() async {
    if (currentRoom == null) return;
    _isLeaving = true;
    try {
      await _dio.delete('/api/rooms/${currentRoom!.id}/leave');
    } catch (_) {}
    await _cancelSession();
    await TokenStorage.clearRoomId();
    _cleanup();
    _isLeaving = false;
  }

  Future<void> restoreRoom() async {
    final roomId = await TokenStorage.getRoomId();
    if (roomId == null) return;
    try {
      await fetchRoom(roomId);
      print('=== Room restored: $roomId');
    } catch (_) {
      // Phòng không còn tồn tại → clear
      await TokenStorage.clearRoomId();
    }
  }

  // ── WebSocket ─────────────────────────────────────────

  Future<void> connectWebSocket(String roomId) async {
    final token = await TokenStorage.getAccessToken();

    if (token == null) {
      print('=== WS: No token, abort');
      return;
    }

    // SockJS dùng https:// không phải wss://
    final sockJsUrl = '${DioClient.baseUrl}/ws';
    print('=== WS: Connecting to $sockJsUrl');

    _stompClient = StompClient(
      config: StompConfig.sockJS(
        url: sockJsUrl,
        onConnect: (frame) {
          print('=== WS: Connected!');
          isConnected = true;
          notifyListeners();

          _stompClient!.subscribe(
            destination: '/topic/room/$roomId',
            callback: (frame) {
              print('=== WS: Received: ${frame.body}');
              // Không xử lý message nếu đang leave hoặc đã rời phòng
              if (_isLeaving || currentRoom == null) return;
              if (frame.body == null) return;
              final data = jsonDecode(frame.body!);
              final newSession = RoomSession.fromJson(data);

              // Nếu chuyển sang FOCUSING → start session cho user này
              if (newSession.status == 'FOCUSING' &&
                  roomSession?.status != 'FOCUSING') {
                _startSession(newSession.durationMinutes ?? 25);
              }

              if (newSession.status == 'IDLE' && roomSession?.status == 'FOCUSING') {
                _cancelSession();
              }

              if (newSession.status == 'BREAK' && roomSession?.status == 'FOCUSING') {
                _cancelSession();
              }

              roomSession = newSession;
              _syncCountdown();
              notifyListeners();
            },
          );
          print('=== WS: Subscribed to /topic/room/$roomId');
        },
        onDisconnect: (_) {
          print('=== WS: Disconnected');
          isConnected = false;
          notifyListeners();
        },
        onWebSocketError: (error) {
          print('=== WS: Error: $error');
          isConnected = false;
          notifyListeners();
        },
        onStompError: (frame) {
          print('=== WS: STOMP Error: ${frame.body}');
        },
        stompConnectHeaders: {'Authorization': 'Bearer $token'},
        webSocketConnectHeaders: {'Authorization': 'Bearer $token'},
      ),
    );
    _stompClient!.activate();

    _pollingTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _refreshMembers(roomId);
    });
  }

  Future<void> _refreshMembers(String roomId) async {
    // Không refresh nếu đang trong quá trình leave
    if (_isLeaving || currentRoom == null) return;
    try {
      final res = await _dio.get('/api/rooms/$roomId');
      final updatedRoom = StudyRoom.fromJson(res.data);
      // Chỉ update nếu member list thay đổi và chưa leave
      if (!_isLeaving && currentRoom != null &&
          updatedRoom.members.length != currentRoom?.members.length) {
        currentRoom = updatedRoom;
        notifyListeners();
      }
    } catch (_) {}
  }

  // ── Owner controls ────────────────────────────────────

  void startFocus(int durationMinutes) {
    print('=== WS: isConnected=$isConnected, client=${_stompClient?.connected}');
    if (currentRoom == null) {
      print('=== WS: No current room');
      return;
    }
    print('=== WS: Sending start to /app/room/${currentRoom!.id}/start');
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

    _countdown = Timer.periodic(const Duration(seconds: 1), (_) async {
      if (remainingSeconds > 0) {
        remainingSeconds--;
        notifyListeners();
      } else {
        _countdown?.cancel();
        print('=== Countdown done, status=${roomSession?.status}');
        if (roomSession?.status == 'FOCUSING') {
          await _completeSession();
          await NotificationService.showFocusComplete();
        } else if (roomSession?.status == 'BREAK') {
          await NotificationService.showBreakComplete();
        }
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
    _pollingTimer?.cancel();
    _stompClient?.deactivate();
    _stompClient = null;   // null ngay để callback không thể fire tiếp
    currentRoom      = null;
    roomSession      = null;
    remainingSeconds = 0;
    isConnected      = false;
    notifyListeners();
  }

  Future<void> _startSession(int durationMinutes) async {
    try {
      final res = await _dio.post('/api/sessions/start', data: {
        'durationMinutes': durationMinutes,
      });
      _currentSessionId = res.data['id'];
      print('=== Room session started: $_currentSessionId');
    } catch (e) {
      print('=== Room session start failed: $e');
    }
  }

  Future<void> _completeSession() async {
    if (_currentSessionId == null) return;
    try {
      await _dio.post('/api/sessions/end', data: {
        'id': _currentSessionId,
        'status': 'COMPLETED',
      });
      print('=== Room session COMPLETED');
    } catch (e) {
      print('=== Room session complete failed: $e');
    }
    _currentSessionId = null;
  }

  Future<void> _cancelSession() async {
    if (_currentSessionId == null) return;
    try {
      await _dio.post('/api/sessions/end', data: {
        'id': _currentSessionId,
        'status': 'ABANDONED',
      });
      print('=== Session CANCELLED: $_currentSessionId');
    } catch (e) {
      print('=== Cancel failed: $e');
      if (e is DioException) print('=== Cancel error body: ${e.response?.data}');
    }
    _currentSessionId = null;
  }

  @override
  void dispose() {
    if (currentRoom != null) {
      leaveRoom();
    } else {
      _cleanup();
    }
    super.dispose();
  }
}