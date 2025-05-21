import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:chat_app/core/di/service_locator.dart';
import 'package:chat_app/data/models/conversation_model.dart';
import 'package:chat_app/presentation/blocs/auth/auth_bloc.dart';
import 'package:chat_app/presentation/blocs/conversations/conversations_bloc.dart';
import 'package:chat_app/presentation/screens/chat/chat_detail_screen.dart';
import 'package:intl/intl.dart'; // For date formatting

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUserId = context.read<AuthBloc>().state.user?.id;
    if (currentUserId == null) {
      return const Center(child: Text("User not logged in."));
    }

    return BlocProvider(
      create: (context) =>
          sl<ConversationsBloc>(param1: currentUserId)..add(LoadConversationsEvent()),
      child: BlocConsumer<ConversationsBloc, ConversationsState>(
        listener: (context, state) {
          if (state is NavigatingToConversation) {
            Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => ChatDetailScreen(conversationId: state.conversationId),
            ));
            // Optionally, clear the navigation event from bloc if it's one-off
            // context.read<ConversationsBloc>().add(ClearNavigationEvent());
          } else if (state is ConversationsError) {
             ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(SnackBar(content: Text(state.message)));
          }
        },
        builder: (context, state) {
          if (state is ConversationsLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is ConversationsLoaded) {
            if (state.conversations.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.chat_bubble_outline, size: 80, color: Colors.grey[700]),
                    const SizedBox(height: 16),
                    const Text(
                      "No chats yet.",
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Start a new conversation from 'Add Friend'\nor create a 'New Group'.",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              );
            }
            return ListView.separated(
              itemCount: state.conversations.length,
              separatorBuilder: (context, index) => Divider(height: 1, indent: 70, color: Colors.grey[800]),
              itemBuilder: (context, index) {
                final convo = state.conversations[index];
                String title = "Unknown Chat";
                String avatarText = "?";
                String? avatarUrl;

                if (convo.type == ConversationType.dm && convo.dmParticipant != null) {
                  title = convo.dmParticipant!.username;
                  avatarText = title.isNotEmpty ? title[0].toUpperCase() : "?";
                  avatarUrl = convo.dmParticipant!.avatarUrl;
                } else if (convo.type == ConversationType.group) {
                  title = convo.groupName ?? "Group Chat";
                  avatarText = title.isNotEmpty ? title[0].toUpperCase() : "G";
                  avatarUrl = convo.groupAvatarUrl;
                }

                return ListTile(
                  leading: CircleAvatar(
                    radius: 28,
                    backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
                    backgroundColor: avatarUrl == null ? Colors.accents[index % Colors.accents.length].withOpacity(0.5) : Colors.transparent,
                    child: avatarUrl == null ? Text(avatarText, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)) : null,
                  ),
                  title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
                  subtitle: convo.lastMessage != null
                      ? Text(
                          convo.lastMessage!.type == MessageType.image ? "📷 Photo" : (convo.lastMessage!.textContent ?? "Message"),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Colors.grey[400]),
                        )
                      : Text("No messages yet", style: TextStyle(color: Colors.grey[500], fontStyle: FontStyle.italic)),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (convo.lastMessage != null)
                        Text(
                          DateFormat('hh:mm a').format(convo.lastMessage!.createdAt),
                          style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                        ),
                      const SizedBox(height: 4),
                      if (convo.unreadCount > 0)
                        CircleAvatar(
                          radius: 10,
                          backgroundColor: Theme.of(context).primaryColor,
                          child: Text(
                            convo.unreadCount.toString(),
                            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                    ],
                  ),
                  onTap: () {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => ChatDetailScreen(conversationId: convo.id),
                    ));
                  },
                );
              },
            );
          }
          return const Center(child: Text("Failed to load conversations."));
        },
      ),
    );
  }
}