import 'dart:io';
import 'package:chat_app/core/constants/supabase_constants.dart'; // For bucket names, e.g. SupabaseConstants.groupAvatarsBucket
import 'package:chat_app/data/datasources/remote/group_remote_data_source.dart'; // You'll need to create this
import 'package:chat_app/data/datasources/remote/storage_remote_data_source.dart'; // Your existing storage remote data source
import 'package:chat_app/data/models/group_model.dart'; // Ensure this model exists
import 'package:chat_app/data/models/user_model.dart'; // Ensure this model exists
import 'package:chat_app/data/repositories/group_repository.dart';

class GroupRepositoryImpl implements GroupRepository {
  final GroupRemoteDataSource _groupRemoteDataSource;
  final StorageRemoteDataSource _storageRemoteDataSource;

  GroupRepositoryImpl(this._groupRemoteDataSource, this._storageRemoteDataSource);

  @override
  Future<GroupModel?> createGroup(
      String name, String createdByUserId, List<String> memberIds,
      {File? avatarImage}) async {
    try {
      String? groupAvatarUrl;
      // Upload group avatar if provided
      if (avatarImage != null) {
        final fileName = 'group_avatar_${DateTime.now().millisecondsSinceEpoch}.${avatarImage.path.split('.').last}';
        final filePath = 'group_avatars/$fileName'; // Path in bucket for group avatars
        groupAvatarUrl = await _storageRemoteDataSource.uploadFile(
          avatarImage,
          SupabaseConstants.groupAvatarsBucket, // You'll define this constant
          filePath,
        );
      }

      // Add the creator to the initial member list if not already there
      final uniqueMemberIds = {...memberIds, createdByUserId}.toList();

      return await _groupRemoteDataSource.createGroup(
        name,
        createdByUserId,
        uniqueMemberIds,
        groupAvatarUrl: groupAvatarUrl,
      );
    } catch (e) {
      // print('GroupRepositoryImpl createGroup error: $e');
      rethrow;
    }
  }

  @override
  Future<GroupModel?> getGroupDetails(String groupId) async {
    try {
      return await _groupRemoteDataSource.getGroupDetails(groupId);
    } catch (e) {
      // print('GroupRepositoryImpl getGroupDetails error: $e');
      rethrow;
    }
  }

  @override
  Stream<List<UserModel>> getGroupMembers(String groupId) {
    try {
      return _groupRemoteDataSource.getGroupMembers(groupId);
    } catch (e) {
      // print('GroupRepositoryImpl getGroupMembers error: $e');
      rethrow;
    }
  }

  @override
  Future<void> addMembersToGroup(String groupId, List<String> userIdsToAdd) async {
    try {
      await _groupRemoteDataSource.addMembersToGroup(groupId, userIdsToAdd);
    } catch (e) {
      // print('GroupRepositoryImpl addMembersToGroup error: $e');
      rethrow;
    }
  }

  @override
  Future<void> removeMemberFromGroup(String groupId, String userIdToRemove) async {
    try {
      await _groupRemoteDataSource.removeMemberFromGroup(groupId, userIdToRemove);
    } catch (e) {
      // print('GroupRepositoryImpl removeMemberFromGroup error: $e');
      rethrow;
    }
  }

  @override
  Future<void> updateGroupInfo(String groupId, {String? name, File? avatarImage}) async {
    try {
      String? groupAvatarUrl;
      if (avatarImage != null) {
        final fileName = 'group_avatar_${groupId}_${DateTime.now().millisecondsSinceEpoch}.${avatarImage.path.split('.').last}';
        final filePath = 'group_avatars/$groupId/$fileName'; // Specific path for this group's avatar
        groupAvatarUrl = await _storageRemoteDataSource.uploadFile(
          avatarImage,
          SupabaseConstants.groupAvatarsBucket,
          filePath,
        );
      }

      final updates = <String, dynamic>{};
      if (name != null) updates['name'] = name;
      if (groupAvatarUrl != null) updates['avatar_url'] = groupAvatarUrl;

      if (updates.isNotEmpty) {
        await _groupRemoteDataSource.updateGroupInfo(groupId, updates);
      }
    } catch (e) {
      // print('GroupRepositoryImpl updateGroupInfo error: $e');
      rethrow;
    }
  }

  @override
  Future<void> leaveGroup(String groupId, String userId) async {
    try {
      await _groupRemoteDataSource.removeMemberFromGroup(groupId, userId);
      // You might also want to update the conversation if this was the last member, or if the group creator leaves
    } catch (e) {
      // print('GroupRepositoryImpl leaveGroup error: $e');
      rethrow;
    }
  }
}