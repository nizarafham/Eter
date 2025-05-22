

part of 'status_bloc.dart';

class GroupedStatus extends Equatable {
  final UserModel user;
  final List<StatusModel> statuses; // Sorted by createdAt
  final bool allViewed; // True if all statuses for this user have been viewed by current user

  const GroupedStatus({
    required this.user,
    required this.statuses,
    required this.allViewed,
  });

  @override
  List<Object?> get props => [user, statuses, allViewed];

  GroupedStatus copyWith({
    UserModel? user,
    List<StatusModel>? statuses,
    bool? allViewed,
  }) {
    return GroupedStatus(
      user: user ?? this.user,
      statuses: statuses ?? this.statuses,
      allViewed: allViewed ?? this.allViewed,
    );
  }
}