/// A project — backed by /posts from jsonplaceholder.
/// Repurposed to demonstrate AgCrudService + AgPagedService on a second
/// resource in the same app, independent of the Tasks module.
class Project {
  const Project({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
  });

  final int id;
  final int userId;
  final String title;
  final String description;

  factory Project.fromJson(Map<String, dynamic> json) => Project(
    id: json['id'] as int,
    userId: json['userId'] as int,
    title: json['title'] as String,
    description: json['body'] as String,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'title': title,
    'body': description,
  };

  Project copyWith({String? title, String? description}) => Project(
    id: id,
    userId: userId,
    title: title ?? this.title,
    description: description ?? this.description,
  );
}
