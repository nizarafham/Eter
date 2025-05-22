import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart'; // For kDebugMode or print
import 'package:chat_app/data/models/friendship_model.dart';
import 'package:chat_app/data/repositories/friendship_repository.dart';

part 'friends_event.dart';
part 'friends_state.dart';

class FriendsBloc extends Bloc<FriendsEvent, FriendsState> {
  final FriendsRepository _friendsRepository;
  final String _currentUserId;

  StreamSubscription? _friendsSubscription;
  StreamSubscription? _requestsSubscription;

  FriendsBloc({
    required FriendsRepository friendsRepository,
    required String currentUserId,
  })  : _friendsRepository = friendsRepository,
        _currentUserId = currentUserId,
        super(FriendsInitial()) {
    on<LoadFriendsAndRequestsEvent>(_onLoadFriendsAndRequests);
    on<_FriendsListUpdatedEvent>(_onFriendsListUpdated);
    on<_FriendRequestsListUpdatedEvent>(_onFriendRequestsListUpdated);
    on<SendFriendRequestEvent>(_onSendFriendRequest);
    on<AcceptFriendRequestEvent>(_onAcceptFriendRequest);
    on<DeclineOrCancelFriendRequestEvent>(_onDeclineOrCancelFriendRequest);
    on<RemoveFriendEvent>(_onRemoveFriend);
  }

  List<FriendshipModel> _getCurrentFriendsFromState() {
    if (state is FriendsLoaded) return (state as FriendsLoaded).friends;
    if (state is FriendsLoading) return (state as FriendsLoading).currentFriends;
    if (state is FriendsError) return (state as FriendsError).currentFriends;
    return const [];
  }

  List<FriendshipModel> _getCurrentRequestsFromState() {
    if (state is FriendsLoaded) return (state as FriendsLoaded).friendRequests;
    if (state is FriendsLoading) return (state as FriendsLoading).currentRequests;
    if (state is FriendsError) return (state as FriendsError).currentRequests;
    return const [];
  }

  void _onLoadFriendsAndRequests(
    LoadFriendsAndRequestsEvent event,
    Emitter<FriendsState> emit,
  ) {
    emit(FriendsLoading(
      currentFriends: _getCurrentFriendsFromState(),
      currentRequests: _getCurrentRequestsFromState(),
    ));

    _friendsSubscription?.cancel();
    _friendsSubscription = _friendsRepository.getFriends(_currentUserId).listen(
          (dynamic friendsRaw) { // Listen as dynamic first
            if (friendsRaw is List<FriendshipModel>) {
              add(_FriendsListUpdatedEvent(friendsRaw));
            } else if (friendsRaw is List) {
              if (kDebugMode) {
                print("FRIENDS_BLOC: _friendsSubscription received List<dynamic>. Attempting manual cast.");
              }
              try {
                final List<FriendshipModel> correctlyCastedFriends =
                    List<FriendshipModel>.from(friendsRaw.map((item) {
                  if (item is Map<String, dynamic>) {
                    return FriendshipModel.fromMap(item);
                  } else if (item is FriendshipModel) {
                    return item;
                  }
                  throw Exception("Unexpected item type in friends list: ${item.runtimeType}");
                }));
                add(_FriendsListUpdatedEvent(correctlyCastedFriends));
              } catch (e) {
                if (kDebugMode) {
                  print("FRIENDS_BLOC: Failed to cast friends list: $e");
                }
                emit(FriendsError(
                  "Internal error processing friends list.",
                  currentFriends: _getCurrentFriendsFromState(),
                  currentRequests: _getCurrentRequestsFromState(),
                ));
              }
            } else {
               if (kDebugMode) {
                 print("FRIENDS_BLOC: _friendsSubscription received unexpected data type: ${friendsRaw.runtimeType}");
               }
               emit(FriendsError("Unexpected data from friends stream.", currentFriends: _getCurrentFriendsFromState(), currentRequests: _getCurrentRequestsFromState()));
            }
          },
          onError: (error) => emit(FriendsError(
            "Failed to load friends: ${error.toString()}",
            currentFriends: _getCurrentFriendsFromState(),
            currentRequests: _getCurrentRequestsFromState(),
          )),
        );

    _requestsSubscription?.cancel();
    _requestsSubscription = _friendsRepository.getFriendRequests(_currentUserId).listen(
          (dynamic requestsRaw) { // Listen as dynamic first to inspect
            if (requestsRaw is List<FriendshipModel>) {
              add(_FriendRequestsListUpdatedEvent(requestsRaw));
            } else if (requestsRaw is List) {
              if (kDebugMode) {
                print("FRIENDS_BLOC: _requestsSubscription received List<dynamic> for currentRequests. Attempting manual cast.");
              }
              try {
                final List<FriendshipModel> correctlyCastedRequests = List<FriendshipModel>.from(
                    requestsRaw.map((item) {
                      if (item is Map<String, dynamic>) { // If it's still raw maps
                        return FriendshipModel.fromMap(item);
                      } else if (item is FriendshipModel) { // If some are already models
                        return item;
                      }
                      throw Exception("Unexpected item type in requests list: ${item.runtimeType}");
                    })
                );
                add(_FriendRequestsListUpdatedEvent(correctlyCastedRequests));
              } catch (e) {
                if (kDebugMode) {
                  print("FRIENDS_BLOC: Failed to cast requests list for currentRequests: $e");
                }
                emit(FriendsError(
                  "Internal error processing friend requests (att currentRequests).",
                  currentFriends: _getCurrentFriendsFromState(),
                  currentRequests: _getCurrentRequestsFromState(), 
                ));
              }
            } else {
               if (kDebugMode) {
                 print("FRIENDS_BLOC: _requestsSubscription received unexpected data type for currentRequests: ${requestsRaw.runtimeType}");
               }
               emit(FriendsError(
                  "Unexpected data from friend requests stream (att currentRequests).",
                  currentFriends: _getCurrentFriendsFromState(),
                  currentRequests: _getCurrentRequestsFromState(),
                ));
            }
          },
          onError: (error) => emit(FriendsError(
            "Failed to load friend requests: ${error.toString()}",
            currentFriends: _getCurrentFriendsFromState(),
            currentRequests: _getCurrentRequestsFromState(),
          )),
        );
  }

