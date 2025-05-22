part of 'chat_bloc.dart'; // Or your chat_bloc file

abstract class ChatState extends Equatable {
  const ChatState();

  @override
  List<Object?> get props => [];
}

class ChatInitial extends ChatState {}

class ChatLoading extends ChatState {
  final List<MessageModel> currentMessages; // To show stale data while loading new
  const ChatLoading({this.currentMessages = const []});

  @override
  List<Object?> get props => [currentMessages];
}

class ChatMessagesLoaded extends ChatState {
  final List<MessageModel> messages;
  const ChatMessagesLoaded(this.messages);

  @override
  List<Object?> get props => [messages];
}

class ChatMessageSending extends ChatState { // Optional: if ChatBloc handles sending state
  final List<MessageModel> currentMessages;
  const ChatMessageSending({required this.currentMessages});
   @override
  List<Object?> get props => [currentMessages];
}

class ChatMessageSent extends ChatState { // Optional
  final List<MessageModel> currentMessages;
  const ChatMessageSent({required this.currentMessages});
   @override
  List<Object?> get props => [currentMessages];
}


class ChatError extends ChatState {
  final String message;
  final List<MessageModel> currentMessages; // Keep data on error if available
  const ChatError(this.message, {this.currentMessages = const []});

  @override
  List<Object?> get props => [message, currentMessages];
}