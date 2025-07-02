import 'package:masters_project_application/models/chat_state.dart';
import 'package:masters_project_application/models/message.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'chat_provider.g.dart';

// Riverpod providers
@riverpod
class ChatNotifier extends _$ChatNotifier {
  @override
  ChatState build() {
    // Initialize with welcome message
    return ChatState(
      messages: [
        Message(
          id: '1',
          text: "Hello! I'm your AI assistant. How can I help you today?",
          isUser: false,
          timestamp: DateTime.now(),
        ),
      ],
    );
  }

  void sendMessage(String text) {
    if (text.trim().isEmpty) return;

    final userMessage = Message(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: text.trim(),
      isUser: true,
      timestamp: DateTime.now(),
    );

    // Add user message and set typing state
    state = state.copyWith(
      messages: [...state.messages, userMessage],
      isTyping: true,
      error: null,
    );

    // Generate bot response
    _generateBotResponse(text);
  }

  void _generateBotResponse(String userMessage) {
    // Simulate API call delay
    Future.delayed(const Duration(milliseconds: 1500), () {
      final botResponse = Message(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: _getSimpleResponse(userMessage.toLowerCase()),
        isUser: false,
        timestamp: DateTime.now(),
      );

      state = state.copyWith(
        messages: [...state.messages, botResponse],
        isTyping: false,
      );
    });
  }

  String _getSimpleResponse(String message) {
    if (message.contains('hello') || message.contains('hi')) {
      return "Hello! Nice to meet you!";
    } else if (message.contains('how are you')) {
      return "I'm doing great, thank you for asking! How are you?";
    } else if (message.contains('help')) {
      return "I'm here to help! You can ask me questions, have a conversation, or just chat.";
    } else if (message.contains('name')) {
      return "I'm a Flutter chatbot built with Riverpod state management!";
    } else if (message.contains('time')) {
      return "The current time is ${DateTime.now().toString().substring(11, 16)}";
    } else if (message.contains('bye') || message.contains('goodbye')) {
      return "Goodbye! It was nice chatting with you!";
    } else {
      final responses = [
        "That's interesting! Tell me more.",
        "I understand. What would you like to know?",
        "Thanks for sharing that with me!",
        "That's a great point. What else is on your mind?",
        "I see. How can I help you with that?",
      ];
      return responses[DateTime.now().millisecond % responses.length];
    }
  }

  void clearMessages() {
    state = const ChatState();
  }

  void setError(String error) {
    state = state.copyWith(error: error, isTyping: false);
  }
}
