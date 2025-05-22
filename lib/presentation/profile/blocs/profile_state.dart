part of 'profile_cubit.dart';

abstract class ProfileState extends Equatable {
  const ProfileState();

  @override
  List<Object?> get props => [];
}

class ProfileInitial extends ProfileState {}

class ProfileLoading extends ProfileState {}

class ProfileLoaded extends ProfileState {
  final UserModel user;
  const ProfileLoaded(this.user);

  @override
  List<Object?> get props => [user];
}

class ProfileUpdating extends ProfileState {
  final UserModel? previousUser; // Can hold previous data while updating
  const ProfileUpdating(this.previousUser);

  @override
  List<Object?> get props => [previousUser];
}

class ProfileUpdateSuccess extends ProfileState {
  final UserModel updatedUser;
  const ProfileUpdateSuccess(this.updatedUser);

   @override
  List<Object?> get props => [updatedUser];
}

class ProfileError extends ProfileState {
  final String message;
  const ProfileError(this.message);

  @override
  List<Object?> get props => [message];
}