  void _onFriendsListUpdated(
    _FriendsListUpdatedEvent event, // event.friends is List<FriendshipModel>
    Emitter<FriendsState> emit,
  ) {
    emit(FriendsLoaded(
        friends: event.friends, // This is now guaranteed List<FriendshipModel>
        friendRequests: _getCurrentRequestsFromState()));
  }

  void _onFriendRequestsListUpdated(
    _FriendRequestsListUpdatedEvent event, // event.requests is List<FriendshipModel>
    Emitter<FriendsState> emit,
  ) {
    emit(FriendsLoaded(
        friends: _getCurrentFriendsFromState(),
        friendRequests: event.requests)); // This is now guaranteed List<FriendshipModel>
  }

  // ... (Action methods: _onSendFriendRequest, _onAcceptFriendRequest, etc. remain the same as the previous good version)
  // They rely on _getCurrentFriendsFromState() and _getCurrentRequestsFromState() which should now be more robust.

  Future<void> _onSendFriendRequest(
    SendFriendRequestEvent event,
    Emitter<FriendsState> emit,
  ) async {
    final friends = _getCurrentFriendsFromState();
    final requests = _getCurrentRequestsFromState();

    emit(FriendsOperationInProgress(
      friends: friends,
      friendRequests: requests,
    ));
    try {
      await _friendsRepository.sendFriendRequest(_currentUserId, event.toUserId);
      emit(FriendsLoaded(
        friends: friends,
        friendRequests: requests,
        successMessage: "Friend request sent!",
      ));
    } catch (e) {
      emit(FriendsError(
        "Failed to send friend request: ${e.toString()}",
        currentFriends: friends,
        currentRequests: requests,
      ));
    }
  }

  Future<void> _onAcceptFriendRequest(
    AcceptFriendRequestEvent event,
    Emitter<FriendsState> emit,
  ) async {
    final friends = _getCurrentFriendsFromState();
    final requests = _getCurrentRequestsFromState();

    emit(FriendsOperationInProgress(friends: friends, friendRequests: requests));
    try {
      await _friendsRepository.acceptFriendRequest(event.requestToAccept.id, _currentUserId);
      // Note: event.requestToAccept.user1Details might be null if not populated from data source
      final senderName = event.requestToAccept.getFriend(event.requestToAccept.actionUserId ?? _currentUserId)?.username ??
                         event.requestToAccept.actionUserId ?? 
                         'User';
      emit(FriendsLoaded(
          friends: friends, 
          friendRequests: requests.where((r) => r.id != event.requestToAccept.id).toList(), 
          successMessage: "$senderName accepted as friend!"));
    } catch (e) {
      emit(FriendsError("Failed to accept request: ${e.toString()}", currentFriends: friends, currentRequests: requests));
    }
  }

  Future<void> _onDeclineOrCancelFriendRequest(
    DeclineOrCancelFriendRequestEvent event,
    Emitter<FriendsState> emit,
  ) async {
    final friends = _getCurrentFriendsFromState();
    final requests = _getCurrentRequestsFromState();

    emit(FriendsOperationInProgress(friends: friends, friendRequests: requests));
    try {
      await _friendsRepository.declineOrCancelFriendRequest(event.requestToDecline.id);
      emit(FriendsLoaded(
          friends: friends,
          friendRequests: requests.where((r) => r.id != event.requestToDecline.id).toList(), 
          successMessage: "Friend request declined/cancelled."));
    } catch (e) {
      emit(FriendsError("Failed to decline request: ${e.toString()}", currentFriends: friends, currentRequests: requests));
    }
  }

  Future<void> _onRemoveFriend(
    RemoveFriendEvent event,
    Emitter<FriendsState> emit,
  ) async {
    final friends = _getCurrentFriendsFromState();
    final requests = _getCurrentRequestsFromState();

    emit(FriendsOperationInProgress(friends: friends, friendRequests: requests));
    try {
      await _friendsRepository.removeFriend(event.friendToRemove.id);
      final friendName = event.friendToRemove.getFriend(_currentUserId)?.username ?? "User";
      emit(FriendsLoaded(
          friends: friends.where((f) => f.id != event.friendToRemove.id).toList(), 
          friendRequests: requests,
          successMessage: "$friendName removed from friends."));
    } catch (e) {
      emit(FriendsError("Failed to remove friend: ${e.toString()}", currentFriends: friends, currentRequests: requests));
    }
  }


  @override
  Future<void> close() {
    _friendsSubscription?.cancel();
    _requestsSubscription?.cancel();
    return super.close();
  }
}