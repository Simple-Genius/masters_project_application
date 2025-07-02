import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

class CoreMLChatService {
  static const MethodChannel _channel = MethodChannel('coreml_chat');
  
  bool _isModelLoaded = false;
  
  /// Initialize and load the Core ML model
  Future<bool> loadModel() async {
    try {
      debugPrint('Loading Core ML model...');
      final result = await _channel.invokeMethod('loadModel');
      _isModelLoaded = result == true;
      
      if (_isModelLoaded) {
        debugPrint('Core ML model loaded successfully');
      } else {
        debugPrint('Failed to load Core ML model');
      }
      
      return _isModelLoaded;
    } catch (e) {
      debugPrint('Error loading Core ML model: $e');
      return false;
    }
  }
  
  /// Generate text using the Core ML model
  Future<String> generateText(String prompt, {int maxTokens = 50}) async {
    try {
      debugPrint('Generating text for prompt: $prompt');
      
      final result = await _channel.invokeMethod('generateText', {
        'prompt': prompt,
        'maxTokens': maxTokens,
      });
      
      return result as String? ?? 'Error: No response generated';
      
    } catch (e) {
      debugPrint('Error generating text: $e');
      return 'Error: Failed to generate response - $e';
    }
  }
  
  /// Check if model is loaded
  Future<bool> isModelLoaded() async {
    try {
      final result = await _channel.invokeMethod('isModelLoaded');
      return result == true;
    } catch (e) {
      debugPrint('Error checking model status: $e');
      return false;
    }
  }
  
  bool get isLoaded => _isModelLoaded;
}