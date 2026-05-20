import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/task_provider.dart';
import '../models/task_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../timer/providers/timer_provider.dart';
import '../../auth/providers/auth_provider.dart';

// ── Design tokens — đồng nhất với stats_screen & timer_screen ────────────────
class _C {
  static const bg                   = Color(0xFF12121D);
  static const surface              = Color(0xFF1F1E2A);
  static const surfaceContainerHigh = Color(0xFF292935);
  static const surfaceVariant       = Color(0xFF343440);
  static const primary              = Color(0xFFCEBDFF);
  static const primaryContainer     = Color(0xFF6C3CE0);
  static const onPrimaryContainer   = Color(0xFFE2D6FF);
  static const secondary            = Color(0xFFD2BBFF);
  static const tertiary             = Color(0xFF00DBE9);
  static const onSurface            = Color(0xFFE3E0F1);
  static const onSurfaceVariant     = Color(0xFFCBC3D7);
  static const outlineVariant       = Color(0xFF494455);

  static LinearGradient get glassCard => const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xB31F1E2A), Color(0xCC0D0D18)],
  );
}

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});
  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  int _filter = 0;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<TaskProvider>().fetchTasks());
  }

  List<TaskModel> _filtered(TaskProvider p) {
    if (_filter == 1) return p.pending;
    if (_filter == 2) return p.completed;
    return p.all;
  }

  @override
  Widget build(BuildContext context) {
    final tasks = context.watch<TaskProvider>();
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0F0F1A), Color(0xFF12121D)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: SafeArea(
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _TopAppBar(),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),

                      // ── Section Header — giống stats_screen ──────────────
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Tasks',
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w700,
                                color: _C.onSurface,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _dateLabel(),
                              style: const TextStyle(
                                fontSize: 13,
                                color: _C.outlineVariant,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // ── Filter chips ──────────────────────────────────────
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Row(children: [
                          _FilterChip(label: 'All',       count: tasks.all.length,       index: 0, selected: _filter, onTap: (i) => setState(() => _filter = i)),
                          const SizedBox(width: 8),
                          _FilterChip(label: 'Pending',   count: tasks.pending.length,   index: 1, selected: _filter, onTap: (i) => setState(() => _filter = i)),
                          const SizedBox(width: 8),
                          _FilterChip(label: 'Done',      count: tasks.completed.length, index: 2, selected: _filter, onTap: (i) => setState(() => _filter = i)),
                        ]),
                      ),
                      const SizedBox(height: 16),

                      // ── Task list ─────────────────────────────────────────
                      Expanded(
                        child: tasks.isLoading
                            ? const Center(child: CircularProgressIndicator(color: _C.primary, strokeWidth: 2))
                            : _filtered(tasks).isEmpty
                            ? _EmptyState(filter: _filter)
                            : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(24, 0, 24, 120),
                          itemCount: _filtered(tasks).length,
                          itemBuilder: (_, i) => _TaskCard(task: _filtered(tasks)[i]),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // ── FAB ───────────────────────────────────────────────────────
            Positioned(
              right: 20, bottom: 24,
              child: GestureDetector(
                onTap: () => _showAddTask(context),
                child: Container(
                  width: 56, height: 56,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF8B6CF0), Color(0xFF6C3CE0)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: _C.primaryContainer.withOpacity(0.45), blurRadius: 24, offset: const Offset(0, 8)),
                    ],
                  ),
                  child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _dateLabel() {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekEnd   = weekStart.add(const Duration(days: 6));
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${months[weekStart.month - 1]} ${weekStart.day} — ${months[weekEnd.month - 1]} ${weekEnd.day}, ${weekEnd.year}';
  }

  void _showAddTask(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _C.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (_) => const _AddTaskSheet(),
    );
  }
}

