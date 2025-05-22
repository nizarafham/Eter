part of 'status_bloc.dart';

abstract class StatusState extends Equatable {
  const StatusState();

  @override
  List<Object?> get props => [];
}

class StatusInitial extends StatusState {}

class StatusLoading extends StatusState {
  final List<GroupedStatus> currentGroupedStatuses;
  final GroupedStatus? currentUserStatusGroup; // <<< ADD THIS LINE

  const StatusLoading({
    this.currentGroupedStatuses = const [],
    this.currentUserStatusGroup, // <<< ADD THIS TO CONSTRUCTOR
  });

  @override
  List<Object?> get props => [currentGroupedStatuses, currentUserStatusGroup]; // <<< ADD TO PROPS
}

class StatusLoaded extends StatusState {
  final List<GroupedStatus> groupedStatuses; // Statuses grouped by user
  final GroupedStatus? currentUserStatusGroup; // Current user's own statuses, separated for easy access
  final String? successMessage;

  const StatusLoaded({
    required this.groupedStatuses,
    this.currentUserStatusGroup,
    this.successMessage,
  });

  @override
  List<Object?> get props => [groupedStatuses, currentUserStatusGroup, successMessage];

  StatusLoaded copyWith({
    List<GroupedStatus>? groupedStatuses,
    GroupedStatus? currentUserStatusGroup,
    bool allowNullCurrentUserStatusGroup = false, // To explicitly set it to null
    String? successMessage,
    bool clearSuccessMessage = false,
  }) {
    return StatusLoaded(
      groupedStatuses: groupedStatuses ?? this.groupedStatuses,
      currentUserStatusGroup: allowNullCurrentUserStatusGroup
          ? currentUserStatusGroup
          : (currentUserStatusGroup ?? this.currentUserStatusGroup),
      successMessage: clearSuccessMessage ? null : successMessage ?? this.successMessage,
    );
  }
}

class StatusPosting extends StatusState { // Could also extend StatusLoaded to keep showing feed
  final List<GroupedStatus> currentGroupedStatuses;
  final GroupedStatus? currentUserStatusGroup;
  const StatusPosting({this.currentGroupedStatuses = const [], this.currentUserStatusGroup});
   @override
  List<Object?> get props => [currentGroupedStatuses, currentUserStatusGroup];
}

// StatusPostSuccess can be handled by showing a success message in StatusLoaded
// class StatusPostSuccess extends StatusState {}

class StatusError extends StatusState {
  final String message;
  final List<GroupedStatus> currentGroupedStatuses;
  final GroupedStatus? currentUserStatusGroup;

  const StatusError(
    this.message, {
    this.currentGroupedStatuses = const [],
    this.currentUserStatusGroup,
  });

  @override
  List<Object?> get props => [message, currentGroupedStatuses, currentUserStatusGroup];
}