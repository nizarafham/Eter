import 'package:chat_app/core/constants/supabase_constants.dart';
import 'package:chat_app/data/models/user_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract class ProfileRemoteDataSource {
  Future<UserModel?> getUserProfile(String userId);
  Future<void> updateUserProfile(UserModel user);
  Future<List<UserModel>> searchUsersByUsername(String usernameQuery, {required int limit});
  // Added updateUserProfileData to the abstract class
  Future<void> updateUserProfileData(String userId, Map<String, dynamic> updates);
  // Add methods for friends, e.g., addFriend, getFriends
}

class ProfileRemoteDataSourceImpl implements ProfileRemoteDataSource {
  final SupabaseClient _supabaseClient;

  ProfileRemoteDataSourceImpl(this._supabaseClient);

  @override
  Future<UserModel?> getUserProfile(String userId) async {
    final response = await _supabaseClient
        .from(SupabaseConstants.profilesTable)
        .select()
        .eq('id', userId)
        .single(); // Use .maybeSingle() if it can be null without error
    return UserModel.fromMap(response);
  }

  @override
  Future<void> updateUserProfile(UserModel user) async {
    await _supabaseClient
        .from(SupabaseConstants.profilesTable)
        .update(user.toMap()..removeWhere((key, value) => key == 'id' || key == 'created_at' || key == 'email')) // Don't update id or created_at or email directly
        .eq('id', user.id);
  }

  @override
  Future<List<UserModel>> searchUsersByUsername(String usernameQuery, {required int limit}) async {
    final response = await _supabaseClient
        .from(SupabaseConstants.profilesTable)
        .select()
        .ilike('username', '%$usernameQuery%') // Case-insensitive search
        .neq('id', _supabaseClient.auth.currentUser!.id) // Exclude self
        .limit(limit); // Apply the limit

    return response.map((data) => UserModel.fromMap(data)).toList();
  }

  @override
  Future<void> updateUserProfileData(String userId, Map<String, dynamic> updates) async {
    await _supabaseClient
        .from(SupabaseConstants.profilesTable)
        .update(updates)
        .eq('id', userId);
  }
}