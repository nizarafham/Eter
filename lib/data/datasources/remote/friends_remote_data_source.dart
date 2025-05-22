import 'package:chat_app/core/constants/supabase_constants.dart';
import 'package:chat_app/data/models/friendship_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
// import 'package:rxdart/rxdart.dart';

abstract class FriendsRemoteDataSource {
  Stream<List<FriendshipModel>> getFriends(String userId);
  Stream<List<FriendshipModel>> getFriendRequests(String userId);
  Future<void> sendFriendRequest(String fromUserId, String toUserId);
  Future<void> acceptFriendRequest(String friendshipId, String actionUserId);
  Future<void> declineOrCancelFriendRequest(String friendshipId);
  Future<void> removeFriend(String friendshipId);
}

class FriendsRemoteDataSourceImpl implements FriendsRemoteDataSource {
  final SupabaseClient _supabaseClient;

  FriendsRemoteDataSourceImpl(this._supabaseClient);

  @override
  Stream<List<FriendshipModel>> getFriends(String userId) {
    final friendsStream = _supabaseClient
        .from(SupabaseConstants.friendshipsTable)
        .stream(primaryKey: ['id'])
        .order('updated_at', ascending: false);

    return friendsStream.map((rows) {
      return rows
          .where((row) =>
              row['status'] == 'accepted' &&
              (row['user_id1'] == userId || row['user_id2'] == userId))
          .map((row) => FriendshipModel.fromMap(row))
          .toList();
    });
  }

  @override
  Stream<List<FriendshipModel>> getFriendRequests(String userId) {
    final requestsStream = _supabaseClient
        .from(SupabaseConstants.friendshipsTable)
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false);

    return requestsStream.map((rows) {
      return rows
          .where((row) =>
              row['status'] == 'pending' &&
              (row['user_id1'] == userId || row['user_id2'] == userId))
          .map((row) => FriendshipModel.fromMap(row))
          .toList();
    });
  }

  @override
  Future<void> sendFriendRequest(String fromUserId, String toUserId) async {
    final sorted = [fromUserId, toUserId]..sort();
    final user1 = sorted[0];
    final user2 = sorted[1];

    final existing = await _supabaseClient
        .from(SupabaseConstants.friendshipsTable)
        .select()
        .eq('user_id1', user1)
        .eq('user_id2', user2)
        .limit(1);

    if (existing.isNotEmpty) {
      final status = existing.first['status'] as String;
      if (status == 'pending') throw Exception('Friend request already pending');
      if (status == 'accepted') throw Exception('Already friends');
      if (status == 'blocked') throw Exception('User is blocked');
      return;
    }

    final now = DateTime.now().toIso8601String();
    await _supabaseClient.from(SupabaseConstants.friendshipsTable).insert({
      'user_id1': user1,
      'user_id2': user2,
      'status': 'pending',
      'action_user_id': fromUserId,
      'created_at': now,
      'updated_at': now,
    });
  }

  @override
  Future<void> acceptFriendRequest(String friendshipId, String actionUserId) async {
    await _supabaseClient
        .from(SupabaseConstants.friendshipsTable)
        .update({
          'status': 'accepted',
          'action_user_id': actionUserId,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', friendshipId)
        .eq('status', 'pending');
  }

  @override
  Future<void> declineOrCancelFriendRequest(String friendshipId) async {
    await _supabaseClient
        .from(SupabaseConstants.friendshipsTable)
        .delete()
        .eq('id', friendshipId)
        .eq('status', 'pending');
  }

  @override
  Future<void> removeFriend(String friendshipId) async {
    await _supabaseClient
        .from(SupabaseConstants.friendshipsTable)
        .delete()
        .eq('id', friendshipId)
        .eq('status', 'accepted');
  }
}