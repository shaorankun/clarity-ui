import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/timer_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/circular_timer.dart';
import '../../tasks/providers/task_provider.dart';
import '../../rooms/providers/room_provider.dart';

// ─── Design tokens ────────────────────────────────────────────────────────────
const _kBg               = Color(0xFF12121D);
const _kSurface          = Color(0xFF1F1E2A);
const _kSurfaceHigh      = Color(0xFF292935);
const _kSurfaceContLow   = Color(0xFF1B1A26);
const _kPrimary          = Color(0xFFCEBDFF);
const _kPrimaryContainer = Color(0xFF6C3CE0);
const _kOnSurface        = Color(0xFFE3E0F1);
const _kOnSurfaceVar     = Color(0xFFCBC3D7);
const _kTertiary         = Color(0xFF00DBE9);
const _kSecondary        = Color(0xFFD2BBFF);
const _kOutlineVar       = Color(0xFF494455);
const _kGlass            = Color(0x991F1E2A);

class TimerScreen extends StatelessWidget {
  const TimerScreen({super.key});

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'morning';
    if (h < 17) return 'afternoon';
    return 'evening';
  }

  void _showTaskPicker(BuildContext context, TimerProvider timer) {
    // Gọi API lấy tasks mới nhất ngay khi mở sheet
    context.read<TaskProvider>().fetchTasks();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _kSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _TaskPickerSheet(timer: timer),
    );
  }

  @override
  Widget build(BuildContext context) {
    final timer  = context.watch<TimerProvider>();
    final room   = context.watch<RoomProvider>();
    final inRoom = room.currentRoom != null;
    final isFocus = timer.mode == TimerMode.focus;

    return Container(
      color: _kBg,
      child: SafeArea(
        child: Column(
          children: [
            _TopAppBar(greeting: 'Good ${_greeting()} 👋'),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [

                    // ── Mode chips — căn giữa đều ────────────────────────────
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: _kSurfaceContLow.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: _kOutlineVar.withOpacity(0.1), width: 1),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: TimerMode.values.map((m) {
                          final active = timer.mode == m;
                          return Expanded(
                            child: GestureDetector(
                              onTap: () => timer.setMode(m),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                decoration: BoxDecoration(
                                  color: active ? _kPrimaryContainer : Colors.transparent,
                                  borderRadius: BorderRadius.circular(999),
                                  boxShadow: active
                                      ? [BoxShadow(color: _kPrimaryContainer.withOpacity(0.2), blurRadius: 8)]
                                      : null,
                                ),
                                child: Text(
                                  m == TimerMode.focus
                                      ? 'FOCUS'
                                      : m == TimerMode.shortBreak
                                      ? 'SHORT BREAK'
                                      : 'LONG BREAK',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: active ? Colors.white : _kOnSurfaceVar.withOpacity(0.7),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ── Timer circle ─────────────────────────────────────────
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 280, height: 180,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(140),
                            boxShadow: [BoxShadow(color: _kPrimaryContainer.withOpacity(0.18), blurRadius: 80, spreadRadius: 10)],
                          ),
                        ),
                        _GlassTimerRing(
                          progress: timer.progress,
                          timeLabel: timer.timeLabel,
                          modeLabel: timer.modeLabel.toUpperCase(),
                          isRunning: timer.status == TimerStatus.running,
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),

                    // ── CTA buttons ──────────────────────────────────────────
                    // Focus mode idle: Select Task & Start (bắt chọn task)
                    // Break mode idle: Start button trực tiếp
                    // Running / paused: Pause + Abandon (cho tất cả mode)
                    if (timer.status == TimerStatus.idle) ...[
                      if (isFocus)
                        _SelectTaskStartButton(
                          timer: timer,
                          inRoom: inRoom,
                          onTap: inRoom ? null : () => _showTaskPicker(context, timer),
                        )
                      else
                        _BreakStartButton(
                          onTap: inRoom ? null : () => timer.start(inRoom: false),
                        ),
                      if (inRoom) ...[
                        const SizedBox(height: 10),
                        Text(
                          isFocus
                              ? 'Leave your study room to start a solo session'
                              : 'Leave your study room to start a solo break',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: _kOnSurfaceVar.withOpacity(0.6), fontSize: 12),
                        ),
                      ],
                    ] else
                      Row(
                        children: [
                          Expanded(
                            child: AppButton(
                              label: timer.status == TimerStatus.running ? 'Pause' : 'Resume',
                              onPressed: timer.status == TimerStatus.running ? timer.pause : timer.resume,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(child: AppButton(label: 'Abandon', outlined: true, onPressed: timer.abandon)),
                        ],
                      ),
                    const SizedBox(height: 28),

                    // ── Stats row ─────────────────────────────────────────────
                    _StatsRow(timer: timer),
                    const SizedBox(height: 28),

                    // ── Today's Tasks section ─────────────────────────────────
                    _TodaysTasksSection(timer: timer),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Top App Bar ──────────────────────────────────────────────────────────────
class _TopAppBar extends StatelessWidget {
  final String greeting;
  const _TopAppBar({required this.greeting});

  String _dateLabel() {
    final now = DateTime.now();
    const days   = ['Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday'];
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${days[now.weekday - 1]}, ${months[now.month - 1]} ${now.day}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: _kBg.withOpacity(0.9),
        border: Border(bottom: BorderSide(color: _kOutlineVar.withOpacity(0.2))),
      ),
      child: Row(
        children: [
          Icon(Icons.menu, color: _kPrimary, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(greeting, style: const TextStyle(color: _kOnSurface, fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: -0.2)),
                Text(_dateLabel(), style: TextStyle(color: _kOnSurfaceVar.withOpacity(0.7), fontSize: 12)),
              ],
            ),
          ),
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle, color: _kSurfaceHigh,
              border: Border.all(color: _kPrimary.withOpacity(0.2), width: 2),
            ),
            child: const Icon(Icons.person, color: _kOnSurfaceVar, size: 22),
          ),
        ],
      ),
    );
  }
}

// ─── Glass Timer Ring ─────────────────────────────────────────────────────────
class _GlassTimerRing extends StatelessWidget {
  final double progress;
  final String timeLabel;
  final String modeLabel;
  final bool   isRunning;

  const _GlassTimerRing({required this.progress, required this.timeLabel, required this.modeLabel, required this.isRunning});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 230, height: 230,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (isRunning)
            Container(
              width: 230, height: 230,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: _kPrimaryContainer.withOpacity(0.3), blurRadius: 60, spreadRadius: 10)],
              ),
            ),
          Container(
            width: 220, height: 220,
            decoration: BoxDecoration(
              shape: BoxShape.circle, color: _kGlass,
              border: Border.all(color: Colors.white.withOpacity(0.05)),
            ),
          ),
          SizedBox(width: 220, height: 220, child: CustomPaint(painter: _ArcPainter(progress: progress))),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(timeLabel, style: const TextStyle(color: _kOnSurface, fontSize: 56, fontWeight: FontWeight.w700, letterSpacing: -1.5, height: 1)),
              const SizedBox(height: 6),
              Text(modeLabel, style: const TextStyle(color: _kPrimary, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
            ],
          ),
        ],
      ),
    );
  }
}

