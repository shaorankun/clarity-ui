import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/timer_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/circular_timer.dart';
import '../../tasks/providers/task_provider.dart';
import '../../rooms/providers/room_provider.dart';

class TimerScreen extends StatelessWidget {
  const TimerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final timer = context.watch<TimerProvider>();
    final room = context.watch<RoomProvider>();
    final inRoom = room.currentRoom != null;

    return Container(
      decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 24),

              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Good ${_greeting()} 👋',
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                      const Text('Stay focused',
                          style: TextStyle(color: AppColors.textPrimary,
                              fontSize: 18, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  // Streak chip
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        const Text('🔥', style: TextStyle(fontSize: 14)),
                        const SizedBox(width: 4),
                        Text('${timer.sessions} today',
                            style: const TextStyle(color: AppColors.textPrimary,
                                fontSize: 13, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ],
              ),

              const Spacer(),

              // Mode chips
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: TimerMode.values.map((m) {
                    final active = timer.mode == m;
                    return GestureDetector(
                      onTap: () => timer.setMode(m),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: active ? AppColors.primary : Colors.transparent,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Text(
                          m == TimerMode.focus ? 'Focus'
                              : m == TimerMode.shortBreak ? 'Short Break' : 'Long Break',
                          style: TextStyle(
                            color: active ? Colors.white : AppColors.textMuted,
                            fontSize: 13,
                            fontWeight: active ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 40),

              // Timer circle
              CircularTimer(
                progress:  timer.progress,
                timeLabel: timer.timeLabel,
                isRunning: timer.status == TimerStatus.running,
              ),

              const SizedBox(height: 40),

              // Selected task chip
              GestureDetector(
                onTap: () => _showTaskPicker(context, timer),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.surfaceLight),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.task_alt_outlined,
                          color: AppColors.textMuted, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        timer.selectedTaskTitle ?? 'No task selected',
                        style: TextStyle(
                          color: timer.selectedTaskTitle != null
                              ? AppColors.textPrimary : AppColors.textMuted,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.keyboard_arrow_down,
                          color: AppColors.textMuted, size: 16),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Controls
              if (timer.status == TimerStatus.idle)
                Column(
                  children: [
                    AppButton(
                      label: 'Start Focus',
                      onPressed: inRoom ? null : () => timer.start(inRoom: false),
                    ),
                    if (inRoom) ...[
                      const SizedBox(height: 8),
                      const Text(
                        'Leave your study room to start a solo session',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                      ),
                    ],
                  ],
                )
              else
                Row(
                  children: [
                    Expanded(
                      child: AppButton(
                        label: timer.status == TimerStatus.running ? 'Pause' : 'Resume',
                        onPressed: timer.status == TimerStatus.running
                            ? timer.pause : timer.resume,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppButton(
                        label: 'Abandon',
                        outlined: true,
                        onPressed: timer.abandon,
                      ),
                    ),
                  ],
                ),

              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'morning';
    if (h < 17) return 'afternoon';
    return 'evening';
  }

  void _showTaskPicker(BuildContext context, TimerProvider timer) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _TaskPickerSheet(timer: timer),
    );
  }
}

class _TaskPickerSheet extends StatelessWidget {
  final TimerProvider timer;
  const _TaskPickerSheet({required this.timer});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Select a Task',
                  style: TextStyle(color: AppColors.textPrimary,
                      fontSize: 18, fontWeight: FontWeight.w600)),
              IconButton(
                icon: const Icon(Icons.close, color: AppColors.textMuted),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // No task option
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.radio_button_unchecked,
                color: AppColors.textMuted),
            title: const Text('Free focus session',
                style: TextStyle(color: AppColors.textSecondary,
                    fontStyle: FontStyle.italic)),
            onTap: () {
              timer.selectTask(null, null);
              Navigator.pop(context);
            },
          ),

          const Divider(color: AppColors.surfaceLight),
          const SizedBox(height: 8),

          // Will be populated with real tasks in Giai đoạn 5
          Consumer<TaskProvider>(
            builder: (context, tasks, _) {
              if (tasks.isLoading) {
                return const Center(child: CircularProgressIndicator(
                    color: AppColors.primary));
              }
              if (tasks.pending.isEmpty) {
                return const Center(
                  child: Text('No pending tasks',
                      style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
                );
              }
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: tasks.pending.map((task) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    timer.selectedTaskId == task.id
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                    color: timer.selectedTaskId == task.id
                        ? AppColors.primary : AppColors.textMuted,
                  ),
                  title: Text(task.title,
                      style: const TextStyle(color: AppColors.textPrimary)),
                  subtitle: task.label != null
                      ? Text(task.label!,
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 12))
                      : null,
                  onTap: () {
                    timer.selectTask(task.id, task.title);
                    Navigator.pop(context);
                  },
                )).toList(),
              );
            },
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}