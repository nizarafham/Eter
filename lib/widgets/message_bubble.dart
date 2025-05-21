import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:chat_app/models/message.dart';
import 'package:chat_app/main.dart'; 

class MessageBubble extends StatelessWidget {
  final Message message;
  final bool isMe;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(12),
            topRight: const Radius.circular(12),
            bottomLeft: isMe ? const Radius.circular(12) : Radius.zero,
            bottomRight: isMe ? Radius.zero : const Radius.circular(12),
          ),
        ),
        color: isMe ? Theme.of(context).primaryColor.withAlpha(200) : Colors.grey[700],
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!isMe && message.username != null)
                Text(
                  message.username!,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.lightBlueAccent[100],
                  ),
                ),
              if (!isMe && message.username != null) const SizedBox(height: 4),
              Text(
                message.content,
                style: TextStyle(color: isMe ? Colors.white : Colors.white70),
              ),
              const SizedBox(height: 4),
              Text(
                DateFormat('hh:mm a').format(message.createdAt.toLocal()), // Format time
                style: TextStyle(
                  fontSize: 10,
                  color: isMe ? Colors.white70 : Colors.white54,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}