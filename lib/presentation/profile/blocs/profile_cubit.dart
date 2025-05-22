import 'dart:io';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:chat_app/data/models/user_model.dart';
import 'package:chat_app/data/repositories/profile_repository.dart';
import 'package:chat_app/presentation/auth/blocs/auth_bloc.dart'; // To get current user ID

part 'profile_state.dart'; // Assuming states are in a separate file or below

class ProfileCubit extends Cubit<ProfileState> {
  final ProfileRepository _profileRepository;
  final AuthBloc _authBloc; // To get current user ID for own profile actions

  ProfileCubit({
    required ProfileRepository profileRepository,
    required AuthBloc authBloc,
  })  : _profileRepository = profileRepository,
        _authBloc = authBloc,
        super(ProfileInitial());

  String? get _currentUserId => _authBloc.state.user?.id;

  Future<void> loadUserProfile(String userId) async {
    emit(ProfileLoading());
    try {
      final user = await _profileRepository.getUserProfile(userId);
      if (user != null) {
        emit(ProfileLoaded(user));
      } else {
        emit(const ProfileError("User profile not found."));
      }
    } catch (e) {
      emit(ProfileError("Failed to load profile: ${e.toString()}"));
    }
  }

  Future<void> updateUserProfile({String? username, File? avatarImage}) async {
    if (_currentUserId == null) {
      emit(const ProfileError("User not authenticated. Cannot update profile."));
      return;
    }
    // Keep current loaded user data to show during update if available
    UserModel? currentUserData;
    if (state is ProfileLoaded) {
        currentUserData = (state as ProfileLoaded).user;
    } else if (state is ProfileUpdateSuccess){
        currentUserData = (state as ProfileUpdateSuccess).updatedUser;
    }


    emit(ProfileUpdating(currentUserData)); // Show loading but keep old data if possible
    try {
      await _profileRepository.updateUserProfile(
        _currentUserId!,
        username: username,
        avatarImage: avatarImage,
      );
      // After update, reload the profile to get the latest data
      final updatedUser = await _profileRepository.getUserProfile(_currentUserId!);
      if (updatedUser != null) {
        emit(ProfileUpdateSuccess(updatedUser));
        // Optionally, revert to ProfileLoaded after a short delay or if user navigates away
        // Future.delayed(const Duration(seconds: 2), () {
        //   if (state is ProfileUpdateSuccess) emit(ProfileLoaded(updatedUser));
        // });
      } else {
        emit(const ProfileError("Profile updated, but failed to reload latest data."));
      }
    } catch (e) {
      emit(ProfileError("Failed to update profile: ${e.toString()}"));
       // If error, try to revert to previous loaded state if possible
      if (currentUserData != null) {
        Future.delayed(const Duration(milliseconds: 100), () => emit(ProfileLoaded(currentUserData!)));
      }
    }
  }
}