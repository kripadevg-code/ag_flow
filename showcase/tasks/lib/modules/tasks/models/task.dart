/// A single task item from GET /todos.
class Task {
  const Task({
    required this.id,
    required this.userId,
    required this.title,
    required this.completed,
  });

  final int id;
  final int userId;
  final String title;
  final bool completed;

  factory Task.fromJson(Map<String, dynamic> json) => Task(
    id: json['id'] as int,
    userId: json['userId'] as int,
    title: json['title'] as String,
    completed: json['completed'] as bool,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'title': title,
    'completed': completed,
  };

  Task copyWith({String? title, bool? completed}) => Task(
    id: id,
    userId: userId,
    title: title ?? this.title,
    completed: completed ?? this.completed,
  );
}
