import 'package:flutter/material.dart';
import '../models/task.dart';
import '../services/api_service.dart';

class TaskProvider extends ChangeNotifier {
  List<Task> _tasks = [];
  bool _isLoading = false;
  String? _error;

  List<Task> get tasks => _tasks;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Задачи для конкретного исполнителя (crew видит только свои)
  List<Task> tasksForUser(int userId) {
    return _tasks.where((t) => t.assignedTo == userId).toList();
  }

  Future<void> loadTasks(String token) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _tasks = await ApiService.getTasks(token);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createTask({
    required String token,
    required String title,
    required String content,
    int? assignedTo,
    String? deadline,
  }) async {
    try {
      await ApiService.createTask(
        token: token,
        title: title,
        taskContent: content,
        assignedTo: assignedTo,
        deadline: deadline,
      );
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> completeTask(String token, int taskInfoId) async {
    try {
      await ApiService.completeTask(token, taskInfoId);
      // Обновляем локально сразу, не ждём перезагрузки
      final index = _tasks.indexWhere((t) => t.taskInfoId == taskInfoId);
      if (index != -1) {
        _tasks[index] = Task(
          id: _tasks[index].id,
          taskInfoId: _tasks[index].taskInfoId,
          title: _tasks[index].title,
          content: _tasks[index].content,
          createdAt: _tasks[index].createdAt,
          authorName: _tasks[index].authorName,
          assignedByName: _tasks[index].assignedByName,
          assignedToName: _tasks[index].assignedToName,
          assignedTo: _tasks[index].assignedTo,
          deadline: _tasks[index].deadline,
          status: 'completed',
        );
        notifyListeners();
      }
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
