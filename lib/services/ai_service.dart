import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:llama_sdk/llama_sdk.dart';

class AiService {
  bool _isInitialized = false;
  String? _modelPath;

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

  Future<void> talkAsync({
    required String prompt,
    required Function(String) onTokenGenerated,
  }) async {
    if (!_isInitialized || _modelPath == null) {
      onTokenGenerated(
        'Error: Model not loaded. Please wait for initialization.',
      );
      return;
    }

    try {
      debugPrint('Starting AI conversation for: $prompt');

      final receivePort = ReceivePort();

      // Start isolate for text generation
      await Isolate.spawn(
        _aiIsolateEntryPoint,
        _IsolateData(
          modelPath: _modelPath!,
          prompt: prompt,
          sendPort: receivePort.sendPort,
        ),
      );

      await for (final message in receivePort) {
        if (message is String) {
          if (message == '_DONE_') {
            receivePort.close();
            break;
          } else if (message.startsWith('_ERROR_')) {
            onTokenGenerated('Error: ${message.substring(7)}');
            receivePort.close();
            break;
          } else {
            onTokenGenerated(message);
          }
        }
      }

      debugPrint('AI conversation completed');
    } catch (e) {
      debugPrint('Error in AI conversation: $e');
      onTokenGenerated('Sorry, I encountered an error. Please try again.');
    }
  }

  static void _aiIsolateEntryPoint(_IsolateData data) async {
    try {
      // Create model instance with improved parameters
      final model = Llama(
        LlamaController(
          modelPath: data.modelPath,
          nCtx: 2048, // Increased context size for Llama 3.2
          nBatch: 512, // Increased batch size
          nThreads: 4, // Add thread count
          temperature: 0.8, // Slightly higher temperature
          topP: 0.95, // Slightly higher topP
          topK: 40, // Add topK parameter
          penaltiesRepeat: 1.1, // Add repeat penalty to avoid repetition
          seed: -1, // Random seed
        ),
      );

      // Format the prompt properly for Llama 3.2 Instruct
      final formattedPrompt =
          '''<|begin_of_text|><|start_header_id|>system<|end_header_id|>

You are a helpful AI assistant. Keep your responses concise and friendly.<|eot_id|><|start_header_id|>user<|end_header_id|>

${data.prompt}<|eot_id|><|start_header_id|>assistant<|end_header_id|>

''';

      final messages = [
        LlamaMessage.withRole(
          role: 'system',
          content:
              'You are a helpful AI assistant. Keep your responses concise and friendly.',
        ),
        LlamaMessage.withRole(role: 'user', content: data.prompt),
      ];

      var tokenCount = 0;
      var fullResponse = '';
      var buffer = '';

      // Track end-of-text markers
      const endMarkers = ['<|eot_id|>', '<|end_of_text|>', '</s>'];

      await for (final token in model.prompt(messages)) {
        // Check for end markers
        buffer += token;

        // Check if we've hit an end marker
        bool shouldStop = false;
        for (final marker in endMarkers) {
          if (buffer.contains(marker)) {
            // Remove the marker from the output
            fullResponse = fullResponse.replaceAll(marker, '');
            shouldStop = true;
            break;
          }
        }

        if (shouldStop) {
          break;
        }

        // Skip empty tokens
        if (token.isEmpty || token == ' ' && fullResponse.isEmpty) {
          continue;
        }

        fullResponse += token;
        data.sendPort.send(token);
        tokenCount++;

        // More generous token limit
        if (tokenCount > 256) {
          break;
        }

        // Natural stopping points after sufficient content
        if (tokenCount > 30) {
          final trimmed = fullResponse.trim();
          if (trimmed.endsWith('.') ||
              trimmed.endsWith('!') ||
              trimmed.endsWith('?') ||
              trimmed.endsWith(':')) {
            // Check if next few tokens would start a new sentence
            await Future.delayed(Duration(milliseconds: 50));
            break;
          }
        }
      }

      // Clean up the response
      fullResponse = fullResponse.trim();

      data.sendPort.send('_DONE_');
    } catch (e) {
      debugPrint('Error in isolate: $e');
      data.sendPort.send('_ERROR_$e');
    }
  }

  Future<String> generateTextComplete(String prompt) async {
    final completer = Completer<String>();
    final buffer = StringBuffer();

    // Add timeout to prevent hanging
    final timer = Timer(Duration(seconds: 30), () {
      if (!completer.isCompleted) {
        completer.complete(
          'Sorry, the response took too long. Please try again.',
        );
      }
    });

    await talkAsync(
      prompt: prompt,
      onTokenGenerated: (token) {
        if (token.startsWith('Error:')) {
          timer.cancel();
          if (!completer.isCompleted) {
            completer.complete(token);
          }
        } else {
          buffer.write(token);
        }
      },
    );

    timer.cancel();

    if (!completer.isCompleted) {
      final response = buffer.toString().trim();
      completer.complete(
        response.isEmpty ? 'I need more time to think about that.' : response,
      );
    }

    return completer.future;
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

class _IsolateData {
  final String modelPath;
  final String prompt;
  final SendPort sendPort;

  _IsolateData({
    required this.modelPath,
    required this.prompt,
    required this.sendPort,
  });
}
