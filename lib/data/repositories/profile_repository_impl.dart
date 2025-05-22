// lib/data/repositories/profile_repository_impl.dart
import 'dart:io';
import 'package:chat_app/core/constants/supabase_constants.dart';
import 'package:chat_app/data/datasources/remote/profile_remote_data_source.dart';
import 'package:chat_app/data/datasources/remote/storage_remote_data_source.dart';
import 'package:chat_app/data/models/user_model.dart';
import 'package:chat_app/data/repositories/profile_repository.dart'; // Interface

class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileRemoteDataSource _profileRemoteDataSource;
  final StorageRemoteDataSource _storageRemoteDataSource;

  // Konstruktor menggunakan positional arguments
  ProfileRepositoryImpl(this._profileRemoteDataSource, this._storageRemoteDataSource);

  @override
  Future<UserModel?> getUserProfile(String userId) async {
    try {
      return await _profileRemoteDataSource.getUserProfile(userId);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> updateUserProfile(String userId, {String? username, File? avatarImage}) async {
    try {
      String? avatarUrl;
      if (avatarImage != null) {
        final fileName = 'avatar_${userId}_${DateTime.now().millisecondsSinceEpoch}.${avatarImage.path.split('.').last}';
        final filePath = '$userId/$fileName';
        avatarUrl = await _storageRemoteDataSource.uploadFile(
          avatarImage,
          SupabaseConstants.profileAvatarsBucket,
          filePath,
        );
      }
      final updates = <String, dynamic>{};
      if (username != null) updates['username'] = username;
      if (avatarUrl != null) updates['avatar_url'] = avatarUrl;

      if (updates.isNotEmpty) {
        await _profileRemoteDataSource.updateUserProfileData(userId, updates);
      }
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<List<UserModel>> searchUsersByUsername(String usernameQuery, {int limit = 10}) async {
     try {
      return await _profileRemoteDataSource.searchUsersByUsername(usernameQuery, limit: limit);
    } catch (e) {
      rethrow;
    }
  }
}