class _ArcPainter extends CustomPainter {
  final double progress;
  const _ArcPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2, cy = size.height / 2, radius = size.width / 2 - 8;
    canvas.drawCircle(Offset(cx, cy), radius, Paint()..color = Colors.white.withOpacity(0.06)..style = PaintingStyle.stroke..strokeWidth = 8);
    if (progress > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, cy), radius: radius),
        -math.pi / 2, 2 * math.pi * progress, false,
        Paint()..color = _kPrimary..style = PaintingStyle.stroke..strokeWidth = 8..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_ArcPainter old) => old.progress != progress;
}

// ─── Select Task & Start button (Focus mode) ──────────────────────────────────
class _SelectTaskStartButton extends StatelessWidget {
  final TimerProvider timer;
  final bool inRoom;
  final VoidCallback? onTap;

  const _SelectTaskStartButton({required this.timer, required this.inRoom, this.onTap});

  @override
  Widget build(BuildContext context) {
    final hasTask = timer.selectedTaskTitle != null;
    return SizedBox(
      width: double.infinity, height: 56,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(hasTask ? Icons.task_alt : Icons.list_alt_outlined, size: 20),
        label: Text(
          hasTask ? timer.selectedTaskTitle! : 'Select Task & Start',
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: _kPrimaryContainer,
          foregroundColor: Colors.white,
          disabledBackgroundColor: _kSurface,
          disabledForegroundColor: _kOnSurfaceVar.withOpacity(0.4),
          shape: const StadiumBorder(),
          elevation: 0,
          shadowColor: Colors.transparent,
        ),
      ),
    );
  }
}

