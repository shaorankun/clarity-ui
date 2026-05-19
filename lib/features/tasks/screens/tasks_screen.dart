import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/task_provider.dart';
import '../models/task_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../timer/providers/timer_provider.dart';

// ── Design tokens from task_list_dark_updated_style ──────────────────────────
class _C {
  static const background           = Color(0xFF12121D);
  static const surfaceContainer     = Color(0xFF1F1E2A);
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
      color: _C.background,
      child: SafeArea(
        child: Stack(
          children: [
            // Background glow orbs
            Positioned(
              top: -80, right: -80,
              child: _GlowOrb(color: _C.primaryContainer.withOpacity(0.10), size: 280),
            ),
            Positioned(
              bottom: 60, left: -120,
              child: _GlowOrb(color: _C.secondary.withOpacity(0.05), size: 380),
            ),

            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _TopAppBar(),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: const Text(
                    'Tasks',
                    style: TextStyle(
                      fontSize: 24, fontWeight: FontWeight.w600,
                      color: _C.onSurface, fontFamily: 'SpaceGrotesk', letterSpacing: -0.3,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(children: [
                    _Chip(label: 'All',       count: tasks.all.length,       index: 0, selected: _filter, onTap: (i) => setState(() => _filter = i)),
                    const SizedBox(width: 8),
                    _Chip(label: 'Pending',   count: tasks.pending.length,   index: 1, selected: _filter, onTap: (i) => setState(() => _filter = i)),
                    const SizedBox(width: 8),
                    _Chip(label: 'Completed', count: tasks.completed.length, index: 2, selected: _filter, onTap: (i) => setState(() => _filter = i)),
                  ]),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: tasks.isLoading
                      ? const Center(child: CircularProgressIndicator(color: _C.primary, strokeWidth: 2))
                      : _filtered(tasks).isEmpty
                      ? _EmptyState()
                      : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 120),
                    itemCount: _filtered(tasks).length,
                    itemBuilder: (_, i) => _TaskCard(task: _filtered(tasks)[i]),
                  ),
                ),
              ],
            ),

            // FAB
            Positioned(
              right: 20, bottom: 24,
              child: GestureDetector(
                onTap: () => _showAddTask(context),
                child: Container(
                  width: 56, height: 56,
                  decoration: BoxDecoration(
                    color: _C.primaryContainer,
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: _C.primaryContainer.withOpacity(0.40), blurRadius: 30, offset: const Offset(0, 8))],
                  ),
                  child: const Icon(Icons.add_rounded, color: _C.onPrimaryContainer, size: 28),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddTask(BuildContext context) {
    showModalBottomSheet(
      context: context, isScrollControlled: true,
      backgroundColor: _C.surfaceContainer,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => const _AddTaskSheet(),
    );
  }
}

// ── Glow Orb ──────────────────────────────────────────────
class _GlowOrb extends StatelessWidget {
  final Color color; final double size;
  const _GlowOrb({required this.color, required this.size});
  @override
  Widget build(BuildContext context) => Container(
    width: size, height: size,
    decoration: BoxDecoration(shape: BoxShape.circle, color: color),
  );
}

// ── Top App Bar ────────────────────────────────────────────
class _TopAppBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: _C.background.withOpacity(0.85),
        border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.06))),
      ),
      child: Row(children: [
        const Icon(Icons.menu_rounded, color: _C.onSurfaceVariant, size: 24),
        const SizedBox(width: 16),
        const Text('Clarity', style: TextStyle(
          fontSize: 22, fontWeight: FontWeight.w700,
          color: _C.primary, fontFamily: 'SpaceGrotesk', letterSpacing: -0.5,
        )),
        const Spacer(),
        const Icon(Icons.filter_list_rounded, color: _C.onSurfaceVariant, size: 22),
        const SizedBox(width: 16),
        Container(
          width: 32, height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle, color: _C.primaryContainer,
            border: Border.all(color: _C.primary.withOpacity(0.3), width: 1.5),
          ),
          child: const Icon(Icons.person_rounded, color: Colors.white, size: 18),
        ),
      ]),
    );
  }
}

