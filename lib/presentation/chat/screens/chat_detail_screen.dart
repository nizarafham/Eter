// lib/presentation/chat/screens/chat_detail_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:chat_app/data/models/message_model.dart'; // Ensure this path is correct
import 'package:chat_app/presentation/auth/blocs/auth_bloc.dart';
import 'package:chat_app/presentation/chat/blocs/chat_bloc.dart'; // Ensure this path is correct
import 'package:chat_app/presentation/message_input/blocs/message_input_cubit.dart'; // Ensure this path is correct
import 'package:chat_app/presentation/chat/widgets/message_bubble.dart'; // Ensure this path is correct
import 'package:chat_app/core/di/service_locator.dart';
import 'package:chat_app/core/utils/image_helper.dart'; // Assuming you have this for ImagePicker abstraction

class ChatDetailScreen extends StatelessWidget {
  final String conversationId;
  final String otherUserName; // Name of the other user or group

  const ChatDetailScreen({
    super.key,
    required this.conversationId,
    required this.otherUserName,
  });

  @override
  Widget build(BuildContext context) {
    final currentUserId = context.read<AuthBloc>().state.user?.id;

    if (currentUserId == null) {
      return Scaffold(
        appBar: AppBar(title: Text(otherUserName)),
        body: const Center(child: Text("Error: User not authenticated.")),
      );
    }

    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => sl<ChatBloc>(param1: conversationId) // param1 is conversationId
            ..add(LoadMessagesEvent()),
        ),
        BlocProvider(
          create: (context) => sl<MessageInputCubit>(),
        ),
      ],
      child: Scaffold(
        appBar: AppBar(
          title: Text(otherUserName),
          // elevation: 0.5,
          // centerTitle: true, // Optional
        ),
        body: _ChatDetailBody(conversationId: conversationId),
      ),
    );
  }
}

class _ChatDetailBody extends StatefulWidget {
  final String conversationId;
  const _ChatDetailBody({required this.conversationId});

  @override
  State<_ChatDetailBody> createState() => _ChatDetailBodyState();
}

