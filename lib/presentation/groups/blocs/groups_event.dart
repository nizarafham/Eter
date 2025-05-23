part of 'groups_bloc.dart';

abstract class GroupsEvent extends Equatable {
  const GroupsEvent();
  @override
  List<Object?> get props => [];
}

class CreateGroup extends GroupsEvent {
  final String name;
  final List<String> memberIds; // List of user IDs to add
  final File? avatarImage;

  const CreateGroup({required this.name, required this.memberIds, this.avatarImage});
  @override
  List<Object?> get props => [name, memberIds, avatarImage];
}

class LoadGroupDetails extends GroupsEvent {
  final String groupId;
  const LoadGroupDetails(this.groupId);
  @override
  List<Object?> get props => [groupId];
}

class AddMembersToGroup extends GroupsEvent {
  final String groupId;
  final List<String> userIdsToAdd;
  const AddMembersToGroup({required this.groupId, required this.userIdsToAdd});
   @override
  List<Object?> get props => [groupId, userIdsToAdd];
}

class RemoveMemberFromGroup extends GroupsEvent {
  final String groupId;
  final String userIdToRemove;
  const RemoveMemberFromGroup({required this.groupId, required this.userIdToRemove});
   @override
  List<Object?> get props => [groupId, userIdToRemove];
}

class LeaveGroup extends GroupsEvent {
  final String groupId;
  const LeaveGroup(this.groupId);
   @override
  List<Object?> get props => [groupId];
}

class UpdateGroupInfo extends GroupsEvent {
  final String groupId;
  final String? newName;
  final File? newAvatarImage;
  const UpdateGroupInfo({required this.groupId, this.newName, this.newAvatarImage});
   @override
  List<Object?> get props => [groupId, newName, newAvatarImage];
}