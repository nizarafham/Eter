import 'dart:io';
import 'package:chat_app/data/datasources/remote/chat_remote_data_source.dart';
import 'package:chat_app/data/models/message_model.dart';
import 'package:chat_app/data/models/conversation_model.dart';
import 'package:chat_app/data/repositories/chat_repository.dart'; // Interface
import 'package:uuid/uuid.dart';

class ChatRepositoryImpl implements ChatRepository {
  final ChatRemoteDataSource _remoteDataSource;
  final Uuid _uuid = const Uuid(); // For generating message IDs client-side if needed

  ChatRepositoryImpl(this._remoteDataSource);

  @override
  Future<String?> createGroupConversation({
    required String groupId,
    required String groupName,
    required List<String> memberIds,
    String? groupAvatarUrl,
    required String createdBy,
  }) async {
    try {
      // ChatRemoteDataSource sekarang perlu metode ini juga
      return await _remoteDataSource.createGroupConversation(
        groupId: groupId,
        groupName: groupName,
        memberIds: memberIds,
        groupAvatarUrl: groupAvatarUrl,
        createdBy: createdBy,
      );
    } catch (e) {
      // print("ChatRepositoryImpl createGroupConversation error: $e");
      rethrow;
    }
  }
  
  @override
  Stream<List<MessageModel>> getMessages(String conversationId) {
    return _remoteDataSource.getMessages(conversationId);
  }

  @override
  Future<void> sendTextMessage(String conversationId, String text, String senderId) async {
    final message = MessageModel(
      id: _uuid.v4(), // Client-generated ID for optimistic updates, or let Supabase handle
      conversationId: conversationId,
      senderId: senderId,
      textContent: text,
      type: MessageType.text,
      createdAt: DateTime.now(), // Client-side timestamp, Supabase can override with server time
    );
    await _remoteDataSource.sendMessage(message);
  }

  @override
  Future<void> sendImageMessage(String conversationId, File imageFile, String senderId) async {
    final imageUrl = await _remoteDataSource.uploadImage(imageFile, conversationId);
    if (imageUrl != null) {
      final message = MessageModel(
        id: _uuid.v4(),
        conversationId: conversationId,
        senderId: senderId,
        imageUrl: imageUrl,
        type: MessageType.image,
        createdAt: DateTime.now(),
      );
      await _remoteDataSource.sendMessage(message);
    } else {
      throw Exception("Image upload failed");
    }
  }

  @override
  Future<void> deleteMessage(String messageId) async {
    await _remoteDataSource.deleteMessage(messageId);
  }

  @override
  Stream<List<ConversationModel>> getConversations(String userId) {
    return _remoteDataSource.getConversations(userId);
  }

  @override
  Future<String?> getOrCreateDmConversation(String userId1, String userId2) async {
    return _remoteDataSource.getOrCreateDmConversation(userId1, userId2);
  }
}