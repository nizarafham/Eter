import 'dart:async';
import 'dart:io'; // For File type
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:chat_app/data/models/status_model.dart';
import 'package:chat_app/data/models/user_model.dart';
import 'package:chat_app/data/repositories/status_repository.dart';
import 'package:collection/collection.dart'; // For groupBy

// Assuming GroupedStatus is defined (e.g., in status_state.dart or a separate file)
part 'grouped_status_model.dart';
part 'status_event.dart';
part 'status_state.dart';

class StatusBloc extends Bloc<StatusEvent, StatusState> {
  final StatusRepository _statusRepository;
  final String _currentUserId;
  StreamSubscription? _statusSubscription;

  StatusBloc({
    required StatusRepository statusRepository,
    required String currentUserId,
  })  : _statusRepository = statusRepository,
        _currentUserId = currentUserId,
        super(StatusInitial()) {
    on<LoadStatuses>(_onLoadStatuses);
    on<_StatusesUpdated>(_onStatusesUpdated);
    on<PostTextStatus>(_onPostTextStatus);
    on<PostImageStatus>(_onPostImageStatus);
    on<MarkStatusAsViewed>(_onMarkStatusAsViewed);
    on<DeleteStatus>(_onDeleteStatus);
  }

  List<GroupedStatus> _getCurrentGroupedStatusesFromState() {
    if (state is StatusLoaded) return (state as StatusLoaded).groupedStatuses;
    if (state is StatusLoading) return (state as StatusLoading).currentGroupedStatuses;
    if (state is StatusError) return (state as StatusError).currentGroupedStatuses;
    if (state is StatusPosting) return (state as StatusPosting).currentGroupedStatuses;
    return const [];
  }

   GroupedStatus? _getCurrentUserStatusGroupFromState() {
    if (state is StatusLoaded) return (state as StatusLoaded).currentUserStatusGroup;
    if (state is StatusError) return (state as StatusError).currentUserStatusGroup;
    if (state is StatusPosting) return (state as StatusPosting).currentUserStatusGroup;
    return null;
  }


  void _onLoadStatuses(LoadStatuses event, Emitter<StatusState> emit) {
    emit(StatusLoading(
      currentGroupedStatuses: _getCurrentGroupedStatusesFromState(),
    ));
    _statusSubscription?.cancel();
    _statusSubscription = _statusRepository.getFriendsStatuses(_currentUserId).listen(
      (allStatuses) {
        add(_StatusesUpdated(allStatuses));
      },
      onError: (error) => emit(StatusError(
        "Failed to load statuses: ${error.toString()}",
        currentGroupedStatuses: _getCurrentGroupedStatusesFromState(),
        currentUserStatusGroup: _getCurrentUserStatusGroupFromState(),
      )),
    );
  }

  void _onStatusesUpdated(_StatusesUpdated event, Emitter<StatusState> emit) {
    // Group statuses by user ID
    final groupedByUserId = groupBy<StatusModel, String>(
      event.allStatuses,
      (status) => status.userId,
    );

    List<GroupedStatus> groupedStatusesList = [];
    GroupedStatus? currentUserStatusGroup;

    groupedByUserId.forEach((userId, userStatuses) {
      if (userStatuses.isNotEmpty) {
        // Sort statuses by creation time (newest first for display logic if needed, or oldest first for viewing sequence)
        userStatuses.sort((a, b) => a.createdAt.compareTo(b.createdAt)); // Oldest first for viewing sequence

        final userDetails = userStatuses.first.userDetails ?? UserModel(id: userId, username: "User $userId", createdAt: DateTime.now()); // Fallback
        final allViewed = userStatuses.every((s) => s.viewedBy.contains(_currentUserId));

        final group = GroupedStatus(
          user: userDetails,
          statuses: userStatuses,
          allViewed: allViewed,
        );

        if (userId == _currentUserId) {
          currentUserStatusGroup = group;
        } else {
          groupedStatusesList.add(group);
        }
      }
    });

    // Optionally sort friend groups: those with unread statuses first, then by latest status time
    groupedStatusesList.sort((a, b) {
      if (a.allViewed && !b.allViewed) return 1; // b (unread) comes first
      if (!a.allViewed && b.allViewed) return -1; // a (unread) comes first
      // If both read or both unread, sort by latest status time (newest group first)
      DateTime? aLatest = a.statuses.isNotEmpty ? a.statuses.last.createdAt : null;
      DateTime? bLatest = b.statuses.isNotEmpty ? b.statuses.last.createdAt : null;
      if (aLatest != null && bLatest != null) return bLatest.compareTo(aLatest);
      if (bLatest != null) return 1; // b has statuses, a doesn't, b comes first
      if (aLatest != null) return -1; // a has statuses, b doesn't, a comes first
      return 0;
    });


    emit(StatusLoaded(
      groupedStatuses: groupedStatusesList,
      currentUserStatusGroup: currentUserStatusGroup,
    ));
  }

