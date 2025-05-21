import 'package:chat_app/core/constants/supabase_constants.dart';
import 'package:chat_app/data/models/group_model.dart';
import 'package:chat_app/data/models/user_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

abstract class GroupRemoteDataSource {
  Future<GroupModel> createGroup(
      String name, String createdByUserId, List<String> memberIds,
      {String? groupAvatarUrl});
  Future<GroupModel?> getGroupDetails(String groupId);
  Stream<List<UserModel>> getGroupMembers(String groupId);
  Future<void> addMembersToGroup(String groupId, List<String> userIdsToAdd);
  Future<void> removeMemberFromGroup(String groupId, String userIdToRemove);
  Future<void> updateGroupInfo(String groupId, Map<String, dynamic> updates);
}

class GroupRemoteDataSourceImpl implements GroupRemoteDataSource {
  final SupabaseClient _supabaseClient;
  final Uuid _uuid = const Uuid();

  GroupRemoteDataSourceImpl(this._supabaseClient);

  @override
  Future<GroupModel> createGroup(
      String name, String createdByUserId, List<String> memberIds,
      {String? groupAvatarUrl}) async {
    final newGroupId = _uuid.v4();
    final now = DateTime.now().toIso8601String();

    final groupResponse = await _supabaseClient
        .from(SupabaseConstants.groupsTable)
        .insert({
          'id': newGroupId,
          'name': name,
          'avatar_url': groupAvatarUrl,
          'created_by': createdByUserId,
          'created_at': now,
          'updated_at': now,
        })
        .select()
        .single();

    final createdGroup = GroupModel.fromMap(groupResponse);

    final List<Map<String, dynamic>> memberEntries = memberIds.map((userId) => {
      'group_id': newGroupId,
      'user_id': userId,
      'joined_at': now,
    }).toList();

    if (memberEntries.isNotEmpty) {
      await _supabaseClient
          .from(SupabaseConstants.groupMembersTable)
          .insert(memberEntries);
    }

    return createdGroup;
  }

  @override
  Future<GroupModel?> getGroupDetails(String groupId) async {
    final response = await _supabaseClient
        .from(SupabaseConstants.groupsTable)
        .select()
        .eq('id', groupId)
        .maybeSingle();

    return response != null ? GroupModel.fromMap(response) : null;
  }

  @override
  Stream<List<UserModel>> getGroupMembers(String groupId) {
    // First get the initial data with a proper select
    final initialFuture = _supabaseClient
        .from(SupabaseConstants.groupMembersTable)
        .select('user_id, profiles(*)')
        .eq('group_id', groupId);

    // Then create a stream that watches for changes
    final stream = _supabaseClient
        .from(SupabaseConstants.groupMembersTable)
        .stream(primaryKey: ['group_id', 'user_id'])
        .eq('group_id', groupId);

    // Combine them using RxDart
    return Stream.fromFuture(initialFuture).asyncExpand((initialData) {
      return stream.map((changes) {
        // For simplicity, we'll just return the initial data on changes
        // In a real app, you might want to merge changes with initial data
        return initialData
            .map((map) => UserModel.fromMap(map['profiles'] as Map<String, dynamic>))
            .toList();
      });
    });
  }

  @override
  Future<void> addMembersToGroup(String groupId, List<String> userIdsToAdd) async {
    final now = DateTime.now().toIso8601String();
    final List<Map<String, dynamic>> memberEntries = userIdsToAdd.map((userId) => {
      'group_id': groupId,
      'user_id': userId,
      'joined_at': now,
    }).toList();

    if (memberEntries.isNotEmpty) {
      await _supabaseClient
          .from(SupabaseConstants.groupMembersTable)
          .insert(memberEntries);
    }
  }

  @override
  Future<void> removeMemberFromGroup(String groupId, String userIdToRemove) async {
    await _supabaseClient
        .from(SupabaseConstants.groupMembersTable)
        .delete()
        .eq('group_id', groupId)
        .eq('user_id', userIdToRemove);
  }

  @override
  Future<void> updateGroupInfo(String groupId, Map<String, dynamic> updates) async {
    await _supabaseClient
        .from(SupabaseConstants.groupsTable)
        .update({...updates, 'updated_at': DateTime.now().toIso8601String()})
        .eq('id', groupId);
  }
}