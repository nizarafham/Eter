import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:chat_app/core/di/service_locator.dart';
import 'package:chat_app/data/models/conversation_model.dart';
import 'package:chat_app/presentation/auth/blocs/auth_bloc.dart';
import 'package:chat_app/presentation/conversations/blocs/conversations_bloc.dart';
import 'package:chat_app/presentation/chat/screens/chat_detail_screen.dart'; // Layar detail chat Anda
import 'package:timeago/timeago.dart' as timeago;
import 'package:cached_network_image/cached_network_image.dart'; // Untuk avatar

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUserId = context.watch<AuthBloc>().state.user?.id;

    if (currentUserId == null) {
      return const Center(child: Text("Pengguna tidak terautentikasi."));
    }

    return BlocProvider(
      create: (context) => sl<ConversationsBloc>(param1: currentUserId) // param1 adalah currentUserId
        ..add(LoadConversations()),
      child: Scaffold(
        // AppBar biasanya bagian dari HomeScreen, jadi mungkin tidak perlu di sini
        // appBar: AppBar(title: const Text("Chats")),
        body: BlocConsumer<ConversationsBloc, ConversationsState>(
          listener: (context, state) {
            if (state is NavigateToChatDetail) {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => ChatDetailScreen(
                  conversationId: state.conversationId,
                  otherUserName: state.displayName,
                ),
              ));
              // Setelah navigasi, mungkin ingin BLoC kembali ke state loaded
              // context.read<ConversationsBloc>().add(LoadConversations()); // Atau cara lain
            } else if (state is ConversationsError && state.currentConversations.isEmpty) {
              // Tampilkan error hanya jika tidak ada data lama untuk ditampilkan
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(SnackBar(content: Text(state.message), backgroundColor: Colors.red));
            }
          },
          builder: (context, state) {
            List<ConversationModel> conversations = [];
            bool isLoading = false;

            if (state is ConversationsInitial) {
                isLoading = true;
            } else if (state is ConversationsLoading) {
              isLoading = true;
              conversations = state.currentConversations;
              if (conversations.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }
            } else if (state is ConversationsLoaded) {
              conversations = state.conversations;
            } else if (state is ConversationsError) {
              conversations = state.currentConversations; // Tampilkan data lama jika ada error
               if (conversations.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text("Gagal memuat percakapan: ${state.message}", textAlign: TextAlign.center),
                    ),
                  );
               }
            }


            if (isLoading && conversations.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            if (conversations.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.chat_bubble_outline_rounded, size: 80, color: Colors.grey[400]),
                      const SizedBox(height: 20),
                      const Text(
                        "Belum ada percakapan.",
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Mulai chat baru dengan teman atau buat grup.",
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () async {
                context.read<ConversationsBloc>().add(LoadConversations());
              },
              child: ListView.separated(
                itemCount: conversations.length,
                separatorBuilder: (context, index) => Divider(height: 0.5, indent: 72, endIndent: 16, color: Theme.of(context).dividerColor.withOpacity(0.5)),
                itemBuilder: (context, index) {
                  final convo = conversations[index];
                  String title = "Percakapan";
                  String subtitle = convo.lastMessage?.textContent ?? (convo.lastMessage?.imageUrl != null ? "📷 Foto" : "...");
                  String? avatarUrl;
                  IconData fallbackIcon = Icons.person_outline;

                  if (convo.type == ConversationType.dm && convo.dmParticipant != null) {
                    title = convo.dmParticipant!.username;
                    avatarUrl = convo.dmParticipant!.avatarUrl;
                  } else if (convo.type == ConversationType.group) {
                    title = convo.groupName ?? "Grup Tanpa Nama";
                    avatarUrl = convo.groupAvatarUrl;
                    fallbackIcon = Icons.group_outlined;
                    if (convo.lastMessage?.senderUsername != null && convo.lastMessage?.senderId != currentUserId) {
                        subtitle = "${convo.lastMessage!.senderUsername}: $subtitle";
                    }
                  }


                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    leading: CircleAvatar(
                      radius: 28,
                      backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
                          ? CachedNetworkImageProvider(avatarUrl)
                          : null,
                      child: (avatarUrl == null || avatarUrl.isEmpty)
                          ? Icon(fallbackIcon, size: 26)
                          : null,
                      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                    ),
                    title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16.5)),
                    subtitle: Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          convo.lastMessage != null ? timeago.format(convo.lastMessage!.createdAt.toLocal()) : "",
                          style: TextStyle(fontSize: 12, color: convo.unreadCount > 0 ? Theme.of(context).primaryColor : Colors.grey[500]),
                        ),
                        if (convo.unreadCount > 0) ...[
                          const SizedBox(height: 5),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              convo.unreadCount.toString(),
                              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ]
                      ],
                    ),
                    onTap: () {
                      String displayNameForChat = (convo.type == ConversationType.dm && convo.dmParticipant != null)
                          ? convo.dmParticipant!.username
                          : (convo.groupName ?? "Grup");
                      Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => ChatDetailScreen(
                          conversationId: convo.id,
                          otherUserName: displayNameForChat,
                        ),
                      ));
                    },
                  );
                },
              ),
            );
          },
        ),
        // FAB untuk memulai chat baru bisa ditambahkan di HomeScreen
      ),
    );
  }
}