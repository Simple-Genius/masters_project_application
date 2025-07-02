import 'package:flutter/widgets.dart';
import 'package:masters_project_application/services/simple_ai_service.dart';

class LlamaCppService {
  // Simple AI service for direct inference
  final SimpleAIService _aiService = SimpleAIService();
  bool _isModelLoaded = false;

  Future<bool> loadModel() async {
    try {
      debugPrint('Initializing AI chatbot...');

      // Load AI model
      _isModelLoaded = await _aiService.loadModel();
      if (_isModelLoaded) {
        debugPrint('AI model loaded successfully');
      } else {
        debugPrint('AI model not available - check model file');
      }

      return _isModelLoaded;
    } catch (e) {
      debugPrint('Error loading AI model: $e');
      return false;
    }
  }

  Future<String> generateText(String prompt) async {
    try {
      debugPrint('Processing query: $prompt');

      // Use AI model if loaded
      if (_isModelLoaded) {
        return await _aiService.generateTextComplete(prompt);
      }

      // Fall back to simple response if model not loaded
      return 'AI model is loading, please wait...';
    } catch (e) {
      debugPrint('Error generating text: $e');
      return 'Error: Unable to generate response - $e';
    }
  }

  bool get isModelLoaded => _isModelLoaded;

  String getModelInfo() {
    return _aiService.getModelInfo();
  }

  void dispose() {
    try {
      _aiService.dispose();
      _isModelLoaded = false;
      debugPrint('AI service disposed');
    } catch (e) {
      debugPrint('Error disposing AI service: $e');
    }
  }
}