import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:chat_app/data/models/friendship_model.dart';
import 'package:chat_app/data/models/user_model.dart'; // To display friend's details
import 'package:chat_app/presentation/friends/blocs/friends_bloc.dart';
// Placeholder for fetching user details - in a real app, you'd fetch these
// or have them denormalized in FriendshipModel.
// For now, we'll just show IDs or a generic name.

class FriendsListView extends StatelessWidget {
  final List<FriendshipModel> friends;
  final String currentUserId;

  const FriendsListView({
    super.key,
    required this.friends,
    required this.currentUserId,
  });

  // In a real app, you'd fetch UserModel for the friend
  UserModel? _getFriendDetails(FriendshipModel friendship) {
    // This is a placeholder. Ideally, FriendshipModel would contain denormalized friend info
    // or you'd have a way to fetch UserModel based on the friend's ID.
    final friendId = friendship.userId1 == currentUserId ? friendship.userId2 : friendship.userId1;
    // Simulating having the friend's details (you'd fetch this properly)
    if (friendship.user1Details != null && friendship.user1Details!.id == friendId) return friendship.user1Details;
    if (friendship.user2Details != null && friendship.user2Details!.id == friendId) return friendship.user2Details;
    return UserModel(id: friendId, username: "Friend $friendId".substring(0,10), createdAt: DateTime.now()); // Placeholder
  }


  void _confirmRemoveFriend(BuildContext context, FriendshipModel friend) {
    final friendDetails = _getFriendDetails(friend);
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Remove Friend"),
        content: Text("Are you sure you want to remove ${friendDetails?.username ?? 'this user'} from your friends?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text("CANCEL"),
          ),
          TextButton(
            onPressed: () {
              context.read<FriendsBloc>().add(RemoveFriendEvent(friend));
              Navigator.of(dialogContext).pop();
            },
            child: Text("REMOVE", style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (friends.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 80, color: Colors.grey[700]),
            const SizedBox(height: 16),
            const Text(
              "No friends yet.",
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(
              "Use the '+' button to add friends.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      itemCount: friends.length,
      separatorBuilder: (context, index) => const Divider(height: 1, indent: 70),
      itemBuilder: (context, index) {
        final friendship = friends[index];
        final friendDetails = _getFriendDetails(friendship); // Placeholder for actual friend details

        return ListTile(
          leading: CircleAvatar(
            radius: 25,
            backgroundImage: friendDetails?.avatarUrl != null ? NetworkImage(friendDetails!.avatarUrl!) : null,
            child: friendDetails?.avatarUrl == null
                ? Text(friendDetails?.username[0].toUpperCase() ?? "?", style: const TextStyle(fontWeight: FontWeight.bold))
                : null,
          ),
          title: Text(friendDetails?.username ?? "Unknown Friend", style: const TextStyle(fontWeight: FontWeight.w500)),
          subtitle: Text("Friends since ${friendship.updatedAt.toLocal().year}", style: TextStyle(color: Colors.grey[600])), // 'updated_at' for accepted date
          trailing: PopupMenuButton<String>(
            icon: const Icon(Icons.more_horiz),
            onSelected: (value) {
              if (value == 'remove') {
                _confirmRemoveFriend(context, friendship);
              } else if (value == 'chat') {
                // TODO: Navigate to chat screen with this friend
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Start chat with ${friendDetails?.username}")));
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'chat',
                child: ListTile(leading: Icon(Icons.chat_bubble_outline), title: Text('Chat')),
              ),
              const PopupMenuItem<String>(
                value: 'remove',
                child: ListTile(leading: Icon(Icons.person_remove_outlined, color: Colors.red), title: Text('Remove Friend', style: TextStyle(color: Colors.red))),
              ),
            ],
          ),
          onTap: () {
             // TODO: Navigate to chat screen or friend's profile
             ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("View profile of ${friendDetails?.username}")));
          },
        );
      },
    );
  }
}