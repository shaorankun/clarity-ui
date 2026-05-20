import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/room_model.dart';
import '../providers/room_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../features/timer/providers/timer_provider.dart';
import 'inside_room_screen.dart';

// ── Design tokens ─────────────────────────────────────────
class _C {
  static const bg                   = Color(0xFF12121D);
  static const surface              = Color(0xFF1F1E2A);
  static const surfaceContLow       = Color(0xFF1B1A26);
  static const surfaceContHigh      = Color(0xFF292935);
  static const surfaceVariant       = Color(0xFF343440);
  static const primary              = Color(0xFFCEBDFF);
  static const primaryContainer     = Color(0xFF6C3CE0);
  static const onPrimaryContainer   = Color(0xFFE2D6FF);
  static const onSurface            = Color(0xFFE3E0F1);
  static const onSurfaceVar         = Color(0xFFCBC3D7);
  static const outline              = Color(0xFF948EA1);
  static const outlineVar           = Color(0xFF494455);
  static const tertiary             = Color(0xFF00DBE9);
  static const secondary            = Color(0xFFD2BBFF);
}

class RoomsScreen extends StatefulWidget {
  const RoomsScreen({super.key});

  @override
  State<RoomsScreen> createState() => _RoomsScreenState();
}

class _RoomsScreenState extends State<RoomsScreen> {
  bool _isPublic = false;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<RoomProvider>();

      provider.fetchPublicRooms();

