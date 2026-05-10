class Comment {
  final int id;
  final int postId;
  final int userId;
  final String username;
  final String content;
  final dynamic createdAt;

  const Comment({
    required this.id,
    required this.postId,
    required this.userId,
    required this.username,
    required this.content,
    required this.createdAt,
  });

  factory Comment.fromJson(Map<String, dynamic> json) => Comment(
    id: json['id'] ?? 0,
    postId: json['postId'] ?? 0,
    userId: json['userId'] ?? 0,
    username: json['username'] ?? '',
    content: json['content'] ?? '',
    createdAt: json['createdAt'],
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'postId': postId,
    'userId': userId,
    'username': username,
    'content': content,
    'createdAt': createdAt,
  };
}