import 'package:equatable/equatable.dart';
import 'package:chat_app/data/models/user_model.dart';

enum FriendshipStatus { pending, accepted, declined, blocked }

class FriendshipModel extends Equatable {
  final String id; // Unique ID for the friendship record
  final String userId1; // ID of the user who initiated or is user1
  final String userId2; // ID of the other user
  final FriendshipStatus status;
  final String? actionUserId; // User who performed the last action (e.g., sent request, accepted)
  final DateTime createdAt;
  final DateTime updatedAt;

  // Denormalized data for easier display
  final UserModel? user1Details;
  final UserModel? user2Details;


  const FriendshipModel({
    required this.id,
    required this.userId1,
    required this.userId2,
    required this.status,
    this.actionUserId,
    required this.createdAt,
    required this.updatedAt,
    this.user1Details,
    this.user2Details,
  });

  // Conductor for the friend of the current user in a friendship
  UserModel? getFriend(String currentUserId) {
    if (userId1 == currentUserId) return user2Details;
    if (userId2 == currentUserId) return user1Details;
    return null;
  }

  String getOtherUserId(String currentUserId) {
    if (userId1 == currentUserId) return userId2;
    if (userId2 == currentUserId) return userId1;
    throw Exception('Current user is not part of this friendship');
  }

  factory FriendshipModel.fromMap(Map<String, dynamic> map, {UserModel? u1, UserModel? u2}) {
    return FriendshipModel(
      id: map['id'] as String,
      userId1: map['user_id1'] as String,
      userId2: map['user_id2'] as String,
      status: FriendshipStatus.values.byName(map['status'] as String? ?? FriendshipStatus.pending.name),
      actionUserId: map['action_user_id'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String? ?? map['created_at'] as String),
      user1Details: u1,
      user2Details: u2,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id1': userId1,
      'user_id2': userId2,
      'status': status.name,
      'action_user_id': actionUserId,
    };
  }


  @override
  List<Object?> get props => [id, userId1, userId2, status, actionUserId, createdAt, updatedAt, user1Details, user2Details];
}