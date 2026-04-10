import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:health_pilot/core/supabase_client.dart';
import 'package:health_pilot/models/message.dart';

class ChatService {
  ChatService._internal();
  static final ChatService _instance = ChatService._internal();

  /// Singleton instance
  factory ChatService() => _instance;

  /// Returns a realtime stream of messages between the current user and the specified other user.
  /// Also silently updates unread messages to 'read' because this is opened when the view opens.
  Stream<List<Message>> getMessages(String otherUserId) {
    final currentUser = supabase.auth.currentUser;
    if (currentUser == null) return const Stream.empty();

    // Fire off an update to mark unread messages from this sender to us as read
    _markMessagesAsRead(otherUserId);

    return supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: true)
        .map((data) {
      return data.where((m) =>
          (m['sender_id'] == currentUser.id && m['receiver_id'] == otherUserId) ||
          (m['sender_id'] == otherUserId && m['receiver_id'] == currentUser.id)
      ).map((e) => Message.fromJson(e)).toList();
    });
  }

  /// Sends a message and persists it to the Supabase database.
  Future<void> sendMessage(String content, String receiverId) async {
    final senderId = supabase.auth.currentUser?.id;
    if (senderId == null) throw Exception('Not logged in');
    
    await supabase.from('messages').insert({
      'sender_id': senderId,
      'receiver_id': receiverId,
      'content': content,
    });
  }

  Future<void> _markMessagesAsRead(String otherUserId) async {
    final currentUser = supabase.auth.currentUser;
    if (currentUser == null) return;

    try {
      await supabase
          .from('messages')
          .update({'is_read': true})
          .eq('sender_id', otherUserId)
          .eq('receiver_id', currentUser.id)
          .eq('is_read', false);
    } catch (_) {
      // Background operation; fail silently.
    }
  }

  Future<void> dispose() async {
    // Left for compatibility if needed.
  }
}

final chatService = ChatService();
