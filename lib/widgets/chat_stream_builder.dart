import 'package:flutter/material.dart';
import 'package:health_pilot/models/message.dart';
import 'package:health_pilot/services/chat_service.dart';

class ChatStreamBuilder extends StatefulWidget {
  final ChatService chatService;
  final Widget Function(BuildContext context, List<Message> messages) builder;

  const ChatStreamBuilder({
    super.key,
    required this.chatService,
    required this.builder,
  });

  @override
  State<ChatStreamBuilder> createState() => _ChatStreamBuilderState();
}

class _ChatStreamBuilderState extends State<ChatStreamBuilder> {
  @override
  void dispose() {
    // Clean up the chat service subscription when the widget is destroyed.
    widget.chatService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Message>>(
      stream: widget.chatService.messagesStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          debugPrint('[ChatStreamBuilder] Error: ${snapshot.error}');
          return Center(
            child: Text(
              'Error loading messages',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          );
        }

        final messages = snapshot.data ?? [];
        return widget.builder(context, messages);
      },
    );
  }
}
