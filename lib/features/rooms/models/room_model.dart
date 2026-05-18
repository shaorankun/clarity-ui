class RoomMember {
  final String userId;
  final String displayName;

  RoomMember({required this.userId, required this.displayName});

  factory RoomMember.fromJson(Map<String, dynamic> json) => RoomMember(
    userId:      json['userId'],
    displayName: json['displayName'],
  );
}

class StudyRoom {
  final String id;
  final String ownerId;
  final String name;
  final String inviteCode;
  final bool isActive;
  final List<RoomMember> members;

  StudyRoom({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.inviteCode,
    required this.isActive,
    required this.members,
  });

  factory StudyRoom.fromJson(Map<String, dynamic> json) => StudyRoom(
    id:         json['id'],
    ownerId:    json['ownerId'],
    name:       json['name'],
    inviteCode: json['inviteCode'],
    isActive:   json['active'] ?? true,
    members: (json['roomMembers'] as List? ?? [])
        .map((e) => RoomMember.fromJson(e))
        .toList(),
  );
}

class RoomSession {
  final String roomId;
  final String status; // "FOCUSING" | "BREAK" | "IDLE"
  final DateTime? startedAt;
  final int? durationMinutes;

  RoomSession({
    required this.roomId,
    required this.status,
    this.startedAt,
    this.durationMinutes,
  });

  factory RoomSession.fromJson(Map<String, dynamic> json) => RoomSession(
    roomId:          json['roomId'],
    status:          json['status'] ?? 'IDLE',
    startedAt:       json['startedAt'] != null
        ? _parseDateTime(json['startedAt']) : null,
    durationMinutes: json['durationMinutes'],
  );

  static DateTime? _parseDateTime(String raw) {
    try {
      final trimmed = raw.replaceFirstMapped(
        RegExp(r'(\.\d{6})\d+'),
            (m) => m.group(1)!,
      );
      // Thêm Z để đánh dấu là UTC
      return DateTime.parse('${trimmed}Z');
    } catch (e) {
      print('=== DateTime parse error: $e, raw: $raw');
      return null;
    }
  }

  // Tính số giây còn lại dựa vào startedAt + durationMinutes
  int get remainingSeconds {
    if (startedAt == null || durationMinutes == null) return 0;
    final startUtc = startedAt!.toUtc();
    final endUtc = startUtc.add(Duration(minutes: durationMinutes!));
    final remaining = endUtc.difference(DateTime.now().toUtc()).inSeconds;
    print('=== remainingSeconds: start=$startUtc end=$endUtc now=${DateTime.now().toUtc()} remaining=$remaining');
    return remaining > 0 ? remaining : 0;
  }
}