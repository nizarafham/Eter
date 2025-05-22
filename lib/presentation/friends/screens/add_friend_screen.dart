// lib/presentation/friends/screens/add_friend_screen.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:chat_app/core/di/service_locator.dart';
import 'package:chat_app/presentation/user_search/blocs/user_search_cubit.dart';
import 'package:chat_app/presentation/friends/blocs/friends_bloc.dart';
import 'package:chat_app/data/models/user_model.dart';
import 'package:chat_app/data/models/friendship_model.dart'; // For FriendshipStatus
import 'package:chat_app/presentation/auth/blocs/auth_bloc.dart';

class AddFriendScreen extends StatefulWidget {
  const AddFriendScreen({super.key});

  @override
  State<AddFriendScreen> createState() => _AddFriendScreenState();
}

class _AddFriendScreenState extends State<AddFriendScreen> {
  final _searchController = TextEditingController();
  // Debouncer for search to avoid excessive API calls
  Timer? _debounce;

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(BuildContext context, String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (query.trim().length >= 2) {
        context.read<UserSearchCubit>().searchUsers(query.trim());
      } else {
        context.read<UserSearchCubit>().clearSearch();
      }
    });
  }

  void _sendFriendRequest(BuildContext context, String toUserId) {
    context.read<FriendsBloc>().add(SendFriendRequestEvent(toUserId: toUserId));
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = context.watch<AuthBloc>().state.user?.id;

    if (currentUserId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Add Friend")),
        body: const Center(child: Text("Authentication error. Please login again.")),
      );
    }

    // Provide UserSearchCubit and FriendsBloc locally for this screen
    // FriendsBloc is provided here to handle 'SendFriendRequestEvent' and listen for its outcome.
    // It also loads existing friends/requests to determine button states.
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => sl<UserSearchCubit>(),
        ),
        BlocProvider(
          create: (context) => sl<FriendsBloc>(param1: currentUserId) // param1 is currentUserId
            ..add(LoadFriendsAndRequestsEvent()), // Load existing relationships
        ),
      ],
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Add Friend"),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Builder(
                builder: (innerContext) { // Use Builder for context with UserSearchCubit
                  return TextField(
                    controller: _searchController,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: "Search by username...",
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Theme.of(context).colorScheme.outline),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Theme.of(context).colorScheme.outline),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 1.5),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                innerContext.read<UserSearchCubit>().clearSearch();
                              },
                            )
                          : null,
                    ),
                    onChanged: (query) => _onSearchChanged(innerContext, query),
                  );
                },
              ),
            ),
            Expanded(
              child: BlocConsumer<FriendsBloc, FriendsState>(
                // Listener for feedback on friend request actions
                listener: (context, friendState) {
                  if (friendState is FriendsLoaded && friendState.successMessage != null) {
                    ScaffoldMessenger.of(context)
                      ..hideCurrentSnackBar()
                      ..showSnackBar(SnackBar(
                        content: Text(friendState.successMessage!),
                        backgroundColor: Colors.green,
                        duration: const Duration(seconds: 2),
                      ));
                    // Clear the message after showing it
                    context.read<FriendsBloc>().emit(friendState.copyWith(clearSuccessMessage: true));
                    // Optionally, refresh search or update UI after successful request
                     if (_searchController.text.isNotEmpty) { // Re-trigger search if needed, or rely on stream
                       _onSearchChanged(context, _searchController.text);
                     }
                  } else if (friendState is FriendsError) {
                    ScaffoldMessenger.of(context)
                      ..hideCurrentSnackBar()
                      ..showSnackBar(SnackBar(
                        content: Text(friendState.message),
                        backgroundColor: Colors.red,
                        duration: const Duration(seconds: 2),
                      ));
                  }
                },
                // Builder to get current friend/request state for button logic
                builder: (context, friendState) {
                  return BlocBuilder<UserSearchCubit, UserSearchState>(
                    builder: (context, searchState) {
                      if (searchState is UserSearchLoading) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (searchState is UserSearchLoaded) {
                        final displayUsers = searchState.users.where((user) => user.id != currentUserId).toList();

                        if (displayUsers.isEmpty) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Text(
                                _searchController.text.trim().isEmpty
                                    ? "Type a username to find friends."
                                    : "No users found matching your search.",
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                              ),
                            )
                          );
                        }

                        return ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          itemCount: displayUsers.length,
                          separatorBuilder: (ctx, idx) => const Divider(height: 0.5),
                          itemBuilder: (context, index) {
                            final user = displayUsers[index];
                            Widget trailingWidget;

                            bool isLoadingAction = friendState is FriendsOperationInProgress; // Or check for specific request ID

                            if (friendState is FriendsLoaded || friendState is FriendsOperationInProgress) {
                              List<FriendshipModel> currentFriends = [];
                              List<FriendshipModel> currentRequests = [];

                              if (friendState is FriendsLoaded) {
                                currentFriends = friendState.friends;
                                currentRequests = friendState.friendRequests;
                              } else if (friendState is FriendsOperationInProgress) {
                                currentFriends = friendState.friends; // Use data from FriendsOperationInProgress
                                currentRequests = friendState.friendRequests;
                              }


                              final existingFriendship = currentFriends.where((f) => (f.userId1 == user.id || f.userId2 == user.id) && f.status == FriendshipStatus.accepted);
                              final pendingRequest = currentRequests.where((r) => (r.userId1 == user.id || r.userId2 == user.id) && r.status == FriendshipStatus.pending);

                              if (existingFriendship.isNotEmpty) {
                                trailingWidget = Chip(
                                  avatar: Icon(Icons.check_circle, color: Theme.of(context).primaryColor, size: 18),
                                  label: Text("Friend", style: TextStyle(color: Theme.of(context).primaryColor)),
                                  backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  visualDensity: VisualDensity.compact,
                                );
                              } else if (pendingRequest.isNotEmpty) {
                                // Check if current user sent the request or received it
                                bool sentByMe = pendingRequest.first.actionUserId == currentUserId;
                                trailingWidget = Chip(
                                  label: Text(sentByMe ? "Requested" : "Pending", style: TextStyle(color: Colors.orange.shade700)),
                                  backgroundColor: Colors.orange.withOpacity(0.1),
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  visualDensity: VisualDensity.compact,
                                );
                              } else {
                                trailingWidget = ElevatedButton.icon(
                                  icon: isLoadingAction
                                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                      : const Icon(Icons.person_add_alt_1, size: 18),
                                  label: const Text("Add"),
                                  onPressed: isLoadingAction ? null : () => _sendFriendRequest(context, user.id),
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                  ),
                                );
                              }
                            } else {
                              // Fallback if FriendsBloc is in initial or error state (less likely with initial load)
                               trailingWidget = ElevatedButton.icon(
                                icon: const Icon(Icons.person_add_alt_1, size: 18),
                                label: const Text("Add"),
                                onPressed: () => _sendFriendRequest(context, user.id),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                ),
                              );
                            }

                            return ListTile(
                              leading: CircleAvatar(
                                radius: 24,
                                backgroundImage: user.avatarUrl != null && user.avatarUrl!.isNotEmpty
                                    ? NetworkImage(user.avatarUrl!)
                                    : null,
                                child: (user.avatarUrl == null || user.avatarUrl!.isEmpty)
                                    ? Text(user.username[0].toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18))
                                    : null,
                                backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                              ),
                              title: Text(user.username, style: const TextStyle(fontWeight: FontWeight.w500)),
                              subtitle: Text(user.email ?? "No email", style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                              trailing: trailingWidget,
                              contentPadding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
                            );
                          },
                        );
                      }
                      if (searchState is UserSearchError) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Text(
                              "Error searching users: ${searchState.message}.\nPlease check your connection and try again.",
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 16, color: Theme.of(context).colorScheme.error),
                            ),
                          )
                        );
                      }
                      if (searchState is UserSearchEmpty) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Text(
                              "No users found matching '${_searchController.text}'.\nTry a different username.",
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                            ),
                          )
                        );
                      }
                      // UserSearchInitial state
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(
                            _searchController.text.trim().isEmpty
                                ? "Type at least 2 characters to search for users."
                                : "", // Handled by UserSearchEmpty if query submitted
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                          ),
                        )
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}