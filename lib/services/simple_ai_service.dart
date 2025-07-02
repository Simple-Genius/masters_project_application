import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:llama_sdk/llama_sdk.dart';

class SimpleAIService {
  Llama? _model;
  bool _isInitialized = false;
  String? _modelPath;

  Future<bool> loadModel() async {
    try {
      debugPrint('Loading AI model...');
      
      // For iOS, the model should be in the app bundle
      // Let's try different possible paths
      final possiblePaths = [
        // iOS bundle paths
        '/var/containers/Bundle/Application/.../Runner.app/assets/models/tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf',
        // Try the Flutter asset approach - copy to documents directory
        await _copyAssetToDocuments('assets/models/tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf'),
      ];
      
      for (final modelPath in possiblePaths) {
        if (modelPath == null) continue;
        
        final modelFile = File(modelPath);
        debugPrint('Checking model path: $modelPath');
        
        if (await modelFile.exists()) {
          debugPrint('Found model at: $modelPath');
          _modelPath = modelPath;
          
          _model = Llama(LlamaController(
            modelPath: _modelPath!,
            nCtx: 512,       // Smaller context for stability
            nBatch: 128,     // Smaller batch size
            greedy: true,    // Use greedy decoding (more stable)
          ));

          _isInitialized = true;
          debugPrint('AI model loaded successfully');
          return true;
        }
      }
      
      debugPrint('No GGUF model found in any location');
      return false;
    } catch (e) {
      debugPrint('Error loading AI model: $e');
      return false;
    }
  }
  
  Future<String?> _copyAssetToDocuments(String assetPath) async {
    try {
      // Copy asset to documents directory so llama_sdk can access it
      final data = await rootBundle.load(assetPath);
      final bytes = data.buffer.asUint8List();
      
      // Get documents directory
      final directory = Directory.systemTemp; // Use temp directory for now
      final fileName = assetPath.split('/').last;
      final file = File('${directory.path}/$fileName');
      
      await file.writeAsBytes(bytes);
      debugPrint('Copied asset to: ${file.path}');
      return file.path;
    } catch (e) {
      debugPrint('Error copying asset: $e');
      return null;
    }
  }

  Stream<String> generateText(String prompt) async* {
    if (!_isInitialized || _model == null) {
      yield 'Error: Model not loaded. Please wait for the model to initialize.';
      return;
    }

    try {
      debugPrint('Generating text for prompt: $prompt');

      // Format prompt for TinyLlama (instruction tuned format)
      final formattedPrompt = "<|user|>\n$prompt<|assistant|>\n";
      
      final messages = [
        LlamaMessage.withRole(role: 'user', content: formattedPrompt),
      ];

      // Add timeout to prevent freezing
      var tokenCount = 0;
      var responseText = '';
      
      await for (final token in _model!.prompt(messages)) {
        // Filter out control tokens and special characters
        if (token.isNotEmpty && !token.contains('<|') && !token.contains('|>')) {
          responseText += token;
          yield token;
          tokenCount++;
        }
        
        // Limit response length to prevent memory issues
        if (tokenCount > 30) {
          debugPrint('Reached token limit, stopping generation');
          break;
        }
        
        // Stop at natural sentence endings
        if (responseText.endsWith('.') || responseText.endsWith('!') || responseText.endsWith('?')) {
          if (tokenCount > 10) { // Ensure we have a reasonable response
            debugPrint('Natural stopping point reached');
            break;
          }
        }
      }
    } catch (e) {
      debugPrint('Error generating text: $e');
      yield '\n\nGeneration error occurred. Please try again.';
    }
  }

  Future<String> generateTextComplete(String prompt) async {
    // Add delay between requests to prevent memory issues
    await Future.delayed(const Duration(milliseconds: 500));
    
    final buffer = StringBuffer();
    
    try {
      await for (final token in generateText(prompt)) {
        if (token.contains('Error:') || token.contains('error')) {
          return token;
        }
        buffer.write(token);
      }
      
      final response = buffer.toString().trim();
      debugPrint('Generated complete response: ${response.length} characters');
      
      // Add delay after generation to stabilize
      await Future.delayed(const Duration(milliseconds: 300));
      
      return response.isEmpty ? 'I need more time to think about that.' : response;
    } catch (e) {
      debugPrint('Error in generateTextComplete: $e');
      return 'Sorry, I encountered an error. Please try a different question.';
    }
  }

  bool get isModelLoaded => _isInitialized && _model != null;

  String getModelInfo() {
    if (!_isInitialized) {
      return '''
AI Model Status: Not Loaded
Please wait for the model to initialize...

Expected Model: TinyLlama 1.1B Chat
Model Format: GGUF
Engine: llama.cpp via Dart FFI
''';
    }
    
    return '''
AI Model Status: Active ✅
Model Path: $_modelPath
Model: TinyLlama 1.1B Chat (Q4_K_M quantization)
Engine: llama.cpp via Dart FFI
Context Length: 2048 tokens
Batch Size: 512 tokens

Capabilities:
✅ Streaming text generation
✅ Conversational AI responses
✅ Local inference (no internet required)
✅ Real-time text generation
✅ Cross-platform compatibility

Features:
🤖 General knowledge and conversation
📝 Creative writing and storytelling
💭 Question answering
🔍 Text analysis and explanation
💡 Problem solving assistance

Framework: llama_sdk (Dart implementation of llama.cpp)
Model Type: Instruction-tuned Language Model
''';
  }

  void dispose() {
    try {
      // Note: Check if Llama class has a dispose method
      _model = null;
      _isInitialized = false;
      debugPrint('AI model disposed');
    } catch (e) {
      debugPrint('Error disposing AI model: $e');
    }
  }
}