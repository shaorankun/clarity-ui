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

    // Khi currentRoom = null (đã leave/cleanup), tự pop về RoomsScreen
    if (!room.isLoading && room.currentRoom == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      });
    }

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: room.isLoading
              ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
              : room.currentRoom == null
              ? const Center(
              child: Text('Room not found',
                  style: TextStyle(color: AppColors.textSecondary)))
              : Column(
            children: [
              _buildHeader(context, room),
              const Spacer(),
              _buildTimer(room, session),
              const SizedBox(height: 32),
              SizedBox(
                height: 50,
                child: isOwner && session?.status == 'FOCUSING'
                    ? _buildFocusingOwnerControls(context, room, session)
                    : _buildStartFocusButton(context, room, session, isOwner),
              ),
              const SizedBox(height: 32),
              _buildMembersSection(room),
              const Spacer(),
              _buildLeaveButton(context, room),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Header ───────────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context, RoomProvider room) {
    final memberCount = room.currentRoom!.members.length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 12, 16, 0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios,
                color: AppColors.textPrimary, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  room.currentRoom!.name,
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '$memberCount MEMBER${memberCount != 1 ? 'S' : ''} ACTIVE',
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                      letterSpacing: 0.8),
                ),
              ],
            ),
          ),
          // Invite code chip
          GestureDetector(
            onTap: () {
              Clipboard.setData(
                  ClipboardData(text: room.currentRoom!.inviteCode));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Invite code copied!'),
                    duration: Duration(seconds: 2)),
              );
            },
            child: Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: AppColors.textMuted.withOpacity(0.4)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'ID: ${room.currentRoom!.inviteCode}',
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.5),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.copy_outlined,
                      color: AppColors.textSecondary, size: 14),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Timer ────────────────────────────────────────────────────────────────

  Widget _buildTimer(RoomProvider room, RoomSession? session) {
    final isActive = session?.status == 'FOCUSING' ||
        session?.status == 'BREAK';
    final total = (session?.durationMinutes ?? 25) * 60;
    final progress =
    total == 0 ? 0.0 : 1 - (room.remainingSeconds / total);
    final status = session?.status ?? 'IDLE';

    final sessionLabel = status == 'FOCUSING'
        ? 'FOCUS SESSION'
        : status == 'BREAK'
        ? 'BREAK TIME'
        : 'FOCUS SESSION';

    return SizedBox(
      width: 260,
      height: 260,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer glow
          if (isActive)
            Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.25),
                    blurRadius: 50,
                    spreadRadius: 12,
                  ),
                ],
              ),
            ),

          // Dark inner circle background
          Container(
            width: 220,
            height: 220,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF13131F),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.4),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),

          // Progress ring
          SizedBox(
            width: 240,
            height: 240,
            child: CircularProgressIndicator(
              value: isActive ? progress.clamp(0.0, 1.0) : 0.0,
              strokeWidth: 6,
              backgroundColor: AppColors.surfaceLight,
              valueColor:
              const AlwaysStoppedAnimation(AppColors.primary),
              strokeCap: StrokeCap.round,
            ),
          ),

          // Label + time
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                sessionLabel,
                style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                    letterSpacing: 2),
              ),
              const SizedBox(height: 8),
              Text(
                isActive ? room.countdownLabel : '00:00',
                style: const TextStyle(
                  fontSize: 44,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Start Focus Button (always visible, disabled for non-owner) ──────────

  Widget _buildStartFocusButton(BuildContext context, RoomProvider room,
      RoomSession? session, bool isOwner) {
    final isEnabled = isOwner;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: GestureDetector(
        onTap: isEnabled
            ? () => _showDurationPicker(context, room, 'focus')
            : null,
        child: Container(
          width: double.infinity,
          height: 50,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: isEnabled
                ? const LinearGradient(
              colors: [Color(0xFF6B50F6), Color(0xFF8A6CF7)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            )
                : null,
            color: isEnabled ? null : AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(32),
            boxShadow: isEnabled
                ? [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.35),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ]
                : null,
          ),
          child: Text(
            isEnabled ? 'Start Focus' : 'Focusing Together',
            style: TextStyle(
              color: isEnabled ? Colors.white : AppColors.textMuted,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
        ),
      ),
    );
  }

  // ─── Members Section ──────────────────────────────────────────────────────

  Widget _buildMembersSection(RoomProvider room) {
    final members = room.currentRoom!.members;
    final ownerId = room.currentRoom!.ownerId;
    final session = room.roomSession;
    final sessionStatus = session?.status ?? 'IDLE';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Members',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary),
              ),
              Icon(Icons.filter_list_rounded,
                  color: AppColors.textSecondary, size: 20),
            ],
          ),
          const SizedBox(height: 12),
          // Member list
          ...members.map((m) => _buildMemberCard(m, sessionStatus, m.userId == ownerId)),
        ],
      ),
    );
  }

  Widget _buildMemberCard(RoomMember member, String sessionStatus, bool isOwner) {
    final isFocusing = sessionStatus == 'FOCUSING';
    final isBreak    = sessionStatus == 'BREAK';
    final isActive   = isFocusing || isBreak;

    final statusColor = isFocusing
        ? const Color(0xFF4CAF50)
        : isBreak
        ? const Color(0xFFFFB74D)
        : AppColors.textMuted;

    final statusLabel = isFocusing
        ? 'Focusing'
        : isBreak
        ? 'On Break'
        : 'Idle';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF16162A),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: AppColors.surfaceLight.withOpacity(0.6), width: 1),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withOpacity(0.25),
              border: Border.all(
                  color: AppColors.primary.withOpacity(0.4), width: 1.5),
            ),
            alignment: Alignment.center,
            child: Text(
              member.displayName.isNotEmpty
                  ? member.displayName[0].toUpperCase()
                  : '?',
              style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 16),
            ),
          ),
          const SizedBox(width: 14),
          // Name + status
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    member.displayName,
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 15),
                  ),
                  if (isOwner) ...[
                    const SizedBox(width: 5),
                    const Text('👑', style: TextStyle(fontSize: 11)),
                  ],
                ],
              ),
              const SizedBox(height: 3),
              Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: statusColor,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    statusLabel,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Owner controls khi đang FOCUSING ────────────────────────────────────

  Widget _buildFocusingOwnerControls(
      BuildContext context, RoomProvider room, RoomSession? session) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          // Take Break — filled gradient button (primary style)
          Expanded(
            child: GestureDetector(
              onTap: () => _showDurationPicker(context, room, 'break'),
              child: Container(
                height: 50,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6B50F6), Color(0xFF8A6CF7)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.4),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Text(
                  'Take Break',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // End — dark outline button
          Expanded(
            child: GestureDetector(
              onTap: room.endSession,
              child: Container(
                height: 50,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E30),
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(
                    color: AppColors.surfaceLight,
                    width: 1.5,
                  ),
                ),
                child: const Text(
                  'End',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Duration Picker ──────────────────────────────────────────────────────

  void _showDurationPicker(
      BuildContext context, RoomProvider room, String type) {
    final options = [1, 5, 10, 15, 25, 30, 45, 50];
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
            Text(
                type == 'focus'
                    ? 'Focus duration'
                    : 'Break duration',
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: options
                  .map((min) => GestureDetector(
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
                      style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600)),
                ),
              ))
                  .toList(),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // ─── Leave Button ─────────────────────────────────────────────────────────

  Widget _buildLeaveButton(BuildContext context, RoomProvider room) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: GestureDetector(
        onTap: () => _confirmLeave(context, room),
        child: Container(
          width: double.infinity,
          height: 54,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.danger.withOpacity(0.15),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: AppColors.danger.withOpacity(0.35), width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.logout_rounded,
                  color: AppColors.danger, size: 18),
              SizedBox(width: 8),
              Text('Leave Room',
                  style: TextStyle(
                      color: AppColors.danger,
                      fontWeight: FontWeight.w600,
                      fontSize: 15)),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Confirm Leave Dialog ─────────────────────────────────────────────────

  void _confirmLeave(BuildContext context, RoomProvider room) {
    // Lưu navigator của screen trước khi mở dialog,
    // tránh dùng context sau khi dialog unmount gây lỗi pop không chạy
    final screenNavigator = Navigator.of(context);

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Leave Room?',
            style: TextStyle(color: AppColors.textPrimary)),
        content: const Text('You will exit this study session.',
            style: TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.textMuted)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(dialogCtx).pop(); // đóng dialog
              await room.leaveRoom();
              screenNavigator.pop(); // về lobby — dùng navigator đã lưu
            },
            child: const Text('Leave',
                style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
  }
}