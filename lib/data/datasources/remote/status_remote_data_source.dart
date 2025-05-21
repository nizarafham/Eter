import 'package:chat_app/core/constants/supabase_constants.dart';
import 'package:chat_app/data/models/status_model.dart';
import 'package:chat_app/data/models/user_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

abstract class StatusRemoteDataSource {
  Future<void> postTextStatus(String userId, String textContent, String backgroundColor);
  Future<void> postImageStatus(String userId, String imageUrl, {String? caption});
  Stream<List<StatusModel>> getStatusesByUsers(List<String> userIds); // Changed from getFriendsStatuses
  Future<StatusModel?> getStatusById(String statusId);
  Future<void> markStatusAsViewed(String statusId, String viewerId);
  Future<void> deleteStatus(String statusId, String userId);
}

class StatusRemoteDataSourceImpl implements StatusRemoteDataSource {
  final SupabaseClient _supabaseClient;
  final Uuid _uuid = const Uuid();

  StatusRemoteDataSourceImpl(this._supabaseClient);

  DateTime _calculateExpiresAt() {
    return DateTime.now().add(const Duration(hours: 24));
  }

  @override
  Future<void> postTextStatus(String userId, String textContent, String backgroundColor) async {
    final now = DateTime.now();
    await _supabaseClient.from(SupabaseConstants.statusesTable).insert({
      'id': _uuid.v4(),
      'user_id': userId,
      'type': 'text',
      'text_content': textContent,
      'background_color': backgroundColor,
      'created_at': now.toIso8601String(),
      'expires_at': _calculateExpiresAt().toIso8601String(),
      'viewed_by': [],
    });
  }

  @override
  Future<void> postImageStatus(String userId, String imageUrl, {String? caption}) async {
    final now = DateTime.now();
    await _supabaseClient.from(SupabaseConstants.statusesTable).insert({
      'id': _uuid.v4(),
      'user_id': userId,
      'type': 'image',
      'media_url': imageUrl,
      'text_content': caption,
      'created_at': now.toIso8601String(),
      'expires_at': _calculateExpiresAt().toIso8601String(),
      'viewed_by': [],
    });
  }

  @override
  Stream<List<StatusModel>> getStatusesByUsers(List<String> userIds) {
    if (userIds.isEmpty) {
      return Stream.value([]);
    }

    final now = DateTime.now().toIso8601String();
    
    final initialFuture = _supabaseClient
        .from(SupabaseConstants.statusesTable)
        .select('*, profiles(id, username, avatar_url)')
        .inFilter('user_id', userIds)
        .gt('expires_at', now)
        .order('created_at', ascending: false);

    final stream = _supabaseClient
        .from(SupabaseConstants.statusesTable)
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false);

    return Stream.fromFuture(initialFuture).asyncExpand((initialData) {
      return stream.map((changes) {
        final filtered = changes.where((status) {
          final isFromTargetUser = userIds.contains(status['user_id']);
          final isNotExpired = status['expires_at'] != null && 
              status['expires_at'].compareTo(now) > 0;
          return isFromTargetUser && isNotExpired;
        }).toList();

        return filtered.map((map) {
          final userDetailsMap = map['profiles'] as Map<String, dynamic>?;
          final userDetails = userDetailsMap != null 
              ? UserModel.fromMap(userDetailsMap) 
              : null;
          return StatusModel.fromMap(map, user: userDetails);
        }).toList();
      });
    });
  }

  @override
  Future<StatusModel?> getStatusById(String statusId) async {
    final response = await _supabaseClient
        .from(SupabaseConstants.statusesTable)
        .select('*, profiles(id, username, avatar_url)')
        .eq('id', statusId)
        .maybeSingle();

    if (response != null && response.isNotEmpty) {
      final userDetailsMap = response['profiles'] as Map<String, dynamic>?;
      final userDetails = userDetailsMap != null 
          ? UserModel.fromMap(userDetailsMap) 
          : null;
      return StatusModel.fromMap(response, user: userDetails);
    }
    return null;
  }

  @override
  Future<void> markStatusAsViewed(String statusId, String viewerId) async {
    await _supabaseClient.rpc('mark_status_viewed', params: {
      'status_id': statusId,
      'viewer_id': viewerId,
    });
  }

  @override
  Future<void> deleteStatus(String statusId, String userId) async {
    await _supabaseClient
        .from(SupabaseConstants.statusesTable)
        .delete()
        .eq('id', statusId)
        .eq('user_id', userId);
  }
}