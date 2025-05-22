import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart'; 
import 'package:chat_app/data/models/notification_model.dart';
import 'package:chat_app/presentation/notifications/blocs/notifications_bloc.dart';
import 'package:chat_app/presentation/auth/blocs/auth_bloc.dart';
import 'package:chat_app/core/di/service_locator.dart';
// Import screens for navigation based on notification type
import 'package:chat_app/presentation/chat/screens/chat_detail_screen.dart';
// import 'package:chat_app/presentation/friends/screens/friend_requests_screen.dart'; // If you have a dedicated screen for requests

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  IconData _getIconForNotificationType(NotificationType type) {
    // ... (same as before)
    switch (type) {
      case NotificationType.friendRequest:
        return Icons.person_add_alt_1_outlined;
      case NotificationType.groupInvite:
        return Icons.group_add_outlined;
      case NotificationType.newMessage:
        return Icons.message_outlined;
      case NotificationType.statusUpdate:
        return Icons.camera_alt_outlined;
      case NotificationType.generic:
      default:
        return Icons.notifications_none_outlined;
    }
  }

  void _handleNavigation(BuildContext context, NotificationModel notification) {
    // Example navigation logic
    switch (notification.type) {
      case NotificationType.newMessage:
        final conversationId = notification.data?['conversation_id'] as String?;
        // Extract display_name from notification.data, provide a fallback.
        final String displayName = notification.data?['display_name'] as String? ?? "Chat"; // Fallback name

        if (conversationId != null) {
          Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => ChatDetailScreen(
              conversationId: conversationId,
              otherUserName: displayName, // <<< PASS THE DISPLAY NAME HERE
            ),
          ));
        } else {
          if (kDebugMode) {
            print("Error: newMessage notification missing conversation_id in data for notification ID: ${notification.id}");
          }
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Could not open chat. Information missing.")),
          );
        }
        break;
      case NotificationType.friendRequest:
        final String senderUsername = notification.data?['sender_username'] as String? ?? "A user";
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Tapped on friend request from $senderUsername")),
        );
        // TODO: Implement navigation or action for friend requests.
        // This might involve navigating to a specific tab in FriendsManagementScreen,
        // or if the notification itself had action_ids in its data, you could trigger
        // accept/decline actions here by dispatching to FriendsBloc.
        // Example: Navigator.of(context).push(MaterialPageRoute(builder: (_) => FriendsManagementScreen(initialTabIndex: 1)));
        break;
      // TODO: Add cases for other notification types (groupInvite, statusUpdate)
      case NotificationType.groupInvite:
         final String groupName = notification.data?['group_name'] as String? ?? "a group";
         final String groupId = notification.referenceId ?? notification.data?['group_id'] as String? ?? "";
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Invited to join $groupName (ID: $groupId)")),
          );
        // TODO: Navigate to group info screen or show accept/decline options.
        break;
      default:
        if (kDebugMode) {
          print("Tapped on notification: ${notification.title} of type ${notification.type}");
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Notification: ${notification.title}")),
        );
        break;
    }
  }

  // ... (rest of the NotificationsScreen build method remains the same)
  // Ensure the BlocConsumer for NavigateToNotificationTarget calls this _handleNavigation method.

  @override
  Widget build(BuildContext context) {
    final currentUserId = context.watch<AuthBloc>().state.user?.id;

    if (currentUserId == null) {
      return const Center(child: Text("User not authenticated."));
    }

    return BlocProvider(
      create: (context) => sl<NotificationsBloc>(param1: currentUserId)
        ..add(LoadNotifications()),
      child: Scaffold(
        body: BlocConsumer<NotificationsBloc, NotificationsState>(
          listener: (context, state) {
            if (state is NotificationsLoaded && state.successMessage != null) {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(SnackBar(
                  content: Text(state.successMessage!),
                  backgroundColor: Colors.green,
                  duration: const Duration(seconds: 2),
                ));
              context.read<NotificationsBloc>().emit(state.copyWith(clearSuccessMessage: true));
            } else if (state is NotificationsError) {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.red,
                  duration: const Duration(seconds: 2),
                ));
            } else if (state is NavigateToNotificationTarget) {
                _handleNavigation(context, state.notification); // Call the updated handler
            }
          },
          builder: (context, state) {
            // ... (the existing builder logic for displaying the list)
            if (state is NotificationsInitial || (state is NotificationsLoading && state.currentNotifications.isEmpty)) {
              return const Center(child: CircularProgressIndicator());
            }

            List<NotificationModel> notifications = [];
            if (state is NotificationsLoaded) {
              notifications = state.notifications;
            } else if (state is NotificationsLoading) {
              notifications = state.currentNotifications;
            } else if (state is NotificationsError) {
              notifications = state.currentNotifications;
            }


            if (notifications.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.notifications_off_outlined, size: 80, color: Colors.grey[700]),
                    const SizedBox(height: 16),
                    const Text("No notifications yet.", style: TextStyle(fontSize: 18, color: Colors.grey)),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () async {
                context.read<NotificationsBloc>().add(LoadNotifications());
              },
              child: ListView.separated(
                itemCount: notifications.length,
                separatorBuilder: (context, index) => const Divider(height: 1, indent: 72, endIndent: 16), // Indent after avatar
                itemBuilder: (context, index) {
                  final notification = notifications[index];
                  final bool isUnread = !notification.isRead;

                  return Dismissible(
                    key: Key(notification.id),
                    direction: DismissDirection.endToStart,
                    onDismissed: (direction) {
                      context.read<NotificationsBloc>().add(DeleteNotification(notification.id));
                    },
                    background: Container(
                      color: Colors.redAccent.withOpacity(0.8),
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: const Icon(Icons.delete_sweep_outlined, color: Colors.white),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: isUnread
                            ? Theme.of(context).primaryColor.withOpacity(0.15)
                            : Theme.of(context).colorScheme.surfaceContainerHighest,
                        child: Icon(
                          _getIconForNotificationType(notification.type),
                          color: isUnread ? Theme.of(context).primaryColor : Theme.of(context).colorScheme.onSurfaceVariant,
                          size: 24,
                        ),
                      ),
                      title: Text(
                        notification.title,
                        style: TextStyle(
                          fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
                           color: isUnread ? Theme.of(context).colorScheme.onSurface : Theme.of(context).colorScheme.onSurface.withOpacity(0.7)
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            notification.body,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              color: isUnread ? Theme.of(context).colorScheme.onSurface.withOpacity(0.8) : Theme.of(context).colorScheme.onSurface.withOpacity(0.6)
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            DateFormat('MMM d, hh:mm a').format(notification.createdAt.toLocal()),
                            style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                          ),
                        ],
                      ),
                      isThreeLine: true, // Allows subtitle to take up more space if needed
                      tileColor: isUnread ? Theme.of(context).primaryColor.withOpacity(0.03) : null,
                      onTap: () {
                        context.read<NotificationsBloc>().add(NotificationTapped(notification));
                      },
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}