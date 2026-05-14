import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/room_model.dart';
import '../providers/room_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../shared/widgets/circular_timer.dart';

class InsideRoomScreen extends StatefulWidget {
  final String roomId;
  const InsideRoomScreen({super.key, required this.roomId});

  @override
  State<InsideRoomScreen> createState() => _InsideRoomScreenState();
}

class _InsideRoomScreenState extends State<InsideRoomScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      final room = context.read<RoomProvider>();
      await room.fetchRoom(widget.roomId);
      await room.connectWebSocket(widget.roomId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final room = context.watch<RoomProvider>();
    final auth = context.watch<AuthProvider>();
    final userId = auth.user?.id ?? '';
    final isOwner = room.isOwner(userId);
    final session = room.roomSession;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: room.isLoading
              ? const Center(child: CircularProgressIndicator(
              color: AppColors.primary))
              : room.currentRoom == null
              ? const Center(child: Text('Room not found',
              style: TextStyle(color: AppColors.textSecondary)))
              : Column(
            children: [
              _buildHeader(context, room),
              const Spacer(),
              _buildStatusChip(session),
              const SizedBox(height: 24),
              _buildTimer(room, session),
              const SizedBox(height: 32),
              _buildMembers(room),
              const Spacer(),
              if (isOwner) _buildOwnerControls(context, room, session),
              _buildLeaveButton(context, room),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, RoomProvider room) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios,
                color: AppColors.textPrimary),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Text(room.currentRoom!.name,
                style: const TextStyle(fontSize: 18,
                    fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                overflow: TextOverflow.ellipsis),
          ),
          // Invite code chip
          GestureDetector(
            onTap: () {
              Clipboard.setData(
                  ClipboardData(text: room.currentRoom!.inviteCode));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Invite code copied!'),
                    duration: Duration(seconds: 2)),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.primary.withOpacity(0.4)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.copy, color: AppColors.primary, size: 12),
                  const SizedBox(width: 6),
                  Text(room.currentRoom!.inviteCode,
                      style: const TextStyle(color: AppColors.primary,
                          fontWeight: FontWeight.bold, letterSpacing: 2)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(RoomSession? session) {
    final status = session?.status ?? 'IDLE';
    final label = status == 'FOCUSING' ? '🎯 Focusing'
        : status == 'BREAK' ? '☕ On Break'
        : '💤 Idle';
    final color = status == 'FOCUSING' ? AppColors.primary
        : status == 'BREAK' ? AppColors.breakColor
        : AppColors.textMuted;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(label,
          style: TextStyle(color: color, fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildTimer(RoomProvider room, RoomSession? session) {
    final isActive = session?.status == 'FOCUSING' ||
        session?.status == 'BREAK';
    final total = (session?.durationMinutes ?? 25) * 60;
    final progress = total == 0 ? 0.0
        : 1 - (room.remainingSeconds / total);

    return CircularTimer(
      progress: isActive ? progress.clamp(0.0, 1.0) : 0.0,
      timeLabel: isActive ? room.countdownLabel : '--:--',
      isRunning: isActive,
    );
  }

  Widget _buildMembers(RoomProvider room) {
    final members = room.currentRoom!.members;
    return Column(
      children: [
        Text('${members.length} member${members.length != 1 ? 's' : ''}',
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: members.map((m) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: AppColors.primary.withOpacity(0.2),
                  child: Text(
                      m.displayName.isNotEmpty
                          ? m.displayName[0].toUpperCase() : '?',
                      style: const TextStyle(color: AppColors.primary,
                          fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 6),
                Text(m.displayName,
                    style: const TextStyle(color: AppColors.textSecondary,
                        fontSize: 11)),
              ],
            ),
          )).toList(),
        ),
      ],
    );
  }

  Widget _buildOwnerControls(
      BuildContext context, RoomProvider room, RoomSession? session) {
    final status = session?.status ?? 'IDLE';

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      child: Column(
        children: [
          const Text('You are the host 👑',
              style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
          const SizedBox(height: 12),
          Row(
            children: [
              if (status != 'FOCUSING')
                Expanded(
                  child: _controlButton(
                    label: '▶ Start Focus',
                    color: AppColors.primary,
                    onTap: () => _showDurationPicker(context, room, 'focus'),
                  ),
                ),
              if (status == 'FOCUSING') ...[
                Expanded(
                  child: _controlButton(
                    label: '☕ Take Break',
                    color: AppColors.breakColor,
                    onTap: () => _showDurationPicker(context, room, 'break'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _controlButton(
                    label: '⏹ End',
                    color: AppColors.danger,
                    onTap: room.endSession,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _controlButton({
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 46,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.4)),
        ),
        child: Text(label,
            style: TextStyle(color: color, fontWeight: FontWeight.w600)),
      ),
    );
  }

  void _showDurationPicker(
      BuildContext context, RoomProvider room, String type) {
    final options = [5, 10, 15, 25, 30, 45, 50];
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(type == 'focus' ? 'Focus duration' : 'Break duration',
                style: const TextStyle(fontSize: 18,
                    fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: options.map((min) => GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  if (type == 'focus') {
                    room.startFocus(min);
                  } else {
                    room.startBreak(min);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text('$min min',
                      style: const TextStyle(color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600)),
                ),
              )).toList(),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildLeaveButton(BuildContext context, RoomProvider room) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: GestureDetector(
        onTap: () => _confirmLeave(context, room),
        child: Container(
          width: double.infinity,
          height: 46,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.danger.withOpacity(0.4)),
          ),
          child: const Text('Leave Room',
              style: TextStyle(color: AppColors.danger,
                  fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }

  void _confirmLeave(BuildContext context, RoomProvider room) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Leave Room?',
            style: TextStyle(color: AppColors.textPrimary)),
        content: const Text('You will exit this study session.',
            style: TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.textMuted)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // đóng dialog
              await room.leaveRoom();
              if (context.mounted) Navigator.pop(context); // về lobby
            },
            child: const Text('Leave',
                style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
  }
}