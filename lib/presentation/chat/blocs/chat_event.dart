part of 'chat_bloc.dart';

abstract class ChatEvent extends Equatable {
  const ChatEvent();

  @override
  List<Object> get props => [];
}

class LoadMessagesEvent extends ChatEvent {}

class SendTextMessageEvent extends ChatEvent {
  final String text;

  const SendTextMessageEvent(this.text);

  @override
  List<Object> get props => [text];
}

class SendImageMessageEvent extends ChatEvent {
  final File imageFile;

  const SendImageMessageEvent(this.imageFile);

  @override
  List<Object> get props => [imageFile];
}

class DeleteMessageEvent extends ChatEvent {
  final String messageId;

  const DeleteMessageEvent(this.messageId);

  @override
  List<Object> get props => [messageId];
}

class _MessagesUpdatedEvent extends ChatEvent {
  final List<MessageModel> messages;

  const _MessagesUpdatedEvent(this.messages);

  @override
  List<Object> get props => [messages];
}