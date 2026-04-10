import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health_pilot/models/message.dart';
import 'package:health_pilot/services/chat_service.dart';

// Provider that exposes the ChatService instance
final chatServiceProvider = Provider<ChatService>((ref) {
  return chatService; // Using the exported singleton from chat_service.dart
});

// A family StreamProvider that takes the other user's ID as an argument
// and returns the realtime stream of messages between the current user and them.
final chatMessagesProvider = StreamProvider.family<List<Message>, String>((ref, otherUserId) {
  final service = ref.watch(chatServiceProvider);
  return service.getMessages(otherUserId);
});
