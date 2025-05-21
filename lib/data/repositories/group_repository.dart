import 'dart:io';
import 'package:chat_app/data/models/group_model.dart'; // You'll need to create this model
import 'package:chat_app/data/models/user_model.dart'; // To get group members

abstract class GroupRepository {
  /// Creates a new chat group.
  ///
  /// [name]: The name of the group.
  /// [createdByUserId]: The ID of the user creating the group.
  /// [memberIds]: A list of initial member IDs.
  /// [avatarImage]: Optional image file for the group avatar.
  ///
  /// Returns the created GroupModel, or null if creation failed.
  Future<GroupModel?> createGroup(
      String name, String createdByUserId, List<String> memberIds,
      {File? avatarImage});

  /// Fetches detailed information about a specific group.
  Future<GroupModel?> getGroupDetails(String groupId);

  /// Streams a list of UserModel objects representing the members of a group.
  Stream<List<UserModel>> getGroupMembers(String groupId);

  /// Adds a list of users as members to an existing group.
  Future<void> addMembersToGroup(String groupId, List<String> userIdsToAdd);

  /// Removes a specific user from a group.
  Future<void> removeMemberFromGroup(String groupId, String userIdToRemove);

  /// Updates the name or avatar of a group.
  Future<void> updateGroupInfo(String groupId,
      {String? name, File? avatarImage});

  /// Allows a user to leave a group.
  Future<void> leaveGroup(String groupId, String userId);

  // You might also want methods for:
  // - getGroupsForUser(String userId) // To get all groups a user is a member of
}