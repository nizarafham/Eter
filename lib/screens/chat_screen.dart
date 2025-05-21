import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:chat_app/main.dart'; // For supabase client
import 'package:chat_app/models/message.dart';
import 'package:chat_app/screens/auth_screen.dart';
import 'package:chat_app/widgets/message_bubble.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late final Stream<List<Message>> _messagesStream;
  final _messageController = TextEditingController();
  final Map<String, String> _profileCache = {}; // Cache for usernames

  @override
  void initState() {
    super.initState();
    final userId = supabase.auth.currentUser!.id;

    _messagesStream = supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false) // Get newest messages at the top for initial load
        .map((maps) {
            final messages = maps.map((map) => Message.fromMap(map)).toList();
            // For ListView, we want oldest at the top, newest at the bottom
            // So we reverse the list after fetching (or adjust ListView's reverse property)
            return messages.reversed.toList();
        });
    _loadInitialUsernames();
  }

  Future<void> _loadInitialUsernames() async {
    // Pre-load usernames for existing messages if needed, or fetch on demand
    // This is a simplified approach. For many users, consider more optimized fetching.
  }

  Future<String> _fetchUsername(String profileId) async {
    if (_profileCache.containsKey(profileId)) {
      return _profileCache[profileId]!;
    }
    try {
      final data = await supabase
          .from('profiles')
          .select('username')
          .eq('id', profileId)
          .single(); // Use single() if you expect exactly one row
      final username = data['username'] as String? ?? 'Unknown User';
      _profileCache[profileId] = username;
      return username;
    } catch (e) {
      // print('Error fetching username for $profileId: $e');
      _profileCache[profileId] = 'Unknown User'; // Cache error result too
      return 'Unknown User';
    }
  }


  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty) {
      return;
    }
    _messageController.clear();

    final userId = supabase.auth.currentUser!.id;
    try {
      await supabase.from('messages').insert({
        'profile_id': userId,
        'content': content,
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sending message: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = supabase.auth.currentUser!.id;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat Room'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await supabase.auth.signOut();
              if (mounted) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => const AuthScreen()),
                );
              }
            },
          )
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Message>>(
              stream: _messagesStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No messages yet.'));
                }

                final messages = snapshot.data!;

                return ListView.builder(
                  reverse: false, // Keep it false as we reversed the list in the stream map
                  padding: const EdgeInsets.all(8.0),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMe = message.profileId == currentUserId;

                    // Asynchronously fetch username if not "me" and not cached
                    if (!isMe && message.username == null) {
                      return FutureBuilder<String>(
                        future: _fetchUsername(message.profileId),
                        builder: (context, usernameSnapshot) {
                          if (usernameSnapshot.connectionState == ConnectionState.done && usernameSnapshot.hasData) {
                            message.username = usernameSnapshot.data; // Assign to model
                          }
                          // Display bubble even while username is loading or if it fails
                          return MessageBubble(
                            message: message, // message.username will be updated
                            isMe: isMe,
                          );
                        },
                      );
                    } else {
                       if (isMe) message.username = "Me"; // Or fetch your own username if needed elsewhere
                       return MessageBubble(message: message, isMe: isMe);
                    }
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Send a message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10)
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(Icons.send, color: Theme.of(context).primaryColor),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}