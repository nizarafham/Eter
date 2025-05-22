part of 'status_bloc.dart';

abstract class StatusEvent extends Equatable {
  const StatusEvent();

  @override
  List<Object?> get props => [];
}

/// Loads statuses for the current user and their friends.
class LoadStatuses extends StatusEvent {}

/// Internal event when the status stream updates.
class _StatusesUpdated extends StatusEvent {
  final List<StatusModel> allStatuses; // Flat list from repository
  const _StatusesUpdated(this.allStatuses);

  @override
  List<Object?> get props => [allStatuses];
}

/// Posts a new text status.
class PostTextStatus extends StatusEvent {
  final String textContent;
  final String backgroundColor; // e.g., hex string like "#RRGGBB"

  const PostTextStatus({required this.textContent, required this.backgroundColor});

  @override
  List<Object?> get props => [textContent, backgroundColor];
}

/// Posts a new image status.
class PostImageStatus extends StatusEvent {
  final File imageFile;
  final String? caption;

  const PostImageStatus({required this.imageFile, this.caption});

  @override
  List<Object?> get props => [imageFile, caption];
}

/// Marks a specific status as viewed by the current user.
class MarkStatusAsViewed extends StatusEvent {
  final String statusId;
  // viewerId will be currentUserId from the BLoC

  const MarkStatusAsViewed({required this.statusId});

  @override
  List<Object?> get props => [statusId];
}

/// Deletes a specific status (must be current user's own).
class DeleteStatus extends StatusEvent {
  final String statusId;

  const DeleteStatus({required this.statusId});

  @override
  List<Object?> get props => [statusId];
}