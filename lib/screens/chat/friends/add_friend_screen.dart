import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:chat_app/core/di/service_locator.dart';
import 'package:chat_app/presentation/blocs/user_search/user_search_cubit.dart';
import 'package:chat_app/presentation/blocs/friends/friends_bloc.dart'; // To send friend request
import 'package:chat_app/data/models/user_model.dart';
import 'package:chat_app/presentation/blocs/auth/auth_bloc.dart';

class AddFriendScreen extends StatefulWidget {
  const AddFriendScreen({super.key});

  @override
  State<AddFriendScreen> createState() => _AddFriendScreenState();
}

class _AddFriendScreenState extends State<AddFriendScreen> {
  final _searchController = TextEditingController();
  UserSearchCubit? _userSearchCubit; // To be able to dispose it if created here
  FriendsBloc? _friendsBloc; // To be able to dispose it if created here


  @override
  void initState() {
    super.initState();
    // If providing BLoCs here, they need to be disposed if not managed by BlocProvider higher up.
    // It's often better to provide them via MultiBlocProvider if they are screen-specific.
    _userSearchCubit = sl<UserSearchCubit>();
    final currentUserId = context.read<AuthBloc>().state.user?.id;
    if (currentUserId != null) {
        _friendsBloc = sl<FriendsBloc>(param1: currentUserId); // Assuming FriendsBloc takes currentUserId
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _userSearchCubit?.close(); // Close if created here and not by BlocProvider
    _friendsBloc?.close();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (query.trim().length >= 3) {
      _userSearchCubit?.searchUsers(query.trim());
    } else {
      _userSearchCubit?.clearSearch();
    }
  }

  void _sendFriendRequest(String toUserId) {
    if (_friendsBloc != null) {
        _friendsBloc!.add(SendFriendRequestEvent(toUserId: toUserId));
    } else {
         ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(const SnackBar(content: Text('Error: Could not send request.')));
    }
  }


  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider( // Use MultiBlocProvider for screen-specific BLoCs
      providers: [
        if (_userSearchCubit != null) BlocProvider.value(value: _userSearchCubit!),
        if (_friendsBloc != null) BlocProvider.value(value: _friendsBloc!),
      ],
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Add Friend"),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: "Search by username...",
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 20),
                ),
                onChanged: _onSearchChanged,
              ),
            ),
            Expanded(
              child: BlocConsumer<FriendsBloc, FriendsState>( // For feedback on friend request
                bloc: _friendsBloc, // Explicitly pass bloc if not using context.watch/read from Builder
                listener: (context, friendState) {
                  if (friendState is FriendsOperationSuccess) {
                    ScaffoldMessenger.of(context)
                      ..hideCurrentSnackBar()
                      ..showSnackBar(SnackBar(content: Text(friendState.message), backgroundColor: Colors.green));
                    _searchController.clear(); // Clear search on success
                    _userSearchCubit?.clearSearch();
                  } else if (friendState is FriendsError) {
                    ScaffoldMessenger.of(context)
                      ..hideCurrentSnackBar()
                      ..showSnackBar(SnackBar(content: Text(friendState.message), backgroundColor: Colors.red));
                  }
                },
                builder: (context, friendState) { // This builder is just for structure, UserSearchCubit drives the list
                  return BlocBuilder<UserSearchCubit, UserSearchState>(
                    bloc: _userSearchCubit,
                    builder: (context, searchState) {
                      if (searchState is UserSearchLoading) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (searchState is UserSearchLoaded) {
                        if (searchState.users.isEmpty) {
                           return Center(child: Text(_searchController.text.trim().isEmpty ? "Type to search for users." : "No users found."));
                        }
                        return ListView.builder(
                          itemCount: searchState.users.length,
                          itemBuilder: (context, index) {
                            final user = searchState.users[index];
                            bool isRequestPendingOrSent = friendState is FriendsLoading; // Simplified check
                            // You might need a more complex check if FriendsBloc holds specific request states

                            return ListTile(
                              leading: CircleAvatar(
                                backgroundImage: user.avatarUrl != null ? NetworkImage(user.avatarUrl!) : null,
                                child: user.avatarUrl == null ? Text(user.username[0].toUpperCase()) : null,
                              ),
                              title: Text(user.username),
                              subtitle: Text(user.email ?? "No email"),
                              trailing: ElevatedButton(
                                onPressed: isRequestPendingOrSent ? null : () => _sendFriendRequest(user.id),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  textStyle: const TextStyle(fontSize: 13),
                                ),
                                child: isRequestPendingOrSent && (friendState is FriendsLoading) // Improve this condition
                                         ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2,))
                                         : const Text("Add"),
                              ),
                            );
                          },
                        );
                      }
                      if (searchState is UserSearchError) {
                        return Center(child: Text("Error: ${searchState.message}"));
                      }
                      return Center(child: Text(_searchController.text.trim().isEmpty ? "Type at least 3 characters to search." : "No users found."));
                    },
                  );
                }
              ),
            ),
          ],
        ),
      ),
    );
  }
}