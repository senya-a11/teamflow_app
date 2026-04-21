import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/task_provider.dart';
import '../models/task.dart';
import 'login_screen.dart';
import 'create_task_screen.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadTasks());
  }

  Future<void> _loadTasks() async {
    final auth = context.read<AuthProvider>();
    final tasks = context.read<TaskProvider>();
    if (auth.token != null) {
      await tasks.loadTasks(auth.token!);
    }
  }

  Future<void> _logout() async {
    await context.read<AuthProvider>().logout();
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final taskProvider = context.watch<TaskProvider>();
    final user = auth.user!;

    // crew видит только свои задачи, team_leader — все
    final tasks = user.isTeamLeader
        ? taskProvider.tasks
        : taskProvider.tasksForUser(user.id);

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF16213E),
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('TeamFlow', style: TextStyle(color: Colors.white, fontSize: 18)),
            Text(
              '${user.username} · ${user.isTeamLeader ? 'Руководитель' : 'Сотрудник'}',
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white70),
            onPressed: _loadTasks,
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white70),
            onPressed: _logout,
          ),
        ],
      ),
      floatingActionButton: user.isTeamLeader
          ? FloatingActionButton.extended(
              onPressed: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const CreateTaskScreen()),
                );
                _loadTasks(); // обновляем после создания
              },
              backgroundColor: const Color(0xFF6C63FF),
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Задача', style: TextStyle(color: Colors.white)),
            )
          : null,
      body: taskProvider.isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF6C63FF)))
          : taskProvider.error != null
              ? _buildError(taskProvider.error!)
              : tasks.isEmpty
                  ? _buildEmpty()
                  : RefreshIndicator(
                      onRefresh: _loadTasks,
                      color: const Color(0xFF6C63FF),
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: tasks.length,
                        itemBuilder: (_, i) => _TaskCard(task: tasks[i]),
                      ),
                    ),
    );
  }

  Widget _buildError(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.cloud_off, color: Colors.white30, size: 48),
          const SizedBox(height: 12),
          Text(error, style: const TextStyle(color: Colors.white54), textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadTasks,
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6C63FF)),
            child: const Text('Повторить', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox, color: Colors.white30, size: 48),
          SizedBox(height: 12),
          Text('Задач пока нет', style: TextStyle(color: Colors.white54)),
        ],
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  final Task task;
  const _TaskCard({required this.task});

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final taskProvider = context.read<TaskProvider>();
    final isCompleted = task.isCompleted;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF16213E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCompleted
              ? Colors.green.withOpacity(0.4)
              : const Color(0xFF6C63FF).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    task.title,
                    style: TextStyle(
                      color: isCompleted ? Colors.white38 : Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      decoration: isCompleted ? TextDecoration.lineThrough : null,
                    ),
                  ),
                ),
                _StatusBadge(status: task.status),
              ],
            ),
            if (task.content.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                task.content,
                style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 14),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 12),
            // Мета-информация
            Wrap(
              spacing: 12,
              runSpacing: 4,
              children: [
                if (task.assignedToName != null)
                  _MetaChip(icon: Icons.person, label: task.assignedToName!),
                if (task.deadline != null)
                  _MetaChip(
                    icon: Icons.calendar_today,
                    label: task.deadline!.split('T').first,
                  ),
                if (task.authorName != null)
                  _MetaChip(icon: Icons.edit, label: 'от ${task.authorName}'),
              ],
            ),
            // Кнопка "Выполнено" для crew
            if (!isCompleted && task.taskInfoId != null && auth.user!.isCrew) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () async {
                    await taskProvider.completeTask(auth.token!, task.taskInfoId!);
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF6C63FF)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Отметить выполненной', style: TextStyle(color: Color(0xFF6C63FF))),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final isCompleted = status == 'completed';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isCompleted ? Colors.green.withOpacity(0.2) : Colors.orange.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isCompleted ? 'Выполнено' : 'В работе',
        style: TextStyle(
          color: isCompleted ? Colors.greenAccent : Colors.orangeAccent,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _MetaChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: Colors.white38),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(color: Colors.white38, fontSize: 12)),
      ],
    );
  }
}
