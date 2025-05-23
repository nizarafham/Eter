part of 'conversations_bloc.dart';

abstract class ConversationsState extends Equatable {
  const ConversationsState();

  @override
  List<Object?> get props => [];
}

class ConversationsInitial extends ConversationsState {}

class ConversationsLoading extends ConversationsState {
  final List<ConversationModel> currentConversations;
  const ConversationsLoading({this.currentConversations = const []});
    @override
  List<Object?> get props => [currentConversations];
}

class ConversationsLoaded extends ConversationsState {
  final List<ConversationModel> conversations;
  const ConversationsLoaded(this.conversations);

  @override
  List<Object?> get props => [conversations];
}

class ConversationsError extends ConversationsState {
  final String message;
  final List<ConversationModel> currentConversations;
  const ConversationsError(this.message, {this.currentConversations = const []});
    @override
  List<Object?> get props => [message, currentConversations];
}

// Opsional: State untuk menandakan navigasi ke chat detail setelah DM dibuat/dipastikan
class NavigateToChatDetail extends ConversationsState {
  final String conversationId;
  final String displayName; // otherUserName atau groupName

  const NavigateToChatDetail(this.conversationId, this.displayName);

  @override
  List<Object?> get props => [conversationId, displayName];
}