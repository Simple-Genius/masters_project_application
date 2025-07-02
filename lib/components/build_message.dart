import 'package:flutter/material.dart';
import 'package:masters_project_application/models/message.dart';

Widget buildMessage(Message message) {
  return Container(
    margin: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      mainAxisAlignment:
          message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: [
        if (!message.isUser) ...[
          CircleAvatar(
            backgroundColor: Colors.blue,
            child: const Icon(Icons.smart_toy, color: Colors.white),
          ),
          const SizedBox(width: 8.0),
        ],
        Flexible(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
            decoration: BoxDecoration(
              color: message.isUser ? Colors.blue : Colors.grey[300],
              borderRadius: BorderRadius.circular(18.0),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message.text,
                  style: TextStyle(
                    color: message.isUser ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 4.0),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "${message.timestamp.hour.toString().padLeft(2, '0')}:${message.timestamp.minute.toString().padLeft(2, '0')}",
                      style: TextStyle(
                        fontSize: 12.0,
                        color:
                            message.isUser ? Colors.white70 : Colors.grey[600],
                      ),
                    ),
                    if (message.isUser) ...[
                      const SizedBox(width: 4.0),
                      Icon(
                        message.status == MessageStatus.sent
                            ? Icons.done
                            : message.status == MessageStatus.error
                            ? Icons.error_outline
                            : Icons.access_time,
                        size: 12.0,
                        color: Colors.white70,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
        if (message.isUser) ...[
          const SizedBox(width: 8.0),
          CircleAvatar(
            backgroundColor: Colors.green,
            child: const Icon(Icons.person, color: Colors.white),
          ),
        ],
      ],
    ),
  );
}
