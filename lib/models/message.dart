class Message {
  final String id;
  final String profileId;
  final String content;
  final DateTime createdAt;
  String? username; // To store fetched username

  Message({
    required this.id,
    required this.profileId,
    required this.content,
    required this.createdAt,
    this.username,
  });

  factory Message.fromMap(Map<String, dynamic> map) {
    return Message(
      id: map['id'] as String,
      profileId: map['profile_id'] as String,
      content: map['content'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}