class Task {
  final int id;
  final int? taskInfoId;
  final String title;
  final String content;
  final String? createdAt;
  final String? authorName;
  final String? assignedByName;
  final String? assignedToName;
  final int? assignedTo;
  final String? deadline;
  final String status;

  Task({
    required this.id,
    this.taskInfoId,
    required this.title,
    required this.content,
    this.createdAt,
    this.authorName,
    this.assignedByName,
    this.assignedToName,
    this.assignedTo,
    this.deadline,
    required this.status,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'],
      taskInfoId: json['task_info_id'],
      title: json['title'],
      content: json['content'] ?? '',
      createdAt: json['created_at'],
      authorName: json['author_name'],
      assignedByName: json['assigned_by_name'],
      assignedToName: json['assigned_to_name'],
      assignedTo: json['assigned_to'],
      deadline: json['deadline'],
      status: json['status'] ?? 'pending',
    );
  }

  bool get isCompleted => status == 'completed';
}
