part of 'conversations_bloc.dart';

abstract class ConversationsEvent extends Equatable {
  const ConversationsEvent();

  @override
  List<Object> get props => [];
}

class LoadConversations extends ConversationsEvent {}

class _ConversationsUpdated extends ConversationsEvent {
  final List<ConversationModel> conversations;
  const _ConversationsUpdated(this.conversations);

  @override
  List<Object> get props => [conversations];
}

// Opsional: Event untuk memulai DM baru jika belum ada
class EnsureDmConversation extends ConversationsEvent {
  final String otherUserId;
  const EnsureDmConversation(this.otherUserId);

  @override
  List<Object> get props => [otherUserId];
}