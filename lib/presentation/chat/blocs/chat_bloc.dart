import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:chat_app/data/models/message_model.dart';
import 'package:chat_app/data/repositories/chat_repository.dart';
import 'package:chat_app/presentation/auth/blocs/auth_bloc.dart'; // Import AuthBloc
import 'dart:io'; // Untuk SendImageMessageEvent

part 'chat_Event.dart';
part 'chat_state.dart'; // Pastikan chat_state.dart Anda memiliki definisi state yang sesuai

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final ChatRepository _chatRepository;
  final AuthBloc _authBloc; // TAMBAHKAN INI
  final String conversationId;
  // HAPUS currentUserId dari parameter konstruktor jika menggunakan AuthBloc
  // final String currentUserId;

  // Getter untuk currentUserId dari AuthBloc
  String get currentUserId => _authBloc.state.user!.id;

  StreamSubscription? _messagesSubscription;

  ChatBloc({
    required ChatRepository chatRepository,
    required AuthBloc authBloc, // TAMBAHKAN INI
    required this.conversationId,
    // required this.currentUserId, // HAPUS INI
  })  : _chatRepository = chatRepository,
        _authBloc = authBloc, // Inisialisasi
        super(ChatInitial()) { // Atau state awal yang sesuai
    on<LoadMessagesEvent>(_onLoadMessages);
    on<_MessagesUpdatedEvent>(_onMessagesUpdated); // Event internal jika Anda menggunakannya
    on<SendTextMessageEvent>(_onSendTextMessage);
    on<SendImageMessageEvent>(_onSendImageMessage);
    on<DeleteMessageEvent>(_onDeleteMessage);
  }

  void _onLoadMessages(LoadMessagesEvent event, Emitter<ChatState> emit) {
    // Asumsikan ChatLoading state memiliki currentMessages
    List<MessageModel> previousMessages = [];
    if (state is ChatMessagesLoaded) {
        previousMessages = (state as ChatMessagesLoaded).messages;
    } else if (state is ChatLoading) {
        previousMessages = (state as ChatLoading).currentMessages;
    }
    emit(ChatLoading(currentMessages: previousMessages));

    _messagesSubscription?.cancel();
    _messagesSubscription = _chatRepository.getMessages(conversationId).listen(
      (messages) => add(_MessagesUpdatedEvent(messages)),
      onError: (error) => emit(ChatError(
          "Gagal memuat pesan: ${error.toString()}",
          currentMessages: previousMessages
      )),
    );
  }

  void _onMessagesUpdated(_MessagesUpdatedEvent event, Emitter<ChatState> emit) {
    emit(ChatMessagesLoaded(event.messages));
  }

  Future<void> _onSendTextMessage(SendTextMessageEvent event, Emitter<ChatState> emit) async {
    // State saat ini (untuk mempertahankan pesan yang sudah ada saat mengirim)
    // MessageInputCubit yang akan menangani state 'sending' untuk UI input
    try {
      // currentUserId sekarang didapat dari getter
      await _chatRepository.sendTextMessage(conversationId, event.text, currentUserId);
      // Pesan akan terupdate melalui stream _messagesSubscription
    } catch (e) {
      // emit(ChatError("Gagal mengirim pesan: ${e.toString()}", currentMessages: _getCurrentMessagesFromState()));
      // Error pengiriman sebaiknya ditangani oleh MessageInputCubit jika ada
    }
  }

  Future<void> _onSendImageMessage(SendImageMessageEvent event, Emitter<ChatState> emit) async {
    try {
      await _chatRepository.sendImageMessage(conversationId, event.imageFile, currentUserId);
      // Pesan akan terupdate melalui stream
    } catch (e) {
      // emit(ChatError("Gagal mengirim gambar: ${e.toString()}", currentMessages: _getCurrentMessagesFromState()));
    }
  }

  Future<void> _onDeleteMessage(DeleteMessageEvent event, Emitter<ChatState> emit) async {
    try {
      await _chatRepository.deleteMessage(event.messageId);
      // Pesan akan terupdate melalui stream
    } catch (e) {
      // emit(ChatError("Gagal menghapus pesan: ${e.toString()}", currentMessages: _getCurrentMessagesFromState()));
    }
  }

  @override
  Future<void> close() {
    _messagesSubscription?.cancel();
    return super.close();
  }
}