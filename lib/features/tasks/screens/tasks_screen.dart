import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/task_provider.dart';
import '../models/task_model.dart';
import '../../../core/theme/app_colors.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  int _filter = 0; // 0=All, 1=Pending, 2=Completed

  @override
  void initState() {
    super.initState();
    Future.microtask(() =>
        context.read<TaskProvider>().fetchTasks());
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
      decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('My Tasks',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary)),
                  IconButton(
                    onPressed: () => _showAddTask(context),
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.add, color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Filter chips
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  _chip('All',       0, tasks.all.length),
                  const SizedBox(width: 8),
                  _chip('Pending',   1, tasks.pending.length),
                  const SizedBox(width: 8),
                  _chip('Completed', 2, tasks.completed.length),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Task list
            Expanded(
              child: tasks.isLoading
                  ? const Center(child: CircularProgressIndicator(
                  color: AppColors.primary))
                  : _filtered(tasks).isEmpty
                  ? _emptyState()
                  : ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: _filtered(tasks).length,
                itemBuilder: (_, i) {
                  final task = _filtered(tasks)[i];
                  return _TaskCard(task: task);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(String label, int index, int count) {
    final active = _filter == index;
    return GestureDetector(
      onTap: () => setState(() => _filter = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text('$label ($count)',
            style: TextStyle(
              color: active ? Colors.white : AppColors.textMuted,
              fontSize: 13,
              fontWeight: active ? FontWeight.w600 : FontWeight.normal,
            )),
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🌱', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 16),
          const Text('No tasks yet',
              style: TextStyle(color: AppColors.textPrimary,
                  fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          const Text('Add your first task to get started',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: () => _showAddTask(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(30),
              ),
              child: const Text('+ Add Task',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddTask(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const _AddTaskSheet(),
    );
  }
}

// ── Task Card ─────────────────────────────────────────────
class _TaskCard extends StatelessWidget {
  final TaskModel task;
  const _TaskCard({required this.task});

  @override
  Widget build(BuildContext context) {
    final provider = context.read<TaskProvider>();

    return Dismissible(
      key: Key(task.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.danger.withOpacity(0.2),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline, color: AppColors.danger),
      ),
      onDismissed: (_) => provider.deleteTask(task.id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.surfaceLight),
        ),
        child: Row(
          children: [
            // Checkbox
            GestureDetector(
              onTap: () => provider.toggleTask(task.id),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: task.completed ? AppColors.primary : Colors.transparent,
                  border: Border.all(
                    color: task.completed ? AppColors.primary : AppColors.textMuted,
                    width: 2,
                  ),
                ),
                child: task.completed
                    ? const Icon(Icons.check, color: Colors.white, size: 14)
                    : null,
              ),
            ),
            const SizedBox(width: 14),

            // Title + label
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(task.title,
                      style: TextStyle(
                        color: task.completed
                            ? AppColors.textMuted : AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        decoration: task.completed
                            ? TextDecoration.lineThrough : null,
                      )),
                  if (task.label != null) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(task.label!,
                          style: const TextStyle(
                              color: AppColors.primaryLight, fontSize: 11)),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Add Task Sheet ────────────────────────────────────────
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
  void dispose() {
    _titleCtrl.dispose();
    _labelCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_titleCtrl.text.trim().isEmpty) return;
    final label = _labelCtrl.text.trim().isNotEmpty
        ? _labelCtrl.text.trim()
        : _selectedLabel;

    await context.read<TaskProvider>().addTask(
      _titleCtrl.text.trim(),
      label: label,
    );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('New Task',
                  style: TextStyle(color: AppColors.textPrimary,
                      fontSize: 18, fontWeight: FontWeight.w600)),
              IconButton(
                icon: const Icon(Icons.close, color: AppColors.textMuted),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Title input
          TextField(
            controller: _titleCtrl,
            autofocus: true,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: const InputDecoration(hintText: 'Task title...'),
          ),
          const SizedBox(height: 12),

          // Label input
          TextField(
            controller: _labelCtrl,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: const InputDecoration(hintText: 'Label (optional)'),
          ),
          const SizedBox(height: 12),

          // Quick label suggestions
          Wrap(
            spacing: 8,
            children: _suggestions.map((s) {
              final active = _selectedLabel == s;
              return GestureDetector(
                onTap: () => setState(() {
                  _selectedLabel = active ? null : s;
                  if (!active) _labelCtrl.clear();
                }),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: active
                        ? AppColors.primary : AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(s,
                      style: TextStyle(
                        color: active ? Colors.white : AppColors.textSecondary,
                        fontSize: 12,
                      )),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 20),

          // Save button
          context.watch<TaskProvider>().isLoading
              ? const Center(child: CircularProgressIndicator(
              color: AppColors.primary))
              : GestureDetector(
            onTap: _save,
            child: Container(
              width: double.infinity,
              height: 52,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Text('Save Task',
                  style: TextStyle(color: Colors.white,
                      fontWeight: FontWeight.w600, fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }
}