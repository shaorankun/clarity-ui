import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../../core/network/dio_client.dart';
import '../models/task_model.dart';

class TaskProvider extends ChangeNotifier {
  List<TaskModel> _tasks = [];
  bool isLoading = false;
  String? errorMessage;

  final _dio = DioClient.instance;

  List<TaskModel> get pending   => _tasks.where((t) => !t.completed).toList();
  List<TaskModel> get completed => _tasks.where((t) => t.completed).toList();
  List<TaskModel> get all       => _tasks;

  Future<void> fetchTasks() async {
    isLoading = true;
    notifyListeners();
    try {
      final res = await _dio.get('/api/tasks');
      _tasks = (res.data as List)
          .map((e) => TaskModel.fromJson(e))
          .toList();
    } on DioException catch (e) {
      errorMessage = e.response?.data['message'] ?? 'Failed to load tasks';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addTask(String title, {String? label}) async {
    try {
      final res = await _dio.post('/api/tasks', data: {
        'title': title,
        if (label != null && label.isNotEmpty) 'label': label,
      });
      _tasks.insert(0, TaskModel.fromJson(res.data));
      notifyListeners();
    } on DioException catch (e) {
      errorMessage = e.response?.data['message'] ?? 'Failed to add task';
      notifyListeners();
    }
  }

  Future<void> toggleTask(String id) async {
    final index = _tasks.indexWhere((t) => t.id == id);
    if (index == -1) return;

    // Optimistic update — cập nhật UI trước, gọi API sau
    final old = _tasks[index];
    _tasks[index] = old.copyWith(completed: !old.completed);
    notifyListeners();

    try {
      await _dio.patch('/api/tasks/$id/complete');
    } catch (_) {
      // Rollback nếu API lỗi
      _tasks[index] = old;
      notifyListeners();
    }
  }

  Future<void> deleteTask(String id) async {
    final old = List<TaskModel>.from(_tasks);
    _tasks.removeWhere((t) => t.id == id);
    notifyListeners();

    try {
      await _dio.delete('/api/tasks/$id');
    } catch (_) {
      _tasks = old;
      notifyListeners();
    }
  }
}