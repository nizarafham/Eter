import 'package:equatable/equatable.dart';
import 'package:chat_app/data/models/user_model.dart'; // For sender details

enum StatusType { text, image, video } // Assuming video might be a future addition

class StatusModel extends Equatable {
  final String id;
  final String userId; // User who posted the status
  final StatusType type;
  final String? textContent;
  final String? mediaUrl; // For image or video
  final String? thumbnailUrl; // Optional, for video
  final String? backgroundColor; // For text statuses
  final DateTime createdAt;
  final DateTime expiresAt; // e.g., 24 hours after createdAt
  final List<String> viewedBy; // List of user IDs who viewed this status

  // Denormalized data for easier display
  final UserModel? userDetails;

  const StatusModel({
    required this.id,
    required this.userId,
    required this.type,
    this.textContent,
    this.mediaUrl,
    this.thumbnailUrl,
    this.backgroundColor,
    required this.createdAt,
    required this.expiresAt,
    this.viewedBy = const [],
    this.userDetails,
  });

  factory StatusModel.fromMap(Map<String, dynamic> map, {UserModel? user}) {
    return StatusModel(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      type: StatusType.values.byName(map['type'] as String? ?? StatusType.text.name),
      textContent: map['text_content'] as String?,
      mediaUrl: map['media_url'] as String?,
      thumbnailUrl: map['thumbnail_url'] as String?,
      backgroundColor: map['background_color'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      expiresAt: DateTime.parse(map['expires_at'] as String),
      viewedBy: List<String>.from(map['viewed_by'] ?? []), // Supabase array
      userDetails: user,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'type': type.name,
      'text_content': textContent,
      'media_url': mediaUrl,
      'thumbnail_url': thumbnailUrl,
      'background_color': backgroundColor,
      'expires_at': expiresAt.toIso8601String(),
      // 'viewed_by': viewedBy, // viewed_by is likely updated via a separate mechanism or RPC
    };
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        type,
        textContent,
        mediaUrl,
        thumbnailUrl,
        backgroundColor,
        createdAt,
        expiresAt,
        viewedBy,
        userDetails,
      ];
}