import 'dart:io';
import 'package:chat_app/data/models/message_model.dart';
import 'package:chat_app/data/models/conversation_model.dart';

abstract class ChatRepository {
  Stream<List<MessageModel>> getMessages(String conversationId);
  Future<void> sendTextMessage(String conversationId, String text, String senderId);
  Future<void> sendImageMessage(String conversationId, File imageFile, String senderId);
  Future<void> deleteMessage(String messageId);
  Stream<List<ConversationModel>> getConversations(String userId);
  Future<String?> getOrCreateDmConversation(String userId1, String userId2); // Returns conversationId
  // Add group chat methods if not in GroupRepository
}