class _ChatDetailBodyState extends State<_ChatDetailBody> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  // final ImagePicker _picker = ImagePicker(); // Using ImageHelper from DI instead

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
          _scrollController.position.minScrollExtent, // For reversed list
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _handleSendTextMessage() {
    if (_messageController.text.trim().isNotEmpty) {
      context.read<MessageInputCubit>().sendTextMessage(
            widget.conversationId,
            _messageController.text.trim(),
          );
      _messageController.clear();
      // _scrollToBottom(); // ChatBloc listener will handle scroll on new messages
    }
  }

  Future<void> _handleSendImage() async {
    final ImageHelper imageHelper = sl<ImageHelper>(); // Get ImageHelper from DI
    final File? pickedFile = await imageHelper.pickImageFromGallery(); // Or pickImageFromCamera
    if (pickedFile != null) {
      context.read<MessageInputCubit>().sendImageMessage(
            widget.conversationId,
            pickedFile,
          );
      // _scrollToBottom(); // ChatBloc listener will handle scroll
    }
  }

  @override
  Widget build(BuildContext context) {
    final String currentUserId = context.read<AuthBloc>().state.user!.id;

    return Column(
      children: [
        Expanded(
          child: BlocConsumer<ChatBloc, ChatState>(
            listener: (context, chatState) {
              if (chatState is ChatError) {
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(
                    SnackBar(content: Text(chatState.message), backgroundColor: Colors.red),
                  );
              } else if (chatState is ChatMessagesLoaded) {
                // Check if the scroll controller is attached to a scroll view
                // and if the view has dimensions before trying to scroll.
                if (_scrollController.hasClients && _scrollController.position.hasContentDimensions) {
                    _scrollToBottom();
                } else {
                    // If not, schedule it for after the frame renders
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (_scrollController.hasClients && _scrollController.position.hasContentDimensions) {
                            _scrollToBottom();
                        }
                    });
                }
              }
            },
            builder: (context, chatState) {
              List<MessageModel> messagesToDisplay = [];
              bool isLoading = false;

              if (chatState is ChatInitial) {
                // Initial state, usually implies loading will start soon
                return const Center(child: Text("Loading messages..."));
              } else if (chatState is ChatLoading) {
                isLoading = true;
                messagesToDisplay = chatState.currentMessages; // Display stale messages if available
                // If no stale messages, show a full-screen loader
                if (messagesToDisplay.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }
              } else if (chatState is ChatMessagesLoaded) {
                messagesToDisplay = chatState.messages;
              } else if (chatState is ChatMessageSending) { // If ChatBloc manages this
                messagesToDisplay = chatState.currentMessages;
                // You might show a small sending indicator at the bottom or on the last message
              } else if (chatState is ChatMessageSent) { // If ChatBloc manages this
                messagesToDisplay = chatState.currentMessages;
              }
              else if (chatState is ChatError) {
                messagesToDisplay = chatState.currentMessages; // Show stale messages on error
                // If no stale messages, show error message prominently
                if (messagesToDisplay.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        "Could not load messages.\nError: ${chatState.message}",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Theme.of(context).colorScheme.error),
                      ),
                    )
                  );
                }
                // If there are stale messages, the error snackbar from the listener is usually enough,
                // and we can still display the stale messages.
              }

              // Common UI for displaying messages, whether stale or fresh
              if (messagesToDisplay.isEmpty && !isLoading) { // No messages and not actively loading fresh ones
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      "No messages yet. Be the first to say something! 👋",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  )
                );
              }

              return Stack( // Use Stack to overlay a loading indicator if needed
                children: [
                  ListView.builder(
                    controller: _scrollController,
                    reverse: true,
                    padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 8.0),
                    itemCount: messagesToDisplay.length,
                    itemBuilder: (context, index) {
                      final message = messagesToDisplay[index];
                      return MessageBubble(
                        key: ValueKey(message.id),
                        message: message,
                        isCurrentUser: message.senderId == currentUserId,
                      );
                    },
                  ),
                  if (isLoading && messagesToDisplay.isNotEmpty) // Show subtle loader if loading more but have messages
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4.0),
                        color: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.5),
                        child: const Center(child: SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
        BlocConsumer<MessageInputCubit, MessageInputState>(
          listener: (context, inputState) {
            if (inputState is MessageSendError) {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  SnackBar(content: Text(inputState.message), backgroundColor: Colors.red),
                );
            } else if (inputState is MessageSentSuccessfully) {
              _scrollToBottom(); // Scroll when message is confirmed sent by cubit
            }
          },
          builder: (context, inputState) {
            bool isSending = inputState is MessageSending;
            return Padding(
              // Adjust padding for keyboard
              padding: EdgeInsets.fromLTRB(8.0, 8.0, 8.0, MediaQuery.of(context).viewInsets.bottom + 8.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  IconButton(
                    icon: Icon(Icons.add_photo_alternate_outlined, color: Theme.of(context).colorScheme.primary),
                    onPressed: isSending ? null : _handleSendImage,
                    tooltip: "Send Image",
                  ),
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      enabled: !isSending,
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25.0),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Theme.of(context).colorScheme.surfaceContainerHighest, // Updated color
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                      ),
                      onSubmitted: isSending ? null : (_) => _handleSendTextMessage(),
                      textInputAction: TextInputAction.send,
                      minLines: 1,
                      maxLines: 5,
                      textCapitalization: TextCapitalization.sentences,
                    ),
                  ),
                  const SizedBox(width: 8.0),
                  if (isSending)
                    const Padding(
                      padding: EdgeInsets.only(right: 4.0, bottom: 4.0), // Align with FAB visual center
                      child: SizedBox(
                        width: 48, // FAB typically 56, mini 40. IconButton is around 48.
                        height: 48,
                        child: Center(child: CircularProgressIndicator(strokeWidth: 2.5)),
                      ),
                    )
                  else
                    FloatingActionButton(
                      onPressed: _handleSendTextMessage,
                      mini: true,
                      elevation: 2,
                      tooltip: "Send Message",
                      child: const Icon(Icons.send),
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}