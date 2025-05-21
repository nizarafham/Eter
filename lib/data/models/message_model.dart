import 'package:equatable/equatable.dart';

enum MessageType { text, image, system } // System for "User A joined" etc.

class MessageModel extends Equatable {
  final String id;
  final String conversationId; // ID of the DM chat or group chat
  final String senderId;
  final String? textContent;
  final String? imageUrl;
  final MessageType type;
  final DateTime createdAt;
  final String? senderUsername; // Denormalized for easier display
  final String? senderAvatarUrl; // Denormalized

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

  factory MessageModel.fromMap(Map<String, dynamic> map, {String? username, String? avatarUrl}) {
    MessageType messageType;
    if (map['image_url'] != null) {
      messageType = MessageType.image;
    } else if (map['text_content'] != null) {
      messageType = MessageType.text;
    } else {
      // Default or handle system messages if you have a 'type' column
      messageType = MessageType.system; // Or throw error if unexpected
    }

    return MessageModel(
      id: map['id'] as String,
      conversationId: map['conversation_id'] as String,
      senderId: map['sender_id'] as String,
      textContent: map['text_content'] as String?,
      imageUrl: map['image_url'] as String?,
      type: map['type'] != null ? MessageType.values.byName(map['type']) : messageType,
      createdAt: DateTime.parse(map['created_at'] as String),
      senderUsername: username ?? map['sender_username'] as String?, // If joined
      senderAvatarUrl: avatarUrl ?? map['sender_avatar_url'] as String?, // If joined
    );
  }

   Map<String, dynamic> toMap() {
    return {
      'id': id, // Supabase usually handles ID generation
      'conversation_id': conversationId,
      'sender_id': senderId,
      'text_content': textContent,
      'image_url': imageUrl,
      'type': type.name,
      // 'created_at': createdAt.toIso8601String(), // Supabase handles timestamp
    };
  }

  @override
  List<Object?> get props => [id, conversationId, senderId, textContent, imageUrl, type, createdAt];
}