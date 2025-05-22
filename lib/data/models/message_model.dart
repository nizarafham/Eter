import 'package:equatable/equatable.dart';

enum MessageType { text, image, system }

class MessageModel extends Equatable {
  final String id;
  final String conversationId;
  final String senderId;
  final String? textContent;
  final String? imageUrl;
  final MessageType type;
  final DateTime createdAt;
  final String? senderUsername;
  final String? senderAvatarUrl;

  const MessageModel({
    required this.id,
    required this.conversationId,
    required this.senderId,
    this.textContent,
    this.imageUrl,
    required this.type,
    required this.createdAt,
    this.senderUsername,
    this.senderAvatarUrl,
  });

  // Getter for content that works for both text and image messages
  String get content => textContent ?? (type == MessageType.image ? 'Image' : 'System message');

  // Getter for mediaUrl that safely returns the image URL
  String? get mediaUrl => imageUrl;

  factory MessageModel.fromMap(Map<String, dynamic> map, {String? username, String? avatarUrl}) {
    MessageType messageType;
    if (map['image_url'] != null) {
      messageType = MessageType.image;
    } else if (map['text_content'] != null) {
      messageType = MessageType.text;
    } else {
      messageType = MessageType.system;
    }

    return MessageModel(
      id: map['id'] as String,
      conversationId: map['conversation_id'] as String,
      senderId: map['sender_id'] as String,
      textContent: map['text_content'] as String?,
      imageUrl: map['image_url'] as String?,
      type: map['type'] != null ? MessageType.values.byName(map['type']) : messageType,
      createdAt: DateTime.parse(map['created_at'] as String),
      senderUsername: username ?? map['sender_username'] as String?,
      senderAvatarUrl: avatarUrl ?? map['sender_avatar_url'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'conversation_id': conversationId,
      'sender_id': senderId,
      'text_content': textContent,
      'image_url': imageUrl,
      'type': type.name,
    };
  }

  @override
  List<Object?> get props => [id, conversationId, senderId, textContent, imageUrl, type, createdAt];
}