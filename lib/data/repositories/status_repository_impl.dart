import 'dart:io';
import 'package:chat_app/core/constants/supabase_constants.dart'; // For bucket names, e.g., SupabaseConstants.statusImagesBucket
import 'package:chat_app/data/datasources/remote/friends_remote_data_source.dart';
import 'package:chat_app/data/datasources/remote/status_remote_data_source.dart'; // You'll need to create this
import 'package:chat_app/data/datasources/remote/storage_remote_data_source.dart'; // Your existing storage remote data source
import 'package:chat_app/data/models/status_model.dart'; // Ensure this model exists
import 'package:chat_app/data/repositories/status_repository.dart';

class StatusRepositoryImpl implements StatusRepository {
  final StatusRemoteDataSource _statusRemoteDataSource;
  final StorageRemoteDataSource _storageRemoteDataSource;
  final FriendsRemoteDataSource _friendsRemoteDataSource; // Added to get friends list

  StatusRepositoryImpl(
    this._statusRemoteDataSource,
    this._storageRemoteDataSource,
    this._friendsRemoteDataSource,
  );

  @override
  Future<void> postTextStatus(String userId, String textContent, String backgroundColor) async {
    try {
      await _statusRemoteDataSource.postTextStatus(userId, textContent, backgroundColor);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> postImageStatus(String userId, File imageFile, {String? caption}) async {
    try {
      final fileName = 'status_image_${userId}_${DateTime.now().millisecondsSinceEpoch}.${imageFile.path.split('.').last}';
      final filePath = '$userId/$fileName';
      final imageUrl = await _storageRemoteDataSource.uploadFile(
        imageFile,
        SupabaseConstants.statusImagesBucket,
        filePath,
      );

      if (imageUrl == null) {
        throw Exception("Failed to upload status image");
      }

      await _statusRemoteDataSource.postImageStatus(userId, imageUrl, caption: caption);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Stream<List<StatusModel>> getFriendsStatuses(String userId) async* {
    try {
      // First get the user's friends list
      final friendships  = await _friendsRemoteDataSource.getFriends(userId).first;

      final friendIds = friendships
          .map((friendship) => friendship.getOtherUserId(userId))
          .toList();
      
      // Include the user's own statuses if desired
      friendIds.add(userId);
      
      // Get statuses for all friends
      yield* _statusRemoteDataSource.getStatusesByUsers(friendIds);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<StatusModel?> getStatusById(String statusId) async {
    try {
      return await _statusRemoteDataSource.getStatusById(statusId);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> markStatusAsViewed(String statusId, String viewerId) async {
    try {
      await _statusRemoteDataSource.markStatusAsViewed(statusId, viewerId);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> deleteStatus(String statusId, String userId) async {
    try {
      await _statusRemoteDataSource.deleteStatus(statusId, userId);
    } catch (e) {
      rethrow;
    }
  }
}