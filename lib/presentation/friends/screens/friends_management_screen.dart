import 'package:chat_app/data/models/friendship_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:chat_app/presentation/friends/blocs/friends_bloc.dart';
import 'package:chat_app/presentation/auth/blocs/auth_bloc.dart';
import 'package:chat_app/core/di/service_locator.dart';
import 'package:chat_app/presentation/friends/widgets/friends_list_view.dart'; // We'll create this
import 'package:chat_app/presentation/friends/widgets/friend_requests_view.dart'; // We'll create this
import 'package:chat_app/presentation/friends/screens/add_friend_screen.dart';


class FriendsManagementScreen extends StatelessWidget {
  const FriendsManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUserId = context.watch<AuthBloc>().state.user?.id;

    if (currentUserId == null) {
      return const Scaffold(body: Center(child: Text("User not authenticated.")));
    }

    return BlocProvider(
      create: (context) => sl<FriendsBloc>(param1: currentUserId) // param1 is currentUserId
        ..add(LoadFriendsAndRequestsEvent()),
      child: DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: AppBar(
            title: const Text("Manage Friends"),
            actions: [
              IconButton(
                icon: const Icon(Icons.person_add_alt_1),
                tooltip: "Add Friend",
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const AddFriendScreen()),
                  );
                },
              ),
            ],
            bottom: const TabBar(
              indicatorColor: Colors.greenAccent,
              indicatorWeight: 3,
              tabs: [
                Tab(text: "MY FRIENDS"),
                Tab(text: "REQUESTS"),
              ],
            ),
          ),
          body: BlocConsumer<FriendsBloc, FriendsState>(
            listener: (context, state) {
              if (state is FriendsLoaded && state.successMessage != null) {
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(SnackBar(
                    content: Text(state.successMessage!),
                    backgroundColor: Colors.green,
                  ));
                // Clear the message after showing
                context.read<FriendsBloc>().emit(state.copyWith(clearSuccessMessage: true));
              } else if (state is FriendsError) {
                 ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(SnackBar(
                    content: Text(state.message),
                    backgroundColor: Colors.red,
                  ));
              }
            },
            builder: (context, state) {
              if (state is FriendsInitial || (state is FriendsLoading && state.currentFriends.isEmpty && state.currentRequests.isEmpty)) {
                return const Center(child: CircularProgressIndicator());
              }

              List<FriendshipModel> friends = [];
              List<FriendshipModel> incomingRequests = [];
              // List<FriendshipModel> outgoingRequests = []; // If you want to display them

              if (state is FriendsLoaded) {
                friends = state.friends;
                incomingRequests = state.getIncomingRequests(currentUserId);
                // outgoingRequests = state.getOutgoingRequests(currentUserId);
              } else if (state is FriendsLoading) { // Show stale data while loading
                friends = state.currentFriends;
                // For simplicity, just show empty if loading requests for the first time
                // incomingRequests = state.currentRequests.where((req) => req.userId2 == currentUserId && req.actionUserId != currentUserId).toList();
              } else if (state is FriendsError) { // Show stale data on error
                 friends = state.currentFriends;
                 // incomingRequests = state.currentRequests.where((req) => req.userId2 == currentUserId && req.actionUserId != currentUserId).toList();
              }


              return TabBarView(
                children: [
                  FriendsListView(friends: friends, currentUserId: currentUserId),
                  FriendRequestsView(requests: incomingRequests, currentUserId: currentUserId),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}