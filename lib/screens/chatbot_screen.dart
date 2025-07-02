import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:masters_project_application/components/build_typing_indicator.dart';
import 'package:masters_project_application/providers/chat_provider.dart';
import 'package:masters_project_application/components/build_message.dart';

class ChatbotScreen extends ConsumerStatefulWidget {
  const ChatbotScreen({super.key});

  @override
  ConsumerState<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends ConsumerState<ChatbotScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onSubmit(String text) {
    Future.delayed(const Duration(microseconds: 100), () {
      if (text.trim().isEmpty) return;

      _textController.clear();
      ref.read(chatNotifierProvider.notifier).sendMessage(text);
      _scrollToBottom();
    });
  }

  void _scrollToBottom() {
    // The delay is a work around for flutter's widget rendering.
    // It gives the Listview time to rebuild with the new message before scrolling
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatNotifierProvider);

    // wait till everything on the screen is rendered, then scroll to the bottom
    // TODO: Consider handling in provider for best practice of optimization
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('ChatBot'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            onPressed:
                () => ref.read(chatNotifierProvider.notifier).clearMessages(),
            icon: const Icon(Icons.clear_all),
            tooltip: 'Clear Chat',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: EdgeInsets.all(8.0),
              itemCount:
                  chatState.messages.length + (chatState.isTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == chatState.messages.length && chatState.isTyping) {
                  return buildTypingIndicator();
                }
                return buildMessage(chatState.messages[index]);
              },
            ),
          ),
          if (chatState.error != null) buildErrorBar(chatState.error!),
          const Divider(height: 1),
          buildTextComposer(chatState.isTyping),
        ],
      ),
    );
  }

  Widget buildErrorBar(String error) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8.0),
      color: Colors.red[100],
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red[700]),
          const SizedBox(width: 8),
          Expanded(
            child: Text(error, style: TextStyle(color: Colors.red[700])),
          ),
          TextButton(
            onPressed:
                () => ref.read(chatNotifierProvider.notifier).setError(''),
            child: const Text('Dismiss'),
          ),
        ],
      ),
    );
  }

  Widget buildTextComposer(bool isDisabled) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _textController,
                onSubmitted: isDisabled ? null : _onSubmit,
                enabled: !isDisabled,
                decoration: InputDecoration(
                  hintText:
                      isDisabled ? 'Bot is typing...' : 'Type a message...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    //vertical: 8.0,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8.0),
            FloatingActionButton(
              onPressed:
                  isDisabled ? null : () => _onSubmit(_textController.text),
              child: const Icon(Icons.send),
            ),
          ],
        ),
      ),
    );
  }
}
