import 'dart:async';
import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:chat_app/data/models/message_model.dart';
import 'package:chat_app/data/repositories/chat_repository.dart';

part 'chat_event.dart';
part 'chat_state.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final ChatRepository _chatRepository;
  final String conversationId;
  final String currentUserId; // Needed to know who is sending

  StreamSubscription? _messagesSubscription;

  ChatBloc({
    required ChatRepository chatRepository, // Corrected parameter name
    required this.conversationId,
    required this.currentUserId,
  })  : _chatRepository = chatRepository,
        super(ChatInitial()) {
    on<LoadMessagesEvent>(_onLoadMessages);
    on<SendTextMessageEvent>(_onSendTextMessage);
    on<SendImageMessageEvent>(_onSendImageMessage);
    on<DeleteMessageEvent>(_onDeleteMessage);
    on<_MessagesUpdatedEvent>(_onMessagesUpdated);
  }

  void _onLoadMessages(LoadMessagesEvent event, Emitter<ChatState> emit) {
    emit(ChatLoading());
    _messagesSubscription?.cancel(); // Cancel previous subscription if any
    _messagesSubscription = _chatRepository.getMessages(conversationId).listen(
      (messages) => add(_MessagesUpdatedEvent(messages)), // Add internal event on update
      onError: (error) => emit(ChatError("Failed to load messages: $error")),
    );
  }

  void _onMessagesUpdated(_MessagesUpdatedEvent event, Emitter<ChatState> emit) {
    // Only emit ChatMessagesLoaded if the state isn't already ChatMessagesLoaded
    // with the same messages to avoid unnecessary rebuilds.
    if (state is ChatMessagesLoaded && (state as ChatMessagesLoaded).messages == event.messages) {
      return;
    }
    emit(ChatMessagesLoaded(event.messages));
  }

  Future<void> _onSendTextMessage(SendTextMessageEvent event, Emitter<ChatState> emit) async {
    // Optional: emit(ChatMessageSending()); if you want explicit UI for sending
    try {
      await _chatRepository.sendTextMessage(conversationId, event.text, currentUserId);
      // The stream subscription will pick up the new message and emit _MessagesUpdatedEvent
      // leading to ChatMessagesLoaded, so explicit ChatMessageSent is often not needed.
    } catch (e) {
      // Revert to previous state or just emit error
      emit(ChatError("Failed to send message: ${e.toString()}"));
    }
  }

  Future<void> _onSendImageMessage(SendImageMessageEvent event, Emitter<ChatState> emit) async {
    // Optional: emit(ChatMessageSending());
    try {
      await _chatRepository.sendImageMessage(conversationId, event.imageFile, currentUserId);
    } catch (e) {
      emit(ChatError("Failed to send image: ${e.toString()}"));
    }
  }

  Future<void> _onDeleteMessage(DeleteMessageEvent event, Emitter<ChatState> emit) async {
    try {
      await _chatRepository.deleteMessage(event.messageId);
      // The stream will update, so the UI will reflect the deletion automatically.
      // If you need immediate optimistic update, you could modify the current list
      // in ChatMessagesLoaded state and emit a new state, then revert if deletion fails.
      // For now, relying on the stream for eventual consistency.
    } catch (e) {
      emit(ChatError("Failed to delete message: ${e.toString()}"));
    }
  }

  @override
  Future<void> close() {
    _messagesSubscription?.cancel(); // Cancel the stream subscription when the BLoC is closed
    return super.close();
  }
}