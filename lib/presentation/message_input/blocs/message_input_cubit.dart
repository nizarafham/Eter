import 'dart:io';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:chat_app/data/repositories/chat_repository.dart';
import 'package:chat_app/presentation/auth/blocs/auth_bloc.dart'; // To get current user ID

part 'message_input_state.dart'; // Assuming states are in a separate file or below

class MessageInputCubit extends Cubit<MessageInputState> {
  final ChatRepository _chatRepository;
  final AuthBloc _authBloc; // To get the sender's ID

  MessageInputCubit({
    required ChatRepository chatRepository,
    required AuthBloc authBloc,
  })  : _chatRepository = chatRepository,
        _authBloc = authBloc,
        super(MessageInputInitial());

  String? get _currentUserId => _authBloc.state.user?.id;

  Future<void> sendTextMessage(String conversationId, String text) async {
    if (_currentUserId == null) {
      emit(const MessageSendError("User not authenticated. Cannot send message."));
      return;
    }
    if (text.trim().isEmpty) {
      // Optionally emit a state or just do nothing
      return;
    }

    emit(MessageSending());
    try {
      await _chatRepository.sendTextMessage(conversationId, text.trim(), _currentUserId!);
      emit(MessageSentSuccessfully());
      // Revert to initial to allow new messages
      Future.delayed(const Duration(milliseconds: 100), () => emit(MessageInputInitial()));
    } catch (e) {
      emit(MessageSendError("Failed to send text message: ${e.toString()}"));
    }
  }

  Future<void> sendImageMessage(String conversationId, File imageFile) async {
    if (_currentUserId == null) {
      emit(const MessageSendError("User not authenticated. Cannot send image."));
      return;
    }

    emit(MessageSending());
    try {
      await _chatRepository.sendImageMessage(conversationId, imageFile, _currentUserId!);
      emit(MessageSentSuccessfully());
      // Revert to initial
      Future.delayed(const Duration(milliseconds: 100), () => emit(MessageInputInitial()));
    } catch (e) {
      emit(MessageSendError("Failed to send image message: ${e.toString()}"));
    }
  }
}