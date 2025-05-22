import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:chat_app/data/models/user_model.dart';
import 'package:chat_app/data/repositories/profile_repository.dart';

part 'user_search_state.dart'; // Assuming states are in a separate file or below

class UserSearchCubit extends Cubit<UserSearchState> {
  final ProfileRepository _profileRepository;

  UserSearchCubit({required ProfileRepository profileRepository})
      : _profileRepository = profileRepository,
        super(UserSearchInitial());

  Future<void> searchUsers(String query) async {
    if (query.trim().isEmpty) {
      emit(UserSearchInitial()); // or UserSearchEmpty if you prefer
      return;
    }
    emit(UserSearchLoading());
    try {
      final users = await _profileRepository.searchUsersByUsername(query.trim());
      if (users.isEmpty) {
        emit(UserSearchEmpty());
      } else {
        emit(UserSearchLoaded(users));
      }
    } catch (e) {
      emit(UserSearchError("Failed to search users: ${e.toString()}"));
    }
  }

  void clearSearch() {
    emit(UserSearchInitial());
  }
}