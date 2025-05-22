import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:chat_app/data/models/friendship_model.dart';
import 'package:chat_app/data/models/user_model.dart'; // For display
import 'package:chat_app/presentation/friends/blocs/friends_bloc.dart';

class FriendRequestsView extends StatelessWidget {
  final List<FriendshipModel> requests; // These should be incoming requests
  final String currentUserId;

  const FriendRequestsView({
    super.key,
    required this.requests,
    required this.currentUserId,
  });

  // Placeholder for fetching user details
  UserModel? _getRequestSenderDetails(FriendshipModel request) {
    // Assuming 'user_id1' is the sender if current user is 'user_id2' and status is 'pending'
    // This needs to be robust based on your FriendshipModel structure and how action_user_id is set
    final senderId = request.actionUserId; // The user who initiated the pending request
    if (request.user1Details != null && request.user1Details!.id == senderId) return request.user1Details;
    if (request.user2Details != null && request.user2Details!.id == senderId) return request.user2Details;
    return UserModel(id: senderId ?? "unknown", username: "User ${senderId ?? 'unknown'}".substring(0,10), createdAt: DateTime.now()); // Placeholder
  }


  @override
  Widget build(BuildContext context) {
    final incomingRequests = requests.where((req) => req.userId2 == currentUserId && req.status == FriendshipStatus.pending).toList();
    // You might also want to show outgoing pending requests separately if desired.

    if (incomingRequests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.no_accounts_outlined, size: 80, color: Colors.grey[700]),
            const SizedBox(height: 16),
            const Text(
              "No new friend requests.",
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: incomingRequests.length,
      itemBuilder: (context, index) {
        final request = incomingRequests[index];
        // The sender is user_id1 if current user is user_id2 for an incoming request
        final senderDetails = _getRequestSenderDetails(request);

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: ListTile(
            leading: CircleAvatar(
              backgroundImage: senderDetails?.avatarUrl != null ? NetworkImage(senderDetails!.avatarUrl!) : null,
              child: senderDetails?.avatarUrl == null
                  ? Text(senderDetails?.username[0].toUpperCase() ?? "?")
                  : null,
            ),
            title: Text("${senderDetails?.username ?? 'Someone'} sent you a friend request."),
            subtitle: Text("Received on ${request.createdAt.toLocal().day}/${request.createdAt.toLocal().month}"),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextButton(
                  onPressed: () {
                    context.read<FriendsBloc>().add(AcceptFriendRequestEvent(request));
                  },
                  style: TextButton.styleFrom(backgroundColor: Colors.green.withOpacity(0.1)),
                  child: const Text("ACCEPT", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () {
                    context.read<FriendsBloc>().add(DeclineOrCancelFriendRequestEvent(request));
                  },
                   style: TextButton.styleFrom(backgroundColor: Colors.red.withOpacity(0.1)),
                  child: const Text("DECLINE", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}