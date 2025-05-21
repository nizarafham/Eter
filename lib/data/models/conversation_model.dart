import 'package:equatable/equatable.dart';
import 'package:chat_app/data/models/user_model.dart';
import 'package:chat_app/data/models/message_model.dart'; // For last message

enum ConversationType { dm, group }

class ConversationModel extends Equatable {
  final String id; // Unique ID for the conversation (can be composite for DMs or group ID)
  final ConversationType type;
  final List<String> participantIds; // User IDs involved
  final String? groupName; // Null if DM
  final String? groupAvatarUrl; // Null if DM
  final String? createdBy; // User ID of group creator, null if DM
  final DateTime createdAt;
  final DateTime updatedAt; // When the last activity (message, member change) occurred
  final MessageModel? lastMessage; // Optional: For display in chat lists
  final int unreadCount; // For the current user

  // For UI display, especially for DMs
  final UserModel? dmParticipant; // The other user in a DM

  const ConversationModel({
    required this.id,
    required this.type,
    required this.participantIds,
    this.groupName,
    this.groupAvatarUrl,
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.lastMessage,
    this.unreadCount = 0,
    this.dmParticipant,
  });

  factory ConversationModel.fromMap(Map<String, dynamic> map, {MessageModel? lastMsg, UserModel? dmUser, int unread = 0}) {
    return ConversationModel(
      id: map['id'] as String,
      type: ConversationType.values.byName(map['type'] as String? ?? ConversationType.dm.name), // Default or ensure 'type' field
      participantIds: List<String>.from(map['participant_ids'] ?? []), // Should be a Supabase array or fetched from a join table
      groupName: map['group_name'] as String?,
      groupAvatarUrl: map['group_avatar_url'] as String?,
      createdBy: map['created_by'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String? ?? map['created_at'] as String),
      lastMessage: lastMsg,
      unreadCount: unread,
      dmParticipant: dmUser,
    );
  }

  // You might not need a toMap if you're not directly inserting/updating this complex model.
  // Updates would likely happen to specific fields or related tables.

  @override
  List<Object?> get props => [
        id,
        type,
        participantIds,
        groupName,
        groupAvatarUrl,
        createdBy,
        createdAt,
        updatedAt,
        lastMessage,
        unreadCount,
        dmParticipant,
      ];

  ConversationModel copyWith({
    String? id,
    ConversationType? type,
    List<String>? participantIds,
    String? groupName,
    String? groupAvatarUrl,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    MessageModel? lastMessage,
    int? unreadCount,
    UserModel? dmParticipant,
  }) {
    return ConversationModel(
      id: id ?? this.id,
      type: type ?? this.type,
      participantIds: participantIds ?? this.participantIds,
      groupName: groupName ?? this.groupName,
      groupAvatarUrl: groupAvatarUrl ?? this.groupAvatarUrl,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastMessage: lastMessage ?? this.lastMessage,
      unreadCount: unreadCount ?? this.unreadCount,
      dmParticipant: dmParticipant ?? this.dmParticipant,
    );
  }
}