// ── Top App Bar — đồng nhất với stats_screen ──────────────────────────────────
class _TopAppBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final auth    = context.watch<AuthProvider>();
    final user    = auth.user;
    final initial = (user?.displayName.isNotEmpty == true)
        ? user!.displayName[0].toUpperCase()
        : '?';

    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: const Color(0xFF12121D).withOpacity(0.8),
        border: Border(
          bottom: BorderSide(color: Colors.white.withOpacity(0.05), width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6C3CE0).withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            GestureDetector(
              onTap: () {},
              child: const Icon(Icons.menu, color: _C.primary, size: 24),
            ),
            const Text(
              'Clarity',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: _C.primary,
                letterSpacing: -0.3,
              ),
            ),
            Container(
              width: 34, height: 34,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF6C3CE0).withOpacity(0.35),
                border: Border.all(color: _C.primary.withOpacity(0.2), width: 1.5),
              ),
              child: Center(
                child: Text(
                  initial,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _C.primary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Filter Chip ───────────────────────────────────────────────────────────────
class _FilterChip extends StatelessWidget {
  final String label; final int count, index, selected;
  final ValueChanged<int> onTap;
  const _FilterChip({required this.label, required this.count, required this.index, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final active = selected == index;
    return GestureDetector(
      onTap: () => onTap(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: active ? LinearGradient(
            colors: [_C.primaryContainer.withOpacity(0.30), _C.primaryContainer.withOpacity(0.15)],
            begin: Alignment.topLeft, end: Alignment.bottomRight,
          ) : null,
          color: active ? null : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: active ? _C.primary.withOpacity(0.40) : _C.outlineVariant.withOpacity(0.40),
          ),
          boxShadow: active ? [BoxShadow(color: _C.primaryContainer.withOpacity(0.25), blurRadius: 12)] : null,
        ),
        child: Text(
          '$label ($count)',
          style: TextStyle(
            color: active ? _C.primary : _C.onSurfaceVariant,
            fontSize: 13,
            fontWeight: active ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

// ── Glass Card container — giống stats_screen ─────────────────────────────────
class _GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final bool highlighted;

  const _GlassCard({
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        gradient: _C.glassCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: highlighted ? _C.primary.withOpacity(0.30) : Colors.white.withOpacity(0.05),
          width: highlighted ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: highlighted
                ? _C.primaryContainer.withOpacity(0.20)
                : const Color(0xFF6C3CE0).withOpacity(0.05),
            blurRadius: highlighted ? 20 : 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

// ── Task Card ─────────────────────────────────────────────────────────────────
class _TaskCard extends StatelessWidget {
  final TaskModel task;
  const _TaskCard({required this.task});

  @override
  Widget build(BuildContext context) {
    final taskProvider  = context.read<TaskProvider>();
    final timerProvider = context.watch<TimerProvider>();
    final isFocusing    = timerProvider.selectedTaskId == task.id && timerProvider.status == TimerStatus.running;

    final statusText  = isFocusing ? 'FOCUSING NOW' : task.completed ? 'COMPLETED' : 'TO DO';
    final statusColor = isFocusing ? _C.secondary : task.completed ? _C.tertiary : _C.outlineVariant;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Dismissible(
        key: Key(task.id),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          decoration: BoxDecoration(
            color: AppColors.danger.withOpacity(0.15),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.danger.withOpacity(0.3)),
          ),
          child: const Icon(Icons.delete_outline_rounded, color: AppColors.danger),
        ),
        onDismissed: (_) => taskProvider.deleteTask(task.id),
        child: _GlassCard(
          highlighted: isFocusing,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Checkbox
              GestureDetector(
                onTap: () => taskProvider.toggleTask(task.id),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 22, height: 22,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    color: task.completed ? _C.primaryContainer : Colors.transparent,
                    border: Border.all(
                      color: task.completed ? _C.primaryContainer : _C.outlineVariant,
                      width: 2,
                    ),
                  ),
                  child: task.completed
                      ? const Icon(Icons.check_rounded, color: _C.onPrimaryContainer, size: 13)
                      : null,
                ),
              ),
              const SizedBox(width: 14),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      statusText,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                        color: statusColor,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      task.title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: task.completed
                            ? _C.onSurfaceVariant.withOpacity(0.45)
                            : _C.onSurface,
                        decoration: task.completed ? TextDecoration.lineThrough : null,
                        decorationColor: _C.outlineVariant,
                      ),
                    ),
                    if (task.label != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            width: 4, height: 4,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: task.completed
                                  ? _C.outlineVariant.withOpacity(0.4)
                                  : _C.primary.withOpacity(0.6),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            task.label!,
                            style: TextStyle(
                              fontSize: 12,
                              color: task.completed
                                  ? _C.outlineVariant.withOpacity(0.40)
                                  : _C.primary.withOpacity(0.65),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),

              // Trailing
              isFocusing
                  ? Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _C.primary.withOpacity(0.15),
                ),
                child: const Icon(Icons.play_arrow_rounded, color: _C.primary, size: 20),
              )
                  : GestureDetector(
                onTap: task.completed ? null : () => _showEdit(context, task),
                child: Icon(
                  Icons.edit_outlined,
                  color: task.completed
                      ? _C.outlineVariant.withOpacity(0.25)
                      : _C.onSurfaceVariant.withOpacity(0.55),
                  size: 18,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEdit(BuildContext context, TaskModel task) {
    showModalBottomSheet(
      context: context, isScrollControlled: true,
      backgroundColor: _C.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (_) => _EditTaskSheet(task: task),
    );
  }
}

// ── Empty State ───────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final int filter;
  const _EmptyState({required this.filter});

  @override
  Widget build(BuildContext context) {
    final icon    = filter == 2 ? Icons.check_circle_outline_rounded : Icons.format_list_bulleted_rounded;
    final label   = filter == 2 ? 'No completed tasks' : filter == 1 ? 'All caught up!' : 'No tasks yet';
    final sub     = filter == 2
        ? 'Complete a task to see it here'
        : filter == 1
        ? 'You\'ve completed all your tasks'
        : 'Tap + to add your first task';

    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 72, height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [_C.primaryContainer.withOpacity(0.20), _C.primaryContainer.withOpacity(0.08)],
              begin: Alignment.topLeft, end: Alignment.bottomRight,
            ),
            border: Border.all(color: _C.primary.withOpacity(0.20)),
          ),
          child: Icon(icon, color: _C.primary, size: 30),
        ),
        const SizedBox(height: 20),
        Text(label, style: const TextStyle(color: _C.onSurface, fontSize: 18, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Text(sub, style: const TextStyle(color: _C.onSurfaceVariant, fontSize: 13)),
      ]),
    );
  }
}

// ── Input Field — đồng nhất style ─────────────────────────────────────────────
class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final bool autofocus;
  const _InputField({required this.controller, required this.hint, this.autofocus = false});

  @override
  Widget build(BuildContext context) => TextField(
    controller: controller, autofocus: autofocus,
    style: const TextStyle(color: _C.onSurface, fontSize: 15),
    decoration: InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: _C.onSurfaceVariant.withOpacity(0.45), fontSize: 15),
      filled: true,
      fillColor: _C.surfaceContainerHigh,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: _C.outlineVariant.withOpacity(0.35))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: _C.outlineVariant.withOpacity(0.35))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _C.primary, width: 1.5)),
    ),
  );
}

