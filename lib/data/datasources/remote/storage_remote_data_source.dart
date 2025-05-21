import 'dart:io';
import 'package:chat_app/core/constants/supabase_constants.dart';
import 'package:chat_app/data/datasources/remote/profile_remote_data_source.dart';
import 'package:chat_app/data/datasources/remote/storage_remote_data_source.dart';
import 'package:chat_app/data/models/user_model.dart';
import 'package:chat_app/data/repositories/profile_repository.dart'; // Interface
import 'package:supabase_flutter/supabase_flutter.dart';

abstract class StorageRemoteDataSource {
  Future<String> uploadFile(File file, String bucketName, String filePath);
  // Add other storage-related methods here if needed, e.g., downloadFile, deleteFile
}

class StorageRemoteDataSourceImpl implements StorageRemoteDataSource {
  final SupabaseClient _supabaseClient;

  StorageRemoteDataSourceImpl(this._supabaseClient);

  @override
  Future<String> uploadFile(File file, String bucketName, String filePath) async {
    final storageResponse = await _supabaseClient.storage
        .from(bucketName)
        .upload(filePath, file);

    // Get the public URL of the uploaded file
    final publicUrlResponse = _supabaseClient.storage
        .from(bucketName)
        .getPublicUrl(filePath);

    return publicUrlResponse;
  }
}

class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileRemoteDataSource _profileRemoteDataSource;
  final StorageRemoteDataSource _storageRemoteDataSource; // For avatar uploads

  ProfileRepositoryImpl(this._profileRemoteDataSource, this._storageRemoteDataSource);

  @override
  Future<UserModel?> getUserProfile(String userId) async {
    try {
      return await _profileRemoteDataSource.getUserProfile(userId);
    } catch (e) {
      // print("ProfileRepository GetUserProfile Error: $e");
      rethrow;
    }
  }

  @override
  Future<void> updateUserProfile(String userId, {String? username, File? avatarImage}) async {
    try {
      String? avatarUrl;
      if (avatarImage != null) {
        final fileName = 'avatar_${userId}_${DateTime.now().millisecondsSinceEpoch}.${avatarImage.path.split('.').last}';
        final filePath = '$userId/$fileName'; // Path in bucket
        avatarUrl = await _storageRemoteDataSource.uploadFile(
          avatarImage,
          SupabaseConstants.profileAvatarsBucket, // Use a specific bucket for avatars
          filePath,
        );
      }
      // Create a map of updates, only including non-null values
      final updates = <String, dynamic>{};
      if (username != null) updates['username'] = username;
      if (avatarUrl != null) updates['avatar_url'] = avatarUrl;

      if (updates.isNotEmpty) {
        await _profileRemoteDataSource.updateUserProfileData(userId, updates);
      }
    } catch (e) {
      // print("ProfileRepository UpdateUserProfile Error: $e");
      rethrow;
    }
  }

  @override
  Future<List<UserModel>> searchUsersByUsername(String usernameQuery, {int limit = 10}) async {
      try {
      return await _profileRemoteDataSource.searchUsersByUsername(usernameQuery, limit: limit);
    } catch (e) {
      // print("ProfileRepository SearchUsers Error: $e");
      rethrow;
    }
  }
}