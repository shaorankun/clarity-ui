class TaskModel {
  final String id;
  final String title;
  final String? label;
  final bool completed;

  TaskModel({
    required this.id,
    required this.title,
    this.label,
    required this.completed,
  });

  factory TaskModel.fromJson(Map<String, dynamic> json) => TaskModel(
    id:        json['id'],
    title:     json['title'],
    label:     json['label'],
    completed: json['completed'] ?? false,
  );

  TaskModel copyWith({bool? completed}) => TaskModel(
    id:        id,
    title:     title,
    label:     label,
    completed: completed ?? this.completed,
  );
}