part of 'groups_bloc.dart';

abstract class GroupsState extends Equatable {
  const GroupsState();
  @override
  List<Object?> get props => [];
}

class GroupsInitial extends GroupsState {}

class GroupsLoading extends GroupsState { // Generic loading for any operation
  final String? operationMessage; // e.g., "Creating group...", "Loading details..."
  const GroupsLoading({this.operationMessage});
   @override
  List<Object?> get props => [operationMessage];
}

class GroupOperationSuccess extends GroupsState {
  final String message;
  final GroupModel? group; // Optional: group data if relevant (e.g., after creation)
  final String? conversationId; // Optional: for navigation to group chat after creation

  const GroupOperationSuccess(this.message, {this.group, this.conversationId});
  @override
  List<Object?> get props => [message, group, conversationId];
}

class GroupDetailsLoaded extends GroupsState {
  final GroupModel group;
  final List<UserModel> members; // Members of the group
  const GroupDetailsLoaded({required this.group, required this.members});
  @override
  List<Object?> get props => [group, members];
}

class GroupsError extends GroupsState {
  final String message;
  const GroupsError(this.message);
  @override
  List<Object?> get props => [message];
}