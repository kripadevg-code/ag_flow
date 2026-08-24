/// A single comment on a [Post], as returned by
/// `GET https://jsonplaceholder.typicode.com/posts/{id}/comments`.
class Comment {
  const Comment({
    required this.id,
    required this.postId,
    required this.name,
    required this.email,
    required this.body,
  });

  final int id;
  final int postId;
  final String name;
  final String email;
  final String body;

  factory Comment.fromJson(Map<String, dynamic> json) => Comment(
    id: json['id'] as int,
    postId: json['postId'] as int,
    name: json['name'] as String,
    email: json['email'] as String,
    body: json['body'] as String,
  );
}