// ─── Start button (Break mode) ────────────────────────────────────────────────
class _BreakStartButton extends StatelessWidget {
  final VoidCallback? onTap;
  const _BreakStartButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity, height: 56,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: const Icon(Icons.play_arrow_rounded, size: 22),
        label: const Text(
          'Start Break',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: _kPrimaryContainer,
          foregroundColor: Colors.white,
          disabledBackgroundColor: _kSurface,
          disabledForegroundColor: _kOnSurfaceVar.withOpacity(0.4),
          shape: const StadiumBorder(),
          elevation: 0,
          shadowColor: Colors.transparent,
        ),
      ),
    );
  }
}

// ─── Stats Row ────────────────────────────────────────────────────────────────
class _StatsRow extends StatelessWidget {
  final TimerProvider timer;
  const _StatsRow({required this.timer});

  @override
  Widget build(BuildContext context) {
    final totalSecs  = timer.focusedSeconds;
    final focusedLabel = totalSecs >= 3600
        ? '${totalSecs ~/ 3600}h ${(totalSecs % 3600) ~/ 60}m'
        : totalSecs >= 60
        ? '${totalSecs ~/ 60}m'
        : '0m';
    return Row(
      children: [
        _StatCard(icon: Icons.schedule_outlined, iconColor: _kPrimary, value: timer.sessions > 0 ? focusedLabel : '0m', label: 'FOCUSED'),
        const SizedBox(width: 8),
        _StatCard(icon: Icons.bolt, iconColor: _kTertiary, value: '${timer.sessions}', label: 'SESSIONS'),
        const SizedBox(width: 8),
        Consumer<TaskProvider>(
          builder: (_, tasks, __) => _StatCard(icon: Icons.task_alt, iconColor: _kSecondary, value: '${tasks.completed.length}/${tasks.all.length}', label: 'TASKS'),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color    iconColor;
  final String   value;
  final String   label;

  const _StatCard({required this.icon, required this.iconColor, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: _kGlass, borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: iconColor, size: 20),
            const SizedBox(height: 6),
            Text(value, style: const TextStyle(color: _kOnSurface, fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(color: _kOnSurfaceVar.withOpacity(0.7), fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.8)),
          ],
        ),
      ),
    );
  }
}

// ─── Today's Tasks Section ────────────────────────────────────────────────────
class _TodaysTasksSection extends StatelessWidget {
  final TimerProvider timer;
  const _TodaysTasksSection({required this.timer});