// ── Sheet drag handle ─────────────────────────────────────────────────────────
Widget _dragHandle() => Center(
  child: Container(
    width: 40, height: 4,
    decoration: BoxDecoration(color: _C.outlineVariant.withOpacity(0.5), borderRadius: BorderRadius.circular(2)),
  ),
);

// ── Add Task Sheet ─────────────────────────────────────────────────────────────
class _AddTaskSheet extends StatefulWidget {
  const _AddTaskSheet();
  @override
  State<_AddTaskSheet> createState() => _AddTaskSheetState();
}

class _AddTaskSheetState extends State<_AddTaskSheet> {
  final _titleCtrl = TextEditingController();
  final _labelCtrl = TextEditingController();
  final _suggestions = ['Study 📚', 'Project 💼', 'Personal 🌿', 'Health 💪'];
  String? _selectedLabel;

  @override
  void dispose() { _titleCtrl.dispose(); _labelCtrl.dispose(); super.dispose(); }

  Future<void> _save() async {
    if (_titleCtrl.text.trim().isEmpty) return;
    final label = _labelCtrl.text.trim().isNotEmpty ? _labelCtrl.text.trim() : _selectedLabel;
    await context.read<TaskProvider>().addTask(_titleCtrl.text.trim(), label: label);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(24, 20, 24, MediaQuery.of(context).viewInsets.bottom + 24),
    child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
      _dragHandle(),
      const SizedBox(height: 20),

      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        const Text('New Task', style: TextStyle(color: _C.onSurface, fontSize: 20, fontWeight: FontWeight.w600)),
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            width: 32, height: 32,
            decoration: BoxDecoration(shape: BoxShape.circle, color: _C.surfaceVariant),
            child: Icon(Icons.close_rounded, color: _C.onSurfaceVariant.withOpacity(0.7), size: 17),
          ),
        ),
      ]),
      const SizedBox(height: 20),

      _InputField(controller: _titleCtrl, hint: 'What do you need to do?', autofocus: true),
      const SizedBox(height: 12),
      _InputField(controller: _labelCtrl, hint: 'Label (optional)'),
      const SizedBox(height: 14),

      // Label suggestions
      Wrap(spacing: 8, runSpacing: 8, children: _suggestions.map((s) {
        final active = _selectedLabel == s;
        return GestureDetector(
          onTap: () => setState(() { _selectedLabel = active ? null : s; if (!active) _labelCtrl.clear(); }),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              gradient: active ? LinearGradient(
                colors: [_C.primaryContainer.withOpacity(0.30), _C.primaryContainer.withOpacity(0.15)],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ) : null,
              color: active ? null : _C.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: active ? _C.primary.withOpacity(0.40) : _C.outlineVariant.withOpacity(0.35)),
            ),
            child: Text(s, style: TextStyle(color: active ? _C.primary : _C.onSurfaceVariant, fontSize: 13)),
          ),
        );
      }).toList()),
      const SizedBox(height: 24),

      context.watch<TaskProvider>().isLoading
          ? const Center(child: CircularProgressIndicator(color: _C.primary, strokeWidth: 2))
          : GestureDetector(
        onTap: _save,
        child: Container(
          width: double.infinity, height: 52, alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF8B6CF0), Color(0xFF6C3CE0)],
              begin: Alignment.topLeft, end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [BoxShadow(color: _C.primaryContainer.withOpacity(0.40), blurRadius: 20, offset: const Offset(0, 6))],
          ),
          child: const Text('Save Task', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15)),
        ),
      ),
    ]),
  );
}