// ── Filter Chip ────────────────────────────────────────────
class _Chip extends StatelessWidget {
  final String label; final int count, index, selected;
  final ValueChanged<int> onTap;
  const _Chip({required this.label, required this.count, required this.index, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final active = selected == index;
    return GestureDetector(
      onTap: () => onTap(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: active ? _C.primaryContainer.withOpacity(0.20) : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: active ? _C.primary.withOpacity(0.35) : _C.outlineVariant.withOpacity(0.45),
          ),
          boxShadow: active ? [BoxShadow(color: _C.primaryContainer.withOpacity(0.20), blurRadius: 15)] : null,
        ),
        child: Text('$label ($count)', style: TextStyle(
          color: active ? _C.primary : _C.onSurfaceVariant,
          fontSize: 13, fontFamily: 'SpaceGrotesk',
          fontWeight: active ? FontWeight.w600 : FontWeight.normal,
        )),
      ),
    );
  }
}

// ── Task Card ──────────────────────────────────────────────
class _TaskCard extends StatelessWidget {
  final TaskModel task;
  const _TaskCard({required this.task});

  @override
  Widget build(BuildContext context) {
    final taskProvider  = context.read<TaskProvider>();
    final timerProvider = context.watch<TimerProvider>();
    final isFocusing    = timerProvider.selectedTaskId == task.id && timerProvider.status == TimerStatus.running;

    final statusText  = isFocusing ? 'Focusing Now' : task.completed ? 'Completed' : 'To Do';
    final statusColor = isFocusing ? _C.secondary : task.completed ? _C.tertiary : _C.onSurfaceVariant;

    return Dismissible(
      key: Key(task.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(color: AppColors.danger.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
        child: const Icon(Icons.delete_outline, color: AppColors.danger),
      ),
      onDismissed: (_) => taskProvider.deleteTask(task.id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [
              _C.surfaceVariant.withOpacity(isFocusing ? 0.50 : 0.35),
              _C.background.withOpacity(isFocusing ? 0.50 : 0.35),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isFocusing ? _C.primary.withOpacity(0.35) : Colors.white.withOpacity(0.06),
            width: isFocusing ? 1.5 : 1.0,
          ),
          boxShadow: isFocusing ? [BoxShadow(color: _C.primaryContainer.withOpacity(0.15), blurRadius: 16)] : null,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Checkbox
            GestureDetector(
              onTap: () => taskProvider.toggleTask(task.id),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 24, height: 24,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(5),
                  color: task.completed ? _C.primaryContainer : Colors.transparent,
                  border: Border.all(color: _C.primaryContainer, width: 2),
                ),
                child: task.completed
                    ? const Icon(Icons.check_rounded, color: _C.onPrimaryContainer, size: 14)
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
                    statusText.toUpperCase(),
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.0, color: statusColor, fontFamily: 'SpaceGrotesk'),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    task.title,
                    style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w500, fontFamily: 'SpaceGrotesk',
                      color: task.completed ? _C.onSurfaceVariant.withOpacity(0.5) : _C.onSurface,
                      decoration: task.completed ? TextDecoration.lineThrough : null,
                      decorationColor: _C.onSurfaceVariant.withOpacity(0.5),
                    ),
                  ),
                  if (task.label != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      task.label!,
                      style: TextStyle(
                        fontSize: 12, fontFamily: 'SpaceGrotesk',
                        color: task.completed ? _C.onSurfaceVariant.withOpacity(0.40) : _C.primary.withOpacity(0.65),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),

            // Trailing
            isFocusing
                ? Container(
              width: 40, height: 40,
              decoration: BoxDecoration(shape: BoxShape.circle, color: _C.primary.withOpacity(0.18)),
              child: const Icon(Icons.play_arrow_rounded, color: _C.primary, size: 22),
            )
                : GestureDetector(
              onTap: () => _showEdit(context, task),
              child: Icon(Icons.edit_outlined,
                  color: task.completed ? _C.onSurfaceVariant.withOpacity(0.35) : _C.onSurfaceVariant.withOpacity(0.65),
                  size: 20),
            ),
          ],
        ),
      ),
    );
  }

  void _showEdit(BuildContext context, TaskModel task) {
    showModalBottomSheet(
      context: context, isScrollControlled: true,
      backgroundColor: _C.surfaceContainer,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _EditTaskSheet(task: task),
    );
  }
}