  Future<void> _onPostTextStatus(PostTextStatus event, Emitter<StatusState> emit) async {
    emit(StatusPosting(
        currentGroupedStatuses: _getCurrentGroupedStatusesFromState(),
        currentUserStatusGroup: _getCurrentUserStatusGroupFromState(),
    ));
    try {
      await _statusRepository.postTextStatus(
          _currentUserId, event.textContent, event.backgroundColor);
      // The stream will update the list. Emit success or rely on stream.
      // For immediate feedback, refetch or optimistically add.
      // Here, we'll emit a success message and the stream will handle the list update.
       emit(StatusLoaded(
        groupedStatuses: _getCurrentGroupedStatusesFromState(),
        currentUserStatusGroup: _getCurrentUserStatusGroupFromState(),
        successMessage: "Status posted!",
      ));
      add(LoadStatuses()); // Refresh statuses
    } catch (e) {
      emit(StatusError(
        "Failed to post text status: ${e.toString()}",
        currentGroupedStatuses: _getCurrentGroupedStatusesFromState(),
        currentUserStatusGroup: _getCurrentUserStatusGroupFromState(),
      ));
    }
  }

  Future<void> _onPostImageStatus(PostImageStatus event, Emitter<StatusState> emit) async {
     emit(StatusPosting(
        currentGroupedStatuses: _getCurrentGroupedStatusesFromState(),
        currentUserStatusGroup: _getCurrentUserStatusGroupFromState(),
    ));
    try {
      await _statusRepository.postImageStatus(_currentUserId, event.imageFile,
          caption: event.caption);
      emit(StatusLoaded(
        groupedStatuses: _getCurrentGroupedStatusesFromState(),
        currentUserStatusGroup: _getCurrentUserStatusGroupFromState(),
        successMessage: "Image status posted!",
      ));
      add(LoadStatuses()); // Refresh statuses
    } catch (e) {
      emit(StatusError(
        "Failed to post image status: ${e.toString()}",
        currentGroupedStatuses: _getCurrentGroupedStatusesFromState(),
        currentUserStatusGroup: _getCurrentUserStatusGroupFromState(),
      ));
    }
  }

  Future<void> _onMarkStatusAsViewed(MarkStatusAsViewed event, Emitter<StatusState> emit) async {
    // Current state might be StatusLoaded
    final currentGroups = _getCurrentGroupedStatusesFromState();
    final currentUserGroup = _getCurrentUserStatusGroupFromState();

    try {
      await _statusRepository.markStatusAsViewed(event.statusId, _currentUserId);
      // Optimistically update the local state or wait for the stream to reflect the change.
      // For simplicity, we'll assume the stream update will handle it.
      // If you want immediate UI update before stream:
      bool changed = false;
      final updatedGroups = currentGroups.map((group) {
        bool groupChanged = false;
        final updatedStatuses = group.statuses.map((status) {
          if (status.id == event.statusId && !status.viewedBy.contains(_currentUserId)) {
            changed = true;
            groupChanged = true;
            return status.copyWith(viewedBy: List.from(status.viewedBy)..add(_currentUserId));
          }
          return status;
        }).toList();
        if (groupChanged) {
          return group.copyWith(statuses: updatedStatuses, allViewed: updatedStatuses.every((s) => s.viewedBy.contains(_currentUserId)));
        }
        return group;
      }).toList();

      GroupedStatus? updatedCurrentUserGroup = currentUserGroup;
      if(currentUserGroup != null){
         bool groupChanged = false;
         final updatedStatuses = currentUserGroup.statuses.map((status) {
          // Current user doesn't "view" their own status in the same way,
          // but this logic is here if viewedBy array needs to be updated for some reason by self.
          // Usually, viewedBy is for others.
          if (status.id == event.statusId && !status.viewedBy.contains(_currentUserId) && status.userId != _currentUserId) { // Only mark if not own status and not already viewed
            changed = true;
            groupChanged = true;
            return status.copyWith(viewedBy: List.from(status.viewedBy)..add(_currentUserId));
          }
          return status;
        }).toList();
        if (groupChanged) {
           updatedCurrentUserGroup = currentUserGroup.copyWith(statuses: updatedStatuses, allViewed: updatedStatuses.every((s) => s.viewedBy.contains(_currentUserId)));
        }
      }


      if (changed) {
        emit(StatusLoaded(groupedStatuses: updatedGroups, currentUserStatusGroup: updatedCurrentUserGroup));
      }
      // The stream will eventually provide the authoritative update.
    } catch (e) {
      // print("Failed to mark status as viewed: $e");
      // No need to emit error state here as it's a background task,
      // unless it's critical for UI. Error will be logged.
    }
  }

  Future<void> _onDeleteStatus(DeleteStatus event, Emitter<StatusState> emit) async {
    // Only current user can delete their own status, RLS should enforce this on backend.
    // Optimistically remove from UI or wait for stream.
    final currentGroups = _getCurrentGroupedStatusesFromState();
    final currentUserGroup = _getCurrentUserStatusGroupFromState();

    emit(StatusPosting(currentGroupedStatuses: currentGroups, currentUserStatusGroup: currentUserGroup)); // Show a generic loading

    try {
      await _statusRepository.deleteStatus(event.statusId, _currentUserId);
       emit(StatusLoaded(
        groupedStatuses: currentGroups, // Stream will update friends' statuses
        currentUserStatusGroup: currentUserGroup?.copyWith( // Optimistically remove from current user's group
          statuses: currentUserGroup.statuses.where((s) => s.id != event.statusId).toList()
        ),
        successMessage: "Status deleted.",
      ));
      // Optionally call add(LoadStatuses()) if optimistic update isn't enough or to confirm
    } catch (e) {
      emit(StatusError(
        "Failed to delete status: ${e.toString()}",
        currentGroupedStatuses: currentGroups,
        currentUserStatusGroup: currentUserGroup,
      ));
    }
  }


  @override
  Future<void> close() {
    _statusSubscription?.cancel();
    return super.close();
  }
}