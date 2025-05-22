part of 'user_search_cubit.dart';

abstract class UserSearchState extends Equatable {
  const UserSearchState();

  @override
  List<Object> get props => [];
}

class UserSearchInitial extends UserSearchState {}

class UserSearchLoading extends UserSearchState {}

class UserSearchLoaded extends UserSearchState {
  final List<UserModel> users;
  const UserSearchLoaded(this.users);

  @override
  List<Object> get props => [users];
}

class UserSearchEmpty extends UserSearchState {}

class UserSearchError extends UserSearchState {
  final String message;
  const UserSearchError(this.message);

  @override
  List<Object> get props => [message];
}