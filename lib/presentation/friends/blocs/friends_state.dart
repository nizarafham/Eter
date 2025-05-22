part of 'friends_bloc.dart';

abstract class FriendsState extends Equatable {
  const FriendsState();

  @override
  List<Object?> get props => [];
}

class FriendsInitial extends FriendsState {}

class FriendsLoading extends FriendsState {
  final List<FriendshipModel> currentFriends;
  final List<FriendshipModel> currentRequests;

  // Keep current data while loading new/performing actions
  const FriendsLoading({
    this.currentFriends = const [],
    this.currentRequests = const [],
  });

  @override
  List<Object?> get props => [currentFriends, currentRequests];
}

class FriendsLoaded extends FriendsState {
  final List<FriendshipModel> friends;
  final List<FriendshipModel> friendRequests; // Pending requests (incoming & outgoing)
  final String? successMessage; // For transient success messages

  const FriendsLoaded({
    required this.friends,
    required this.friendRequests,
    this.successMessage,
  });

  // Helper to get only incoming requests for the current user
  List<FriendshipModel> getIncomingRequests(String currentUserId) {
    return friendRequests.where((req) => req.userId2 == currentUserId && req.actionUserId != currentUserId).toList();
  }

  // Helper to get only outgoing requests from the current user
  List<FriendshipModel> getOutgoingRequests(String currentUserId) {
    return friendRequests.where((req) => req.userId1 == currentUserId && req.actionUserId == currentUserId).toList();
  }


  @override
  List<Object?> get props => [friends, friendRequests, successMessage];

  FriendsLoaded copyWith({
    List<FriendshipModel>? friends,
    List<FriendshipModel>? friendRequests,
    String? successMessage,
    bool clearSuccessMessage = false,
  }) {
    return FriendsLoaded(
      friends: friends ?? this.friends,
      friendRequests: friendRequests ?? this.friendRequests,
      successMessage: clearSuccessMessage ? null : successMessage ?? this.successMessage,
    );
  }
}

class FriendsOperationInProgress extends FriendsLoaded { // Extends FriendsLoaded to keep UI state
  const FriendsOperationInProgress({
    required super.friends,
    required super.friendRequests,
  });
}

class FriendsError extends FriendsState {
  final String message;
  final List<FriendshipModel> currentFriends; // Keep current data on error
  final List<FriendshipModel> currentRequests;

  const FriendsError(
    this.message, {
    this.currentFriends = const [],
    this.currentRequests = const [],
  });

  @override
  List<Object?> get props => [message, currentFriends, currentRequests];
}