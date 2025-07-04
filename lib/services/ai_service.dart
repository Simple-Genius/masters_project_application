import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:llama_sdk/llama_sdk.dart';

class AiService {
  bool _isInitialized = false;
  String? _modelPath;
  static int _conversationCount = 0;

  Future<bool> loadModel() async {
    try {
      debugPrint('Loading Llama 3.2 model...');

      _modelPath = await _copyAssetToDocuments(
        'assets/models/Llama-3.2-3B-Instruct-IQ3_M.gguf',
      );

      if (_modelPath == null) {
        debugPrint('Failed to copy model to documents');
        return false;
      }

      final modelFile = File(_modelPath!);
      if (!await modelFile.exists()) {
        debugPrint('Model file not found at: $_modelPath');
        return false;
      }

      debugPrint('Model path ready: $_modelPath');
      _isInitialized = true;
      debugPrint('Llama 3.2 model path prepared successfully');
      return true;
    } catch (e) {
      debugPrint('Error loading Llama 3.2 model: $e');
      return false;
    }
  }

  Future<String?> _copyAssetToDocuments(String assetPath) async {
    try {
      final data = await rootBundle.load(assetPath);
      final bytes = data.buffer.asUint8List();

      final directory = Directory.systemTemp;
      final fileName = assetPath.split('/').last;
      final file = File('${directory.path}/$fileName');

      await file.writeAsBytes(bytes);
      debugPrint('Copied model to: ${file.path}');
      return file.path;
    } catch (e) {
      debugPrint('Error copying model asset: $e');
      return null;
    }
  }

  Future<String> generateTextComplete(String prompt) async {
    if (!_isInitialized || _modelPath == null) {
      return 'Error: Model not loaded. Please wait for initialization.';
    }

    _conversationCount++;
    debugPrint('=== Starting conversation #$_conversationCount ===');

    try {
      // Create a fresh model instance for each request
      debugPrint('Creating new model instance...');
      final model = Llama(
        LlamaController(
          modelPath: _modelPath!,
          nCtx: 512, // Even smaller context
          nBatch: 128, // Smaller batch
          nThreads: 1, // Single thread for stability
          temperature: 0.7,
          topP: 0.9,
          topK: 40,
          penaltiesRepeat: 1.1,
          seed:
              DateTime.now().millisecondsSinceEpoch, // Different seed each time
        ),
      );

      debugPrint('Model instance created');

      final messages = [LlamaMessage.withRole(role: 'user', content: prompt)];

      final buffer = StringBuffer();
      var tokenCount = 0;
      const maxTokens = 80; // Strict limit

      debugPrint('Starting generation...');

      await for (final token in model.prompt(messages)) {
        // Skip empty tokens
        if (token.isEmpty || token.trim().isEmpty) {
          continue;
        }

        // Skip end markers
        if (token.contains('<|') || token.contains('|>')) {
          debugPrint('Found end marker, stopping');
          break;
        }

        buffer.write(token);
        tokenCount++;

        if (tokenCount % 10 == 0) {
          debugPrint('Generated $tokenCount tokens...');
        }

        // Hard stop at max tokens
        if (tokenCount >= maxTokens) {
          debugPrint('Reached max tokens limit');
          break;
        }

        // Natural stopping point
        final current = buffer.toString();
        if (tokenCount > 20 &&
            (current.endsWith('.') ||
                current.endsWith('!') ||
                current.endsWith('?'))) {
          debugPrint('Found natural stopping point');
          break;
        }
      }

      final response = buffer.toString().trim();
      debugPrint('Generation complete: $tokenCount tokens');
      debugPrint('Response: $response');

      // No need to explicitly dispose - let garbage collection handle it

      return response.isEmpty
          ? 'I need more time to think about that.'
          : response;
    } catch (e, stackTrace) {
      debugPrint('Error in text generation: $e');
      debugPrint('Stack trace: $stackTrace');
      return 'Sorry, I encountered an error. Please try again.';
    }
  }

  bool get isModelLoaded => _isInitialized && _modelPath != null;

  void dispose() {
    try {
      _isInitialized = false;
      _modelPath = null;
      debugPrint('AI service disposed');
    } catch (e) {
      debugPrint('Error disposing AI service: $e');
    }
  }
}
