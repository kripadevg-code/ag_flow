/// A single blog post, as returned by
/// `GET https://jsonplaceholder.typicode.com/posts`.
class Post {
  const Post({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
  });

  final int id;
  final int userId;
  final String title;
  final String body;

  factory Post.fromJson(Map<String, dynamic> json) => Post(
    id: json['id'] as int,
    userId: json['userId'] as int,
    title: json['title'] as String,
    body: json['body'] as String,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'title': title,
    'body': body,
  };

  Post copyWith({String? title, String? body}) => Post(
    id: id,
    userId: userId,
    title: title ?? this.title,
    body: body ?? this.body,
  );
}
