import 'dart:io';
import 'package:chat_app/core/constants/supabase_constants.dart';
import 'package:chat_app/data/models/conversation_model.dart';
import 'package:chat_app/data/models/message_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:rxdart/rxdart.dart';
import 'package:uuid/uuid.dart';

abstract class ChatRemoteDataSource {
  Stream<List<MessageModel>> getMessages(String conversationId);
  Future<void> sendMessage(MessageModel message);
  Future<String?> uploadImage(File imageFile, String conversationId);
  Future<void> deleteMessage(String messageId);
  // Implementation for getConversations
  Stream<List<ConversationModel>> getConversations(String userId);
  // Implementation for getOrCreateDmConversation
  Future<String?> getOrCreateDmConversation(String userId1, String userId2);
  // Add methods for conversations/groups (createGroup, getConversations, etc.)
}

class ChatRemoteDataSourceImpl implements ChatRemoteDataSource {
  final SupabaseClient _supabaseClient;

  ChatRemoteDataSourceImpl(this._supabaseClient);

  @override
  Stream<List<MessageModel>> getMessages(String conversationId) {
    // This needs a more robust way to join sender's profile info
    // For simplicity, fetching raw messages first.
    // Consider a Supabase View or Function for joining profile data.
    return _supabaseClient
        .from(SupabaseConstants.messagesTable)
        .stream(primaryKey: ['id'])
        .eq('conversation_id', conversationId)
        .order('created_at', ascending: true)
        .map((maps) {
      return maps.map((map) {
        // Ideally, join with profiles table here or in a view
        // For now, senderUsername and senderAvatarUrl would be null
        // or you'd make a separate call in the repository/BLoC if not denormalized
        return MessageModel.fromMap(map);
      }).toList();
    });
  }

  @override
  Future<void> sendMessage(MessageModel message) async {
    await _supabaseClient.from(SupabaseConstants.messagesTable).insert(message.toMap());
  }

  @override
  Future<String?> uploadImage(File imageFile, String conversationId) async {
    final userId = _supabaseClient.auth.currentUser!.id;
    final fileName = '${DateTime.now().millisecondsSinceEpoch}_${imageFile.path.split('/').last}';
    final filePath = '$userId/$conversationId/$fileName'; // Organize by user/conversation

    try {
      await _supabaseClient.storage
          .from(SupabaseConstants.imagesBucket)
          .upload(filePath, imageFile);

      final publicUrlResponse = _supabaseClient.storage
          .from(SupabaseConstants.imagesBucket)
          .getPublicUrl(filePath);
      return publicUrlResponse;
    } catch (e) {
      // print('Error uploading image: $e');
      return null;
    }
  }

  @override
  Future<void> deleteMessage(String messageId) async {
    // Ensure RLS allows deleting only own messages
    await _supabaseClient
        .from(SupabaseConstants.messagesTable)
        .delete()
        .eq('id', messageId)
        .eq('sender_id', _supabaseClient.auth.currentUser!.id); // Crucial for security
  }

  @override
  Stream<List<ConversationModel>> getConversations(String userId) {
    // Stream for conversations where userId is user1_id
    final stream1 = _supabaseClient
        .from(SupabaseConstants.conversationsTable)
        .stream(primaryKey: ['id'])
        .eq('user1_id', userId)
        .order('updated_at', ascending: false) // Use 'updated_at' for sorting
        .map((maps) => maps.map((map) => ConversationModel.fromMap(map)).toList());

    // Stream for conversations where userId is user2_id
    final stream2 = _supabaseClient
        .from(SupabaseConstants.conversationsTable)
        .stream(primaryKey: ['id'])
        .eq('user2_id', userId)
        .order('updated_at', ascending: false) // Use 'updated_at' for sorting
        .map((maps) => maps.map((map) => ConversationModel.fromMap(map)).toList());

    // Combine both streams and merge/sort the results
    return Rx.combineLatest2<List<ConversationModel>, List<ConversationModel>, List<ConversationModel>>(
      stream1,
      stream2,
      (list1, list2) {
        final combined = [...list1, ...list2];
        // Sort the combined list by 'updatedAt' in descending order
        combined.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
        return combined;
      },
    );
  }

  @override
  Future<String?> getOrCreateDmConversation(String userId1, String userId2) async {
    // Ensure consistent ordering of user IDs to avoid duplicate conversations
    final sortedUserIds = [userId1, userId2]..sort();
    final String userA = sortedUserIds[0];
    final String userB = sortedUserIds[1];

    // Try to find an existing DM conversation
    final List<Map<String, dynamic>> response = await _supabaseClient
        .from(SupabaseConstants.conversationsTable)
        .select('id')
        .eq('type', 'dm') // Assuming a 'type' column for direct messages
        .eq('user1_id', userA)
        .eq('user2_id', userB)
        .limit(1);

    if (response.isNotEmpty) {
      return response.first['id'] as String;
    } else {
      // Create a new DM conversation if one doesn't exist
      final newConversationId = const Uuid().v4();
      await _supabaseClient
          .from(SupabaseConstants.conversationsTable)
          .insert({
            'id': newConversationId,
            'type': 'dm',
            'user1_id': userA,
            'user2_id': userB,
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(), // Use 'updated_at' here
          });
      return newConversationId;
    }
  }
}