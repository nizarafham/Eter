import 'dart:io';
import 'package:chat_app/data/models/user_model.dart';

abstract class ProfileRepository {
  Future<UserModel?> getUserProfile(String userId);
  Future<void> updateUserProfile(String userId, {String? username, File? avatarImage});
  Future<List<UserModel>> searchUsersByUsername(String usernameQuery, {int limit = 10});
}