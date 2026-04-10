import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:health_pilot/core/supabase_client.dart';
import 'package:health_pilot/models/message.dart';

class ChatService {
  ChatService._internal();
  static final ChatService _instance = ChatService._internal();

  /// Singleton instance
  factory ChatService() => _instance;

  StreamController<List<Message>>? _messagesController;
  RealtimeChannel? _subscription;
  List<Message> _cache = [];

  /// Returns the actively managed message stream. 
  /// Throws if `initializeConversation` hasn't been called.
  Stream<List<Message>> get messagesStream {
    if (_messagesController == null) {
      throw Exception('ChatService stream accessed before initialization.');
    }
    return _messagesController!.stream;
  }

  /// Initializes the stream, fetches the initial conversation, and subscribes to realtime inserts.
  void initializeConversation(String receiverId) async {
    final senderId = supabase.auth.currentUser?.id;
    if (senderId == null) {
      debugPrint('[ChatService] Error: User not logged in');
      return;
    }

    _cache = [];
    _messagesController = StreamController<List<Message>>.broadcast();

    // 1. Initial fetch of the active conversation
    try {
      final response = await supabase
          .from('messages')
          .select()
          .or('and(sender_id.eq.$senderId,receiver_id.eq.$receiverId),and(sender_id.eq.$receiverId,receiver_id.eq.$senderId)')
          .order('created_at', ascending: true);
          
      _cache = (response as List<dynamic>).map((e) => Message.fromJson(e)).toList();
      _messagesController?.add(_cache.toList());
    } catch (e) {
      _messagesController?.addError(e);
      debugPrint('[ChatService] Fetch error: $e');
    }

    // Unsubscribe previous if any
    await _subscription?.unsubscribe();

    // 2. Subscribe to Supabase Realtime for inserts
    _subscription = supabase
        .channel('public:messages:$receiverId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'messages',
          // Note: Realtime channel filters don't support complex OR conditions natively,
          // so we filter on the client side to ensure it's the active conversation.
          callback: (payload) {
            final newMsg = Message.fromJson(payload.newRecord);
            if ((newMsg.senderId == senderId && newMsg.receiverId == receiverId) ||
                (newMsg.senderId == receiverId && newMsg.receiverId == senderId)) {
              _cache.add(newMsg);
              _messagesController?.add(_cache.toList());
            }
          },
        )
        .subscribe();
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

  /// Disposes the current channel subscription and stream controller.
  Future<void> dispose() async {
    if (_subscription != null) {
      await _subscription!.unsubscribe();
      _subscription = null;
    }
    if (_messagesController != null) {
      await _messagesController!.close();
      _messagesController = null;
    }
    _cache = [];
  }
}