  @override
  Widget build(BuildContext context) {
    return Consumer<TaskProvider>(
      builder: (context, tasks, _) {
        final completed   = tasks.completed;
        final activeTitle = timer.selectedTaskTitle;
        final isRunning   = timer.status != TimerStatus.idle;
        final isBreak     = timer.mode == TimerMode.shortBreak || timer.mode == TimerMode.longBreak;
        // Free focus session: focus mode đang chạy/paused nhưng không có task được chọn
        final isFreeFocus = isRunning && !isBreak && activeTitle == null;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Current Task",
              style: TextStyle(color: _kOnSurface, fontSize: 22, fontWeight: FontWeight.w600, letterSpacing: -0.3),
            ),
            const SizedBox(height: 12),

            // Đang trong break
            if (isRunning && isBreak) ...[
              _BreakCard(isShort: timer.mode == TimerMode.shortBreak),
              const SizedBox(height: 8),
            ]
            // Đang free focus session
            else if (isFreeFocus) ...[
              const _FreeFocusCard(),
              const SizedBox(height: 8),
            ]
            // Đang có task cụ thể được chọn
            else if (activeTitle != null) ...[
                _ActiveTaskCard(title: activeTitle),
                const SizedBox(height: 8),
              ],

            if (tasks.isLoading)
              const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator(color: _kPrimary)))
            else if (completed.isEmpty && activeTitle == null && !isFreeFocus && !(isRunning && isBreak))
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: _kGlass, borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.05)),
                ),
                child: Text(
                  'No tasks yet. Select a task above to get started!',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: _kOnSurfaceVar.withOpacity(0.6), fontSize: 13),
                ),
              )
            else if (completed.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text('Completed', style: TextStyle(color: _kOnSurfaceVar.withOpacity(0.5), fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.8)),
                ),
                ...completed.take(5).map((task) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _CompletedTaskItem(title: task.title, subtitle: task.label),
                )),
              ],
          ],
        );
      },
    );
  }
}

// ─── Break Card ───────────────────────────────────────────────────────────────
class _BreakCard extends StatelessWidget {
  final bool isShort;
  const _BreakCard({required this.isShort});

  @override
  Widget build(BuildContext context) {
    const breakColor = Color(0xFF4DD0E1); // cyan nhạt cho break
    final label = isShort ? 'Short Break' : 'Long Break';
    final subtitle = isShort ? 'Take a quick 5-minute rest' : 'Relax — you earned a long break';
    final icon = isShort ? Icons.coffee_outlined : Icons.weekend_outlined;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: breakColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: breakColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 24, height: 24,
            decoration: BoxDecoration(
              color: breakColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: breakColor.withOpacity(0.6)),
            ),
            child: Icon(icon, color: breakColor, size: 14),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: _kOnSurface, fontSize: 15, fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(subtitle, style: TextStyle(color: breakColor.withOpacity(0.7), fontSize: 12, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: breakColor.withOpacity(0.15), borderRadius: BorderRadius.circular(999)),
            child: const Text('BREAK', style: TextStyle(color: breakColor, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.8)),
          ),
        ],
      ),
    );
  }
}

// ─── Free Focus Session Card ──────────────────────────────────────────────────
class _FreeFocusCard extends StatelessWidget {
  const _FreeFocusCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kPrimaryContainer.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kPrimary.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 24, height: 24,
            decoration: BoxDecoration(
              color: _kPrimaryContainer.withOpacity(0.4),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: _kPrimary.withOpacity(0.6)),
            ),
            child: const Icon(Icons.self_improvement, color: _kPrimary, size: 14),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Free Focus Session', style: TextStyle(color: _kOnSurface, fontSize: 15, fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text('In Progress', style: TextStyle(color: _kPrimary.withOpacity(0.7), fontSize: 12, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: _kPrimary.withOpacity(0.15), borderRadius: BorderRadius.circular(999)),
            child: const Text('ACTIVE', style: TextStyle(color: _kPrimary, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.8)),
          ),
        ],
      ),
    );
  }
}

// ─── Active Task Card ─────────────────────────────────────────────────────────
class _ActiveTaskCard extends StatelessWidget {
  final String title;
  const _ActiveTaskCard({required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kPrimaryContainer.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kPrimary.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 24, height: 24,
            decoration: BoxDecoration(
              color: _kPrimaryContainer.withOpacity(0.4),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: _kPrimary.withOpacity(0.6)),
            ),
            child: const Icon(Icons.timer_outlined, color: _kPrimary, size: 14),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: _kOnSurface, fontSize: 15, fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text('In Progress', style: TextStyle(color: _kPrimary.withOpacity(0.7), fontSize: 12, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: _kPrimary.withOpacity(0.15), borderRadius: BorderRadius.circular(999)),
            child: const Text('ACTIVE', style: TextStyle(color: _kPrimary, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.8)),
          ),
        ],
      ),
    );
  }
}

