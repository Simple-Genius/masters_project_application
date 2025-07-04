import 'package:flutter/foundation.dart';
import 'package:masters_project_application/models/chat_state.dart';
import 'package:masters_project_application/models/message.dart';
import 'package:masters_project_application/services/ai_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'chat_provider.g.dart';

// Riverpod providers
@riverpod
class ChatNotifier extends _$ChatNotifier {
  final AiService _aiService = AiService();
  bool _isModelLoaded = false;
  bool _isModelLoading = false;

  @override
  ChatState build() {
    // Initialize AI model
    _initializeAI();

    // Initialize with welcome message
    return ChatState(
      messages: [
        Message(
          id: '1',
          text:
              "Hello! I'm your AI assistant. The AI model is loading, please wait a moment...",
          isUser: false,
          timestamp: DateTime.now(),
        ),
      ],
    );
  }

  Future<void> _initializeAI() async {
    if (_isModelLoading) return;

    _isModelLoading = true;

    try {
      debugPrint('Starting AI model initialization...');
      _isModelLoaded = await _aiService.loadModel();
      debugPrint('AI Model loaded: $_isModelLoaded');

      if (_isModelLoaded) {
        // Update welcome message once model is loaded
        final welcomeMessage = Message(
          id: '2',
          text: "Great! I'm ready to help. How can I assist you today?",
          isUser: false,
          timestamp: DateTime.now(),
        );

        state = state.copyWith(messages: [...state.messages, welcomeMessage]);
      } else {
        // Show error message if model failed to load
        final errorMessage = Message(
          id: '2',
          text:
              "Sorry, I couldn't load the AI model. Please restart the app and try again.",
          isUser: false,
          timestamp: DateTime.now(),
        );

        state = state.copyWith(
          messages: [...state.messages, errorMessage],
          error: "Failed to load AI model",
        );
      }
    } catch (e) {
      debugPrint('Error loading AI model: $e');

      final errorMessage = Message(
        id: '2',
        text: "Sorry, there was an error loading the AI model: ${e.toString()}",
        isUser: false,
        timestamp: DateTime.now(),
      );

      state = state.copyWith(
        messages: [...state.messages, errorMessage],
        error: e.toString(),
      );
    } finally {
      _isModelLoading = false;
    }
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

  void _generateBotResponse(String userMessage) async {
    try {
      if (!_isModelLoaded) {
        // Check if model is still loading
        if (_isModelLoading) {
          final waitMessage = Message(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            text:
                "The AI model is still loading. Please wait a moment and try again.",
            isUser: false,
            timestamp: DateTime.now(),
          );

          state = state.copyWith(
            messages: [...state.messages, waitMessage],
            isTyping: false,
          );
          return;
        }

        // Try to load model again if it failed before
        await _initializeAI();

        if (!_isModelLoaded) {
          final errorMessage = Message(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            text:
                "Sorry, the AI model is not available. Please restart the app.",
            isUser: false,
            timestamp: DateTime.now(),
          );

          state = state.copyWith(
            messages: [...state.messages, errorMessage],
            isTyping: false,
          );
          return;
        }
      }

      // Use AI model for response
      debugPrint('Generating AI response for: $userMessage');
      final aiResponse = await _aiService.generateTextComplete(userMessage);
      debugPrint('AI response received: $aiResponse');

      final botResponse = Message(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: aiResponse,
        isUser: false,
        timestamp: DateTime.now(),
      );

      state = state.copyWith(
        messages: [...state.messages, botResponse],
        isTyping: false,
      );
    } catch (e) {
      debugPrint('Error generating bot response: $e');

      final errorResponse = Message(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: "Sorry, I encountered an error. Please try again.",
        isUser: false,
        timestamp: DateTime.now(),
      );

      state = state.copyWith(
        messages: [...state.messages, errorResponse],
        isTyping: false,
        error: e.toString(),
      );
    }
  }

  void clearMessages() {
    // Keep initial welcome message
    state = ChatState(
      messages: [
        Message(
          id: '1',
          text:
              _isModelLoaded
                  ? "Hello! I'm your AI assistant. How can I help you today?"
                  : "Hello! The AI model is loading...",
          isUser: false,
          timestamp: DateTime.now(),
        ),
      ],
    );
  }

  void setError(String error) {
    state = state.copyWith(
      error: error.isEmpty ? null : error,
      isTyping: false,
    );
  }

  void dispose() {
    _aiService.dispose();
  }
}
