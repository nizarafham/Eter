import 'package:chat_app/data/models/friendship_model.dart'; // You'll need to create this model

abstract class FriendsRepository {
  /// Streams a list of accepted friendships for a given user.
  Stream<List<FriendshipModel>> getFriends(String userId);

  /// Streams a list of pending incoming or outgoing friend requests for a given user.
  Stream<List<FriendshipModel>> getFriendRequests(String userId);

  /// Sends a friend request from one user to another.
  Future<void> sendFriendRequest(String fromUserId, String toUserId);

  /// Accepts a pending friend request.
  /// [friendshipId]: The ID of the friendship record to update.
  /// [actionUserId]: The ID of the user performing the action (for RLS/security).
  Future<void> acceptFriendRequest(String friendshipId, String actionUserId);

  /// Declines or cancels a pending friend request.
  /// [friendshipId]: The ID of the friendship record to delete or update.
  Future<void> declineOrCancelFriendRequest(String friendshipId);

  /// Removes an existing friend.
  /// [friendshipId]: The ID of the established friendship record to delete.
  Future<void> removeFriend(String friendshipId);
}