// ── Empty State ────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: 72, height: 72,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _C.primaryContainer.withOpacity(0.15),
          border: Border.all(color: _C.primary.withOpacity(0.15)),
        ),
        child: const Icon(Icons.format_list_bulleted_rounded, color: _C.primary, size: 32),
      ),
      const SizedBox(height: 20),
      const Text('No tasks yet', style: TextStyle(color: _C.onSurface, fontSize: 18, fontWeight: FontWeight.w600, fontFamily: 'SpaceGrotesk')),
      const SizedBox(height: 8),
      const Text('Add your first task to get started', style: TextStyle(color: _C.onSurfaceVariant, fontSize: 14)),
    ]),
  );
}

// ── Add Task Sheet ─────────────────────────────────────────
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
    padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
    child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
      Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: _C.outlineVariant, borderRadius: BorderRadius.circular(2)))),
      const SizedBox(height: 20),
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        const Text('New Task', style: TextStyle(color: _C.onSurface, fontSize: 18, fontWeight: FontWeight.w600, fontFamily: 'SpaceGrotesk')),
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            width: 32, height: 32,
            decoration: const BoxDecoration(shape: BoxShape.circle, color: _C.surfaceVariant),
            child: const Icon(Icons.close_rounded, color: _C.onSurfaceVariant, size: 18),
          ),
        ),
      ]),
      const SizedBox(height: 20),
      _InputField(controller: _titleCtrl, hint: 'Task title...', autofocus: true),
      const SizedBox(height: 12),
      _InputField(controller: _labelCtrl, hint: 'Label (optional)'),
      const SizedBox(height: 14),
      Wrap(spacing: 8, runSpacing: 8, children: _suggestions.map((s) {
        final active = _selectedLabel == s;
        return GestureDetector(
          onTap: () => setState(() { _selectedLabel = active ? null : s; if (!active) _labelCtrl.clear(); }),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: active ? _C.primaryContainer.withOpacity(0.25) : _C.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: active ? _C.primary.withOpacity(0.35) : _C.outlineVariant.withOpacity(0.4)),
            ),
            child: Text(s, style: TextStyle(color: active ? _C.primary : _C.onSurfaceVariant, fontSize: 13, fontFamily: 'SpaceGrotesk')),
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
            color: _C.primaryContainer, borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: _C.primaryContainer.withOpacity(0.40), blurRadius: 24, offset: const Offset(0, 6))],
          ),
          child: const Text('Save Task', style: TextStyle(color: _C.onPrimaryContainer, fontWeight: FontWeight.w600, fontSize: 15, fontFamily: 'SpaceGrotesk')),
        ),
      ),
    ]),
  );
}

// ── Edit Task Sheet ────────────────────────────────────────
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
    padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
    child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
      Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: _C.outlineVariant, borderRadius: BorderRadius.circular(2)))),
      const SizedBox(height: 20),
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        const Text('Edit Task', style: TextStyle(color: _C.onSurface, fontSize: 18, fontWeight: FontWeight.w600, fontFamily: 'SpaceGrotesk')),
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            width: 32, height: 32,
            decoration: const BoxDecoration(shape: BoxShape.circle, color: _C.surfaceVariant),
            child: const Icon(Icons.close_rounded, color: _C.onSurfaceVariant, size: 18),
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
            color: _C.primaryContainer, borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: _C.primaryContainer.withOpacity(0.40), blurRadius: 24, offset: const Offset(0, 6))],
          ),
          child: const Text('Save Changes', style: TextStyle(color: _C.onPrimaryContainer, fontWeight: FontWeight.w600, fontSize: 15, fontFamily: 'SpaceGrotesk')),
        ),
      ),
    ]),
  );
}

// ── Input Field ────────────────────────────────────────────
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
      hintStyle: TextStyle(color: _C.onSurfaceVariant.withOpacity(0.5), fontSize: 15),
      filled: true, fillColor: _C.surfaceContainerHigh,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: _C.outlineVariant.withOpacity(0.4))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: _C.outlineVariant.withOpacity(0.4))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _C.primary, width: 1.5)),
    ),
  );
}