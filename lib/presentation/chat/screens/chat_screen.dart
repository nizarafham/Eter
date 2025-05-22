// lib/presentation/chat/pages/chat_screen.dart
import 'dart:io';

import 'package:chat_app/presentation/message_input/blocs/message_input_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart'; // Untuk memilih gambar
import 'package:chat_app/data/models/message_model.dart'; // Pastikan path ini benar
import 'package:chat_app/core/di/service_locator.dart';
import 'package:chat_app/data/repositories/chat_repository.dart'; // Pastikan path ini benar
import 'package:chat_app/presentation/chat/blocs/chat_bloc.dart'; // Pastikan path ini benar
import 'package:chat_app/presentation/chat/widgets/message_bubble.dart'; // Import widget pembantu

class ChatScreen extends StatelessWidget {
  final String conversationId;
  final String otherUserName; // Nama pengguna lawan chat

  // Hapus chatRepository dan currentUserId dari konstruktor ChatScreen
  const ChatScreen({
    super.key,
    required this.conversationId,
    required this.otherUserName,
    // final ChatRepository chatRepository, // TIDAK PERLU LAGI
    // final String currentUserId, // TIDAK PERLU LAGI
  });

  @override
  Widget build(BuildContext context) {
    // Jika Anda perlu currentUserId untuk logika di luar BLoC di layar ini,
    // Anda bisa mendapatkannya dari AuthBloc yang sudah global.
    // final String? currentUserId = context.watch<AuthBloc>().state.user?.id;

    return MultiBlocProvider( // Gunakan MultiBlocProvider jika Anda juga memakai MessageInputCubit di sini
      providers: [
        BlocProvider<ChatBloc>(
          create: (context) => sl<ChatBloc>(param1: conversationId) // <- PERUBAHAN UTAMA DI SINI
            ..add(LoadMessagesEvent()), // Memuat pesan saat bloc dibuat
        ),
        BlocProvider<MessageInputCubit>( // Tambahkan ini jika belum ada dan Anda ingin MessageInputCubit
          create: (context) => sl<MessageInputCubit>(),
        ),
      ],
      child: Scaffold(
        appBar: AppBar(
          title: Text(otherUserName),
        ),
        // Pastikan _ChatBody juga sudah disesuaikan untuk tidak bergantung pada
        // currentUserId yang diteruskan dari ChatScreen, tapi dari AuthBloc atau ChatBloc.
        // Dan pastikan _ChatBody menggunakan MessageInputCubit untuk mengirim pesan.
        body: _ChatBody(conversationId: conversationId), // _ChatBody mungkin perlu conversationId
      ),
    );
  }
}

class _ChatBody extends StatefulWidget {
  final String conversationId; // <<< TAMBAHKAN PARAMETER INI

  const _ChatBody({
    Key? key,
    required this.conversationId, // <<< TAMBAHKAN PARAMETER INI KE KONSTRUKTOR
  }) : super(key: key);

  @override
  State<_ChatBody> createState() => _ChatBodyState();
}

class _ChatBodyState extends State<_ChatBody> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _picker = ImagePicker(); // Untuk mengambil gambar

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.minScrollExtent, // Scroll to top for reversed list (bottom of chat)
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage() {
    if (_messageController.text.trim().isNotEmpty) {
      context.read<ChatBloc>().add(SendTextMessageEvent(_messageController.text.trim()));
      _messageController.clear();
      _scrollToBottom();
    }
  }

  Future<void> _sendImage() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      context.read<ChatBloc>().add(SendImageMessageEvent(File(pickedFile.path)));
      _scrollToBottom();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: BlocConsumer<ChatBloc, ChatState>(
            listener: (context, state) {
              if (state is ChatError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(state.message)),
                );
              } else if (state is ChatMessagesLoaded) {
                _scrollToBottom(); // Scroll to bottom when messages are loaded/updated
              }
            },
            builder: (context, state) {
              if (state is ChatLoading) {
                return const Center(child: CircularProgressIndicator());
              } else if (state is ChatMessagesLoaded) {
                if (state.messages.isEmpty) {
                  return const Center(child: Text("Say hi! No messages yet."));
                }
                return ListView.builder(
                  controller: _scrollController,
                  reverse: true, // Display newest messages at the bottom
                  itemCount: state.messages.length,
                  itemBuilder: (context, index) {
                    final message = state.messages[index];
                    return MessageBubble(
                      message: message,
                      isCurrentUser: message.senderId == context.read<ChatBloc>().currentUserId,
                    );
                  },
                );
              } else if (state is ChatError) {
                return Center(child: Text("Error: ${state.message}"));
              }
              return const SizedBox.shrink(); // Initial state or other unhandled states
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.image),
                onPressed: _sendImage, // Tombol untuk mengirim gambar
              ),
              Expanded(
                child: TextField(
                  controller: _messageController,
                  decoration: InputDecoration(
                    hintText: 'Type a message...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20.0),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surfaceVariant,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  ),
                  onSubmitted: (_) => _sendMessage(), // Kirim saat menekan Enter
                ),
              ),
              const SizedBox(width: 8.0),
              FloatingActionButton(
                onPressed: _sendMessage,
                mini: true,
                child: const Icon(Icons.send),
              ),
            ],
          ),
        ),
      ],
    );
  }
}