      _refreshTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
        if (mounted) {
          provider.refreshPublicRoomsSilently();
        }
      });
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _navigateToRoom(BuildContext context, String roomId) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => InsideRoomScreen(roomId: roomId)),
    ).then((_) {
      if (mounted) context.read<RoomProvider>().fetchPublicRooms();
    });
  }

  /// Dùng khi muốn join/create phòng mới.
  /// Nếu đang trong phòng → hiện confirm dialog trước.
  /// Sau khi xác nhận → leave phòng cũ rồi join/create phòng mới.
  Future<void> _switchToRoom(BuildContext context, Future<bool> Function() joinAction) async {
    final room = context.read<RoomProvider>();

    if (room.currentRoom != null) {
      // Hỏi xác nhận trước khi thoát phòng cũ
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogCtx) => AlertDialog(
          backgroundColor: _C.surface,
          title: const Text(
            'Leave Current Room?',
            style: TextStyle(color: _C.onSurface, fontFamily: 'SpaceGrotesk'),
          ),
          content: Text(
            'You are in "${room.currentRoom!.name}". Leave and join the new room?',
            style: const TextStyle(color: _C.onSurfaceVar),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(false),
              child: const Text('Cancel', style: TextStyle(color: _C.outline)),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(true),
              child: const Text('Leave & Join', style: TextStyle(color: _C.primary)),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
      await room.leaveRoom();
    }

    // Thực hiện join/create
    final ok = await joinAction();
    if (ok && mounted) {
      _navigateToRoom(context, room.currentRoom!.id);
    } else if (!ok && mounted && room.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(room.errorMessage!),
          backgroundColor: const Color(0xFFCF6679),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final room = context.watch<RoomProvider>();

    return Container(
      color: _C.bg,
      child: SafeArea(
        child: Stack(
          children: [
            // Background glow
            Positioned(
              top: -60, right: -60,
              child: Container(
                width: 240, height: 240,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _C.primaryContainer.withOpacity(0.08),
                ),
              ),
            ),

            Column(
              children: [
                _TopAppBar(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        // ── Rejoin Banner ──────────────────────────
                        if (room.currentRoom != null) ...[
                          _RejoinBanner(
                            roomName: room.currentRoom!.name,
                            onTap: () => _navigateToRoom(context, room.currentRoom!.id),
                          ),
                          const SizedBox(height: 20),
                        ],

                        // ── Action Buttons ─────────────────────────
                        Row(
                          children: [
                            Expanded(
                              child: _PrimaryActionButton(
                                icon: Icons.add_circle_outline_rounded,
                                label: 'Create Room',
                                onTap: () => _showCreateRoom(context),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _SecondaryActionButton(
                                icon: Icons.login_rounded,
                                label: 'Join Room',
                                onTap: () => _showJoinRoom(context),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),

                        // ── Active Rooms Header ────────────────────
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Active Rooms',
                              style: TextStyle(
                                fontFamily: 'SpaceGrotesk',
                                fontSize: 22,
                                fontWeight: FontWeight.w600,
                                color: _C.onSurface,
                              ),
                            ),
                            if (!room.isLoadingPublic)
                              Text(
                                '${room.publicRooms.length} Live',
                                style: const TextStyle(
                                  fontFamily: 'SpaceGrotesk',
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: _C.primary,
                                  letterSpacing: 1.2,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // ── Room List ──────────────────────────────
                        if (room.isLoadingPublic)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(32),
                              child: CircularProgressIndicator(
                                color: _C.primary, strokeWidth: 2,
                              ),
                            ),
                          )
                        else if (room.publicRooms.isEmpty)
                          _EmptyRoomsCard()
                        else
                          ...(() {
                            final myRoomId = room.currentRoom?.id;
                            final sorted = [...room.publicRooms]..sort((a, b) {
                              if (a.id == myRoomId) return -1;
                              if (b.id == myRoomId) return 1;
                              return 0;
                            });
                            return sorted.map((r) {
                              final isMine = r.id == myRoomId;
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _RoomCard(
                                  room: r,
                                  isFirst: r.members.isNotEmpty,
                                  isMine: isMine,
                                  onTap: () async {
                                    if (isMine) {
                                      _navigateToRoom(context, r.id);
                                      return;
                                    }
                                    await _switchToRoom(
                                      context,
                                          () => room.joinPublicRoom(r.id),
                                    );
                                  },
                                ),
                              );
                            });
                          })(),

                        const SizedBox(height: 24),

                        // ── Decorative Banner ──────────────────────
                        _FlowStateBanner(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _abandonSoloIfRunning() async {
    final timer = context.read<TimerProvider>();
    if (timer.status != TimerStatus.idle) {
      await timer.abandon();
    }
  }

  void _showCreateRoom(BuildContext context) {
    final ctrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _C.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(
              24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: _C.outlineVar,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Create a Room',
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w600,
                          color: _C.onSurface, fontFamily: 'SpaceGrotesk')),
                  GestureDetector(
                    onTap: () {
                      setState(() => _isPublic = false);
                      Navigator.pop(ctx);
                    },
                    child: Container(
                      width: 32, height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _C.surfaceVariant,
                      ),
                      child: const Icon(Icons.close_rounded,
                          color: _C.onSurfaceVar, size: 18),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              TextField(
                controller: ctrl,
                autofocus: true,
                style: const TextStyle(color: _C.onSurface),
                decoration: InputDecoration(
                  hintText: 'Room name...',
                  hintStyle: TextStyle(color: _C.onSurfaceVar.withOpacity(0.5)),
                  filled: true,
                  fillColor: _C.surfaceContHigh,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: _C.outlineVar.withOpacity(0.4)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: _C.outlineVar.withOpacity(0.4)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: _C.primary, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Public room',
                      style: TextStyle(color: _C.onSurfaceVar)),
                  GestureDetector(
                    onTap: () => setSheetState(() => _isPublic = !_isPublic),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _isPublic
                            ? _C.primaryContainer
                            : _C.surfaceContHigh,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _isPublic ? 'Public' : 'Private',
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Consumer<RoomProvider>(
                builder: (ctx2, room, _) => GestureDetector(
                  onTap: room.isLoading ? null : () async {
                    if (ctrl.text.trim().isEmpty) return;
                    final name = ctrl.text.trim();
                    final isPublicSnapshot = _isPublic;
                    await _abandonSoloIfRunning();
                    setState(() => _isPublic = false);
                    Navigator.pop(ctx);
                    // Dùng _switchToRoom: leave phòng cũ (nếu có) trước khi create
                    await _switchToRoom(
                      context,
                          () => room.createRoom(name, isPublic: isPublicSnapshot),
                    );
                  },
                  child: Container(
                    width: double.infinity,
                    height: 52,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: _C.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: _C.primaryContainer.withOpacity(0.4),
                          blurRadius: 20,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: room.isLoading
                        ? const SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                        : const Text('Create Room',
                        style: TextStyle(
                          color: _C.onPrimaryContainer,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        )),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showJoinRoom(BuildContext context) {
    final ctrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _C.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
            24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: _C.outlineVar,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Join a Room',
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w600,
                        color: _C.onSurface, fontFamily: 'SpaceGrotesk')),
                GestureDetector(
                  onTap: () => Navigator.pop(ctx),
                  child: Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(
                        shape: BoxShape.circle, color: _C.surfaceVariant),
                    child: const Icon(Icons.close_rounded,
                        color: _C.onSurfaceVar, size: 18),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            TextField(
              controller: ctrl,
              autofocus: true,
              maxLength: 6,
              style: const TextStyle(
                color: _C.onSurface,
                fontSize: 24,
                letterSpacing: 8,
                fontWeight: FontWeight.bold,
              ),
              decoration: InputDecoration(
                hintText: 'ABC123',
                hintStyle: TextStyle(
                    color: _C.onSurfaceVar.withOpacity(0.4),
                    letterSpacing: 8, fontSize: 24),
                counterText: '',
                filled: true,
                fillColor: _C.surfaceContHigh,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: _C.outlineVar.withOpacity(0.4)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: _C.outlineVar.withOpacity(0.4)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: _C.primary, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Consumer<RoomProvider>(
              builder: (ctx2, room, _) => GestureDetector(
                onTap: room.isLoading ? null : () async {
                  if (ctrl.text.trim().length != 6) return;
                  final code = ctrl.text.trim();
                  await _abandonSoloIfRunning();
                  Navigator.pop(ctx);
                  // Dùng _switchToRoom: leave phòng cũ (nếu có) trước khi join
                  await _switchToRoom(
                    context,
                        () => room.joinRoom(code),
                  );
                },
                child: Container(
                  width: double.infinity,
                  height: 52,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _C.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: _C.primaryContainer.withOpacity(0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: room.isLoading
                      ? const SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2),
                  )
                      : const Text('Join Room',
                      style: TextStyle(
                        color: _C.onPrimaryContainer,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      )),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

}

// ── Top App Bar ────────────────────────────────────────────
class _TopAppBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: _C.bg.withOpacity(0.85),
        border: Border(
          bottom: BorderSide(color: Colors.white.withOpacity(0.05)),
        ),
      ),
      child: Row(
        children: [
          const Text(
            'Study Rooms',
            style: TextStyle(
              fontFamily: 'SpaceGrotesk',
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: _C.primary,
              letterSpacing: -0.3,
            ),
          ),
          const Spacer(),
          Container(
            width: 34, height: 34,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _C.primaryContainer.withOpacity(0.25),
              border: Border.all(color: _C.primary.withOpacity(0.2), width: 1.5),
            ),
            child: const Icon(Icons.person_rounded,
                color: _C.onSurfaceVar, size: 18),
          ),
        ],
      ),
    );
  }
}

// ── Primary Action Button ──────────────────────────────────
class _PrimaryActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _PrimaryActionButton(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: _C.primaryContainer,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: _C.primaryContainer.withOpacity(0.4),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: _C.onPrimaryContainer, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: _C.onPrimaryContainer,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Secondary Action Button ────────────────────────────────
class _SecondaryActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _SecondaryActionButton(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _C.primaryContainer.withOpacity(0.5)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: _C.primary, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: _C.primary,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Rejoin Banner ──────────────────────────────────────────
class _RejoinBanner extends StatelessWidget {
  final String roomName;
  final VoidCallback onTap;
  const _RejoinBanner({required this.roomName, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [
              _C.primaryContainer.withOpacity(0.25),
              _C.surface.withOpacity(0.95),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _C.primary.withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
              color: _C.primaryContainer.withOpacity(0.2),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 10, height: 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _C.tertiary,
                boxShadow: [
                  BoxShadow(color: _C.tertiary.withOpacity(0.5), blurRadius: 8),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Currently in a room',
                    style: TextStyle(
                        color: _C.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                        letterSpacing: 0.5),
                  ),
                  const SizedBox(height: 2),
                  Text(roomName,
                      style: const TextStyle(
                          color: _C.onSurface,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'SpaceGrotesk')),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: _C.primary, size: 14),
          ],
        ),
      ),
    );
  }
}

// ── Room Card ──────────────────────────────────────────────
class _RoomCard extends StatelessWidget {
  final StudyRoom room;
  final bool isFirst;
  final bool isMine;
  final VoidCallback onTap;
  const _RoomCard({
    required this.room,
    required this.isFirst,
    required this.isMine,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final memberCount = room.members.length;

    if (isMine) {
      // ── Card nổi bật: đang ở trong phòng này ────────────
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF3D2A8A), Color(0xFF2A1F5E)],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF6C3CE0), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6C3CE0).withOpacity(0.45),
              blurRadius: 24,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Badge "You're here"
            Row(
              children: [
                Container(
                  width: 8, height: 8,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF00DBE9),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x8000DBE9),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                const Text(
                  "YOU'RE IN THIS ROOM",
                  style: TextStyle(
                    color: Color(0xFF00DBE9),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text(
                    'ACTIVE',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Room name + members
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        room.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'SpaceGrotesk',
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$memberCount member${memberCount != 1 ? 's' : ''}',
                        style: const TextStyle(
                          color: Color(0xFFCEBDFF),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),

                // Rejoin button
                GestureDetector(
                  onTap: onTap,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(999),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withOpacity(0.25),
                          blurRadius: 12,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Text(
                      'Rejoin',
                      style: TextStyle(
                        color: Color(0xFF3D2A8A),
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    // ── Card thường ─────────────────────────────────────────
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF1F1E2A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF494455)),
      ),
      child: Row(
        children: [
          // Left: icon
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFF6C3CE0).withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.meeting_room_rounded,
              color: Color(0xFFCEBDFF),
              size: 22,
            ),
          ),
          const SizedBox(width: 14),

          // Middle: room name + members
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  room.name,
                  style: const TextStyle(
                    color: Color(0xFFE3E0F1),
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '$memberCount member${memberCount != 1 ? 's' : ''}',
                  style: const TextStyle(
                    color: Color(0xFF948EA1),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Right: Join button
          GestureDetector(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
              decoration: BoxDecoration(
                color: const Color(0xFF6C3CE0),
                borderRadius: BorderRadius.circular(999),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6C3CE0).withOpacity(0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Text(
                'Join',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Empty State ────────────────────────────────────────────
class _EmptyRoomsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _C.outlineVar.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Container(
            width: 56, height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _C.primaryContainer.withOpacity(0.15),
              border: Border.all(color: _C.primary.withOpacity(0.15)),
            ),
            child: const Icon(Icons.meeting_room_outlined,
                color: _C.primary, size: 26),
          ),
          const SizedBox(height: 16),
          const Text(
            'No active rooms',
            style: TextStyle(
              color: _C.onSurface,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              fontFamily: 'SpaceGrotesk',
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Create a room and invite others to join',
            textAlign: TextAlign.center,
            style: TextStyle(color: _C.outline, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

// ── Flow State Banner ──────────────────────────────────────
class _FlowStateBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _C.outlineVar.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: _C.primaryContainer.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Decorative glow
          Positioned(
            right: -20, bottom: -20,
            child: Container(
              width: 120, height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _C.primaryContainer.withOpacity(0.12),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Flow State Awaits',
                style: TextStyle(
                  fontFamily: 'SpaceGrotesk',
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: _C.primary,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Join a room to boost your productivity.',
                style: TextStyle(color: _C.onSurfaceVar, fontSize: 13),
              ),
            ],
          ),
        ],
      ),
    );
  }
}