import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/room_model.dart';
import '../providers/room_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../features/timer/providers/timer_provider.dart';
import 'inside_room_screen.dart';

class RoomsScreen extends StatefulWidget {
  const RoomsScreen({super.key});

  @override
  State<RoomsScreen> createState() => _RoomsScreenState();
}

class _RoomsScreenState extends State<RoomsScreen> {
  bool _isPublic = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RoomProvider>().fetchPublicRooms();
    });
  }

  void _navigateToRoom(BuildContext context, String roomId) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => InsideRoomScreen(roomId: roomId)),
    ).then((_) {
      if (mounted) context.read<RoomProvider>().fetchPublicRooms();
    });
  }

  @override
  Widget build(BuildContext context) {
    final room = context.watch<RoomProvider>();

    return Container(
      decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Study Rooms',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary)),
              const SizedBox(height: 8),
              const Text('Focus together, achieve more',
                  style: TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 32),

              if (room.currentRoom != null) ...[
                _RejoinBanner(
                  roomName: room.currentRoom!.name,
                  onTap: () => _navigateToRoom(context, room.currentRoom!.id),
                ),
                const SizedBox(height: 24),
                const Divider(color: AppColors.surfaceLight),
                const SizedBox(height: 24),
              ],

              _ActionCard(
                icon: '🚪',
                title: 'Create a Room',
                subtitle: 'Start a session and invite friends',
                gradient: true,
                onTap: () => _showCreateRoom(context),
              ),
              const SizedBox(height: 16),

              _ActionCard(
                icon: '🔑',
                title: 'Join with Code',
                subtitle: 'Enter a 6-character invite code',
                gradient: false,
                onTap: () => _showJoinRoom(context),
              ),

              const SizedBox(height: 32),
              const Text('How it works',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary)),
              const SizedBox(height: 12),
              const _HintRow(icon: '👑', text: 'Room owner controls Start, Break & End'),
              const SizedBox(height: 8),
              const _HintRow(icon: '🔄', text: 'Timer syncs in real-time for everyone'),
              const SizedBox(height: 8),
              const _HintRow(icon: '📤', text: 'Share your invite code to let others join'),

              const SizedBox(height: 32),
              const Text('Public Rooms',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary)),
              const SizedBox(height: 12),
              if (room.isLoadingPublic)
                const Center(child: CircularProgressIndicator())
              else if (room.publicRooms.isEmpty)
                const Text('No public rooms available',
                    style: TextStyle(color: AppColors.textSecondary))
              else
                ...room.publicRooms.map((r) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _PublicRoomCard(
                    room: r,
                    onTap: () async {
                      final ok = await room.joinPublicRoom(r.id);
                      if (ok && mounted) {
                        _navigateToRoom(context, room.currentRoom!.id);
                      }
                    },
                  ),
                )),
            ],
          ),
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
      backgroundColor: AppColors.surface,
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Create a Room',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary)),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.textMuted),
                    onPressed: () {
                      setState(() => _isPublic = false);
                      Navigator.pop(ctx);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: ctrl,
                autofocus: true,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(hintText: 'Room name...'),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Public room',
                      style: TextStyle(color: AppColors.textSecondary)),
                  GestureDetector(
                    onTap: () => setSheetState(() => _isPublic = !_isPublic),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _isPublic ? AppColors.primary : AppColors.surfaceLight,
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
              const SizedBox(height: 12),
              Consumer<RoomProvider>(
                builder: (ctx2, room, _) => AppButton(
                  label: 'Create Room',
                  isLoading: room.isLoading,
                  onPressed: () async {
                    if (ctrl.text.trim().isEmpty) return;
                    final name = ctrl.text.trim();
                    await _abandonSoloIfRunning();
                    final ok = await room.createRoom(name, isPublic: _isPublic);
                    if (ok) {
                      setState(() => _isPublic = false);
                      Navigator.pop(ctx);
                      if (mounted) {
                        _navigateToRoom(context, room.currentRoom!.id);
                      }
                    } else if (room.errorMessage?.contains('already') == true) {
                      setState(() => _isPublic = false);
                      Navigator.pop(ctx);
                      if (mounted) {
                        _showAlreadyInRoomDialog(room, name, isCreate: true);
                      }
                    } else {
                      if (ctx2.mounted) {
                        ScaffoldMessenger.of(ctx2).showSnackBar(
                          SnackBar(
                              content: Text(room.errorMessage ?? 'Error'),
                              backgroundColor: AppColors.danger),
                        );
                      }
                    }
                  },
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
      backgroundColor: AppColors.surface,
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Join a Room',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary)),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.textMuted),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: ctrl,
              autofocus: true,
              maxLength: 6,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 24,
                letterSpacing: 8,
                fontWeight: FontWeight.bold,
              ),
              decoration: const InputDecoration(
                hintText: 'ABC123',
                counterText: '',
              ),
            ),
            const SizedBox(height: 20),
            Consumer<RoomProvider>(
              builder: (ctx2, room, _) => AppButton(
                label: 'Join Room',
                isLoading: room.isLoading,
                onPressed: () async {
                  if (ctrl.text.trim().length != 6) return;
                  final code = ctrl.text.trim();
                  await _abandonSoloIfRunning();
                  final ok = await room.joinRoom(code);
                  if (ok) {
                    Navigator.pop(ctx);
                    if (mounted) {
                      _navigateToRoom(context, room.currentRoom!.id);
                    }
                  } else if (room.errorMessage?.contains('already') == true) {
                    Navigator.pop(ctx);
                    if (mounted) {
                      _showAlreadyInRoomDialog(room, code, isCreate: false);
                    }
                  } else {
                    if (ctx2.mounted) {
                      ScaffoldMessenger.of(ctx2).showSnackBar(
                        SnackBar(
                            content: Text(room.errorMessage ?? 'Error'),
                            backgroundColor: AppColors.danger),
                      );
                    }
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAlreadyInRoomDialog(RoomProvider room, String value,
      {bool isCreate = false}) {
    final navigator = Navigator.of(context);
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Already in a Room',
            style: TextStyle(color: AppColors.textPrimary)),
        content: const Text(
            'You are currently in another room. Leave it and join this one?',
            style: TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.textMuted)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await room.leaveRoom();
              final ok = isCreate
                  ? await room.createRoom(value)
                  : await room.joinRoom(value);
              if (ok && mounted) {
                _navigateToRoom(context, room.currentRoom!.id);
              }
            },
            child: Text(
              isCreate ? 'Leave & Create' : 'Leave & Join',
              style: const TextStyle(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final String icon;
  final String title;
  final String subtitle;
  final bool gradient;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: gradient ? AppColors.primaryGradient : null,
          color: gradient ? null : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: gradient ? null : Border.all(color: AppColors.surfaceLight),
        ),
        child: Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 32)),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white)),
                const SizedBox(height: 4),
                Text(subtitle,
                    style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withOpacity(0.7))),
              ],
            ),
            const Spacer(),
            Icon(Icons.arrow_forward_ios,
                color: Colors.white.withOpacity(0.7), size: 16),
          ],
        ),
      ),
    );
  }
}

class _HintRow extends StatelessWidget {
  final String icon;
  final String text;
  const _HintRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(icon, style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 10),
        Text(text,
            style: const TextStyle(
                color: AppColors.textSecondary, fontSize: 13)),
      ],
    );
  }
}

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
          color: AppColors.primary.withOpacity(0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primary.withOpacity(0.4)),
        ),
        child: Row(
          children: [
            const Text('🟢', style: TextStyle(fontSize: 20)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Currently in a room',
                      style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 13)),
                  const SizedBox(height: 2),
                  Text(roomName,
                      style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios,
                color: AppColors.primary, size: 14),
          ],
        ),
      ),
    );
  }
}

class _PublicRoomCard extends StatelessWidget {
  final StudyRoom room;
  final VoidCallback onTap;

  const _PublicRoomCard({required this.room, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.surfaceLight),
        ),
        child: Row(
          children: [
            const Text('🏠', style: TextStyle(fontSize: 24)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(room.name,
                      style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text('${room.members.length} member(s)',
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 12)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios,
                color: AppColors.textMuted, size: 14),
          ],
        ),
      ),
    );
  }
}