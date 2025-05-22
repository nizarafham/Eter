part of 'friends_bloc.dart';


abstract class FriendsEvent extends Equatable {
  const FriendsEvent();

  @override
  List<Object?> get props => [];
}

/// Triggered to load initial friends and requests, and to set up streams.
class LoadFriendsAndRequestsEvent extends FriendsEvent {}

/// Internal event when the list of accepted friends is updated from the stream.
class _FriendsListUpdatedEvent extends FriendsEvent {
  final List<FriendshipModel> friends;
  const _FriendsListUpdatedEvent(this.friends);
  @override
  List<Object?> get props => [friends];
}

/// Internal event when the list of friend requests is updated from the stream.
class _FriendRequestsListUpdatedEvent extends FriendsEvent {
  final List<FriendshipModel> requests;
  const _FriendRequestsListUpdatedEvent(this.requests);
  @override
  List<Object?> get props => [requests];
}

/// Event to send a friend request to a user.
class SendFriendRequestEvent extends FriendsEvent {
  final String toUserId;
  const SendFriendRequestEvent({required this.toUserId});
  @override
  List<Object?> get props => [toUserId];
}

/// Event to accept a pending friend request.
class AcceptFriendRequestEvent extends FriendsEvent {
  final FriendshipModel requestToAccept; // Pass the whole model for context
  const AcceptFriendRequestEvent(this.requestToAccept);
  @override
  List<Object?> get props => [requestToAccept];
}

/// Event to decline or cancel a pending friend request.
class DeclineOrCancelFriendRequestEvent extends FriendsEvent {
  final FriendshipModel requestToDecline; // Pass the whole model for context
  const DeclineOrCancelFriendRequestEvent(this.requestToDecline);
  @override
  List<Object?> get props => [requestToDecline];
}

/// Event to remove an existing friend.
class RemoveFriendEvent extends FriendsEvent {
  final FriendshipModel friendToRemove; // Pass the whole model for context
  const RemoveFriendEvent(this.friendToRemove);
  @override
  List<Object?> get props => [friendToRemove];
}