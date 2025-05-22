part of 'message_input_cubit.dart';

abstract class MessageInputState extends Equatable {
  const MessageInputState();

  @override
  List<Object> get props => [];
}

class MessageInputInitial extends MessageInputState {}

class MessageSending extends MessageInputState {}

class MessageSentSuccessfully extends MessageInputState {}

class MessageSendError extends MessageInputState {
  final String message;
  const MessageSendError(this.message);

  @override
  List<Object> get props => [message];
}