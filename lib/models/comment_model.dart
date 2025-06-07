class Comment {
  final String id;
  final String text;
  final String username;
  final DateTime createdAt;

  Comment({
    required this.id,
    required this.text,
    required this.username,
    required this.createdAt,
  });

  factory Comment.fromJson(Map<String, dynamic> json) => Comment(
        id: json['_id'],
        text: json['text'],
        username: json['commentedBy']['username'],
        createdAt: DateTime.parse(json['createdAt']),
      );
}
