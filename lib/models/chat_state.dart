import 'package:masters_project_application/models/message.dart';

class ChatState {
  final List<Message> messages;
  final bool isTyping;
  final String? error;

  const ChatState({
    this.messages = const [],
    this.error,
    this.isTyping = false,
  });

  ChatState copyWith({List<Message>? messages, bool? isTyping, String? error}) {
    return ChatState(
      messages: messages ?? this.messages,
      isTyping: isTyping ?? this.isTyping,
    );
  }
}
