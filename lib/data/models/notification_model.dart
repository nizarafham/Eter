import 'package:equatable/equatable.dart';

enum NotificationType { friendRequest, groupInvite, newMessage, statusUpdate, generic }

class NotificationModel extends Equatable {
  final String id;
  final String recipientId; // User ID of the recipient
  final NotificationType type;
  final String title;
  final String body;
  final String? senderId; // User who triggered the notification
  final String? referenceId; // e.g., friendship_id, group_id, message_id, status_id
  final Map<String, dynamic>? data; // Additional data for navigation or context
  final bool isRead;
  final DateTime createdAt;

  const NotificationModel({
    required this.id,
    required this.recipientId,
    required this.type,
    required this.title,
    required this.body,
    this.senderId,
    this.referenceId,
    this.data,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationModel.fromMap(Map<String, dynamic> map) {
    return NotificationModel(
      id: map['id'] as String,
      recipientId: map['recipient_id'] as String,
      type: NotificationType.values.byName(map['type'] as String? ?? NotificationType.generic.name),
      title: map['title'] as String? ?? 'Notification',
      body: map['body'] as String? ?? '',
      senderId: map['sender_id'] as String?,
      referenceId: map['reference_id'] as String?,
      data: map['data'] != null ? Map<String, dynamic>.from(map['data']) : null,
      isRead: map['is_read'] as bool? ?? false,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

   Map<String, dynamic> toInsertMap() { // For inserting new notifications
    return {
      'recipient_id': recipientId,
      'type': type.name,
      'title': title,
      'body': body,
      'sender_id': senderId,
      'reference_id': referenceId,
      'data': data,
      // is_read and created_at will be handled by Supabase default/trigger
    };
  }

  @override
  List<Object?> get props => [id, recipientId, type, title, body, senderId, referenceId, data, isRead, createdAt];
}