// ── Edit Task Sheet ───────────────────────────────────────────────────────────
class _EditTaskSheet extends StatefulWidget {
  final TaskModel task;
  const _EditTaskSheet({required this.task});
  @override
  State<_EditTaskSheet> createState() => _EditTaskSheetState();
}

class _EditTaskSheetState extends State<_EditTaskSheet> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _labelCtrl;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.task.title);
    _labelCtrl = TextEditingController(text: widget.task.label ?? '');
  }

  @override
  void dispose() { _titleCtrl.dispose(); _labelCtrl.dispose(); super.dispose(); }

  Future<void> _save() async {
    if (_titleCtrl.text.trim().isEmpty) return;
    await context.read<TaskProvider>().updateTask(
      widget.task.id,
      title: _titleCtrl.text.trim(),
      label: _labelCtrl.text.trim().isNotEmpty ? _labelCtrl.text.trim() : null,
    );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(24, 20, 24, MediaQuery.of(context).viewInsets.bottom + 24),
    child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
      _dragHandle(),
      const SizedBox(height: 20),

      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        const Text('Edit Task', style: TextStyle(color: _C.onSurface, fontSize: 20, fontWeight: FontWeight.w600)),
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            width: 32, height: 32,
            decoration: BoxDecoration(shape: BoxShape.circle, color: _C.surfaceVariant),
            child: Icon(Icons.close_rounded, color: _C.onSurfaceVariant.withOpacity(0.7), size: 17),
          ),
        ),
      ]),
      const SizedBox(height: 20),

      _InputField(controller: _titleCtrl, hint: 'Task title...', autofocus: true),
      const SizedBox(height: 12),
      _InputField(controller: _labelCtrl, hint: 'Label (optional)'),
      const SizedBox(height: 24),

      GestureDetector(
        onTap: _save,
        child: Container(
          width: double.infinity, height: 52, alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF8B6CF0), Color(0xFF6C3CE0)],
              begin: Alignment.topLeft, end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [BoxShadow(color: _C.primaryContainer.withOpacity(0.40), blurRadius: 20, offset: const Offset(0, 6))],
          ),
          child: const Text('Save Changes', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15)),
        ),
      ),
    ]),
  );
}