import 'package:chat_app/data/datasources/remote/friends_remote_data_source.dart'; // You'll need to create this
import 'package:chat_app/data/models/friendship_model.dart'; // Ensure this model exists
import 'package:chat_app/data/repositories/friendship_repository.dart';

class FriendsRepositoryImpl implements FriendsRepository {
  final FriendsRemoteDataSource _remoteDataSource;

  FriendsRepositoryImpl(this._remoteDataSource);

  @override
  Stream<List<FriendshipModel>> getFriends(String userId) {
    try {
      return _remoteDataSource.getFriends(userId);
    } catch (e) {
      // print('FriendsRepositoryImpl getFriends error: $e');
      rethrow;
    }
  }

  @override
  Stream<List<FriendshipModel>> getFriendRequests(String userId) {
    try {
      return _remoteDataSource.getFriendRequests(userId);
    } catch (e) {
      // print('FriendsRepositoryImpl getFriendRequests error: $e');
      rethrow;
    }
  }

  @override
  Future<void> sendFriendRequest(String fromUserId, String toUserId) async {
    try {
      await _remoteDataSource.sendFriendRequest(fromUserId, toUserId);
    } catch (e) {
      // print('FriendsRepositoryImpl sendFriendRequest error: $e');
      rethrow;
    }
  }

  @override
  Future<void> acceptFriendRequest(String friendshipId, String actionUserId) async {
    try {
      await _remoteDataSource.acceptFriendRequest(friendshipId, actionUserId);
    } catch (e) {
      // print('FriendsRepositoryImpl acceptFriendRequest error: $e');
      rethrow;
    }
  }

  @override
  Future<void> declineOrCancelFriendRequest(String friendshipId) async {
    try {
      await _remoteDataSource.declineOrCancelFriendRequest(friendshipId);
    } catch (e) {
      // print('FriendsRepositoryImpl declineOrCancelFriendRequest error: $e');
      rethrow;
    }
  }

  @override
  Future<void> removeFriend(String friendshipId) async {
    try {
      await _remoteDataSource.removeFriend(friendshipId);
    } catch (e) {
      // print('FriendsRepositoryImpl removeFriend error: $e');
      rethrow;
    }
  }
}