// ─── Completed Task Item ──────────────────────────────────────────────────────
class _CompletedTaskItem extends StatelessWidget {
  final String  title;
  final String? subtitle;

  const _CompletedTaskItem({required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 0.7,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _kGlass, borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Row(
          children: [
            Container(
              width: 24, height: 24,
              decoration: BoxDecoration(color: _kPrimary, borderRadius: BorderRadius.circular(6)),
              child: const Icon(Icons.check, color: Color(0xFF390094), size: 14),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(color: _kOnSurface, fontSize: 15, decoration: TextDecoration.lineThrough, decorationColor: _kPrimary.withOpacity(0.5))),
                  if (subtitle != null && subtitle!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(subtitle!, style: TextStyle(color: _kOnSurfaceVar.withOpacity(0.7), fontSize: 12)),
                  ],
                ],
              ),
            ),
            Icon(Icons.more_vert, color: _kOnSurfaceVar.withOpacity(0.3), size: 18),
          ],
        ),
      ),
    );
  }
}

// ─── HomeSwitcherNotifier ─────────────────────────────────────────────────────
class HomeSwitcherNotifier extends InheritedWidget {
  final void Function(int index) switchTo;

  const HomeSwitcherNotifier({
    super.key,
    required this.switchTo,
    required super.child,
  });

  static HomeSwitcherNotifier? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<HomeSwitcherNotifier>();

  @override
  bool updateShouldNotify(HomeSwitcherNotifier old) => false;
}

// ─── Task Picker Sheet ────────────────────────────────────────────────────────
class _TaskPickerSheet extends StatelessWidget {
  final TimerProvider timer;
  const _TaskPickerSheet({required this.timer});

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height * 0.7;
    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              width: 40, height: 4,
              decoration: BoxDecoration(color: _kOutlineVar.withOpacity(0.4), borderRadius: BorderRadius.circular(2)),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Select a Task', style: TextStyle(color: _kOnSurface, fontSize: 18, fontWeight: FontWeight.w600)),
              IconButton(icon: Icon(Icons.close, color: _kOnSurfaceVar.withOpacity(0.7)), onPressed: () => Navigator.pop(context)),
            ],
          ),
          const SizedBox(height: 8),
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.radio_button_unchecked, color: _kOnSurfaceVar.withOpacity(0.6)),
                    title: Text('Free focus session', style: TextStyle(color: _kOnSurfaceVar.withOpacity(0.8), fontStyle: FontStyle.italic)),
                    onTap: () {
                      timer.selectTask(null, null);
                      Navigator.pop(context);
                      timer.start(inRoom: false);
                    },
                  ),
                  Divider(color: _kOutlineVar.withOpacity(0.4)),
                  Consumer<TaskProvider>(
                    builder: (context, tasks, _) {
                      if (tasks.isLoading) {
                        return const Center(child: Padding(padding: EdgeInsets.all(20.0), child: CircularProgressIndicator(color: _kPrimary)));
                      }
                      if (tasks.pending.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Text('No pending tasks', style: TextStyle(color: _kOnSurfaceVar.withOpacity(0.6), fontSize: 13)),
                        );
                      }
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: tasks.pending.map((task) {
                          final selected = timer.selectedTaskId == task.id;
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Icon(
                              selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                              color: selected ? _kPrimary : _kOnSurfaceVar.withOpacity(0.6),
                            ),
                            title: Text(task.title, style: const TextStyle(color: _kOnSurface)),
                            subtitle: task.label != null ? Text(task.label!, style: TextStyle(color: _kOnSurfaceVar.withOpacity(0.6), fontSize: 12)) : null,
                            onTap: () {
                              timer.selectTask(task.id, task.title);
                              Navigator.pop(context);
                              timer.start(inRoom: false);
                            },
                          );
                        }).toList(),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}