import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'isUser': isUser,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      text: json['text'],
      isUser: json['isUser'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}

class Conversation {
  final String id;
  final DateTime startedAt;
  DateTime lastActivityAt;
  final List<ChatMessage> messages;

  Conversation({
    required this.id,
    required this.startedAt,
    required this.lastActivityAt,
    required this.messages,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'startedAt': startedAt.toIso8601String(),
      'lastActivityAt': lastActivityAt.toIso8601String(),
      'messages': messages.map((m) => m.toJson()).toList(),
    };
  }

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: json['id'],
      startedAt: DateTime.parse(json['startedAt']),
      lastActivityAt: DateTime.parse(json['lastActivityAt']),
      messages: (json['messages'] as List)
          .map((m) => ChatMessage.fromJson(m))
          .toList(),
    );
  }

  String get lastMessageText {
    if (messages.isEmpty) return '';
    final lastMessage = messages.last;
    return lastMessage.text;
  }

  String get formattedTimestamp {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final conversationDate = DateTime(
      lastActivityAt.year,
      lastActivityAt.month,
      lastActivityAt.day,
    );

    String dayText;
    if (conversationDate == today) {
      dayText = 'Hari ini';
    } else if (conversationDate == yesterday) {
      dayText = 'Kemarin';
    } else {
      final daysDiff = today.difference(conversationDate).inDays;
      if (daysDiff < 7) {
        dayText = '$daysDiff hari lalu';
      } else {
        dayText =
            '${lastActivityAt.day}/${lastActivityAt.month}/${lastActivityAt.year}';
      }
    }

    final hour = lastActivityAt.hour.toString().padLeft(2, '0');
    final minute = lastActivityAt.minute.toString().padLeft(2, '0');
    return '$dayText, $hour:$minute';
  }
}

class ChatStorageService {
  static const String _conversationsKey = 'chat_conversations';
  static const String _currentConversationKey = 'chat_current_conversation';
  static const String _lastActivityKey = 'chat_last_activity';
  static const Duration idleTimeout = Duration(minutes: 5);

  static final ChatStorageService _instance = ChatStorageService._internal();
  factory ChatStorageService() => _instance;
  ChatStorageService._internal();

  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Save current conversation
  Future<void> saveCurrentConversation(List<ChatMessage> messages) async {
    if (_prefs == null) await init();

    if (messages.isEmpty) {
      await _prefs!.remove(_currentConversationKey);
      await _prefs!.remove(_lastActivityKey);
      return;
    }

    final conversationData = {
      'messages': messages.map((m) => m.toJson()).toList(),
      'lastActivity': DateTime.now().toIso8601String(),
    };

    await _prefs!.setString(
      _currentConversationKey,
      jsonEncode(conversationData),
    );
    await _prefs!.setString(_lastActivityKey, DateTime.now().toIso8601String());
  }

  // Load current conversation
  Future<List<ChatMessage>?> loadCurrentConversation() async {
    if (_prefs == null) await init();

    final data = _prefs!.getString(_currentConversationKey);
    if (data == null) return null;

    try {
      final conversationData = jsonDecode(data) as Map<String, dynamic>;
      final messages = (conversationData['messages'] as List)
          .map((m) => ChatMessage.fromJson(m))
          .toList();
      return messages;
    } catch (e) {
      return null;
    }
  }

  // Check if conversation should be ended (idle timeout)
  Future<bool> shouldEndConversation() async {
    if (_prefs == null) await init();

    final lastActivityStr = _prefs!.getString(_lastActivityKey);
    if (lastActivityStr == null) return true;

    try {
      final lastActivity = DateTime.parse(lastActivityStr);
      final now = DateTime.now();
      final difference = now.difference(lastActivity);
      return difference > idleTimeout;
    } catch (e) {
      return true;
    }
  }

  // End current conversation and save to history
  Future<void> endCurrentConversation() async {
    if (_prefs == null) await init();

    final messages = await loadCurrentConversation();
    if (messages == null || messages.isEmpty) return;

    final conversation = Conversation(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      startedAt: messages.first.timestamp,
      lastActivityAt: DateTime.now(),
      messages: messages,
    );

    final conversations = await getAllConversations();
    conversations.add(conversation);

    // Sort by last activity (newest first)
    conversations.sort((a, b) => b.lastActivityAt.compareTo(a.lastActivityAt));

    await _saveConversations(conversations);
    await _prefs!.remove(_currentConversationKey);
    await _prefs!.remove(_lastActivityKey);
  }

  // Get all conversations
  Future<List<Conversation>> getAllConversations() async {
    if (_prefs == null) await init();

    final data = _prefs!.getString(_conversationsKey);
    if (data == null) return [];

    try {
      final conversationsData = jsonDecode(data) as List;
      return conversationsData.map((c) => Conversation.fromJson(c)).toList();
    } catch (e) {
      return [];
    }
  }

  // Delete a specific conversation
  Future<void> deleteConversation(String id) async {
    if (_prefs == null) await init();

    final conversations = await getAllConversations();
    conversations.removeWhere((c) => c.id == id);
    await _saveConversations(conversations);
  }

  // Delete all conversations
  Future<void> clearAllConversations() async {
    if (_prefs == null) await init();

    await _prefs!.remove(_conversationsKey);
    await _prefs!.remove(_currentConversationKey);
    await _prefs!.remove(_lastActivityKey);
  }

  // Update last activity timestamp
  Future<void> updateLastActivity() async {
    if (_prefs == null) await init();
    await _prefs!.setString(_lastActivityKey, DateTime.now().toIso8601String());
  }

  Future<void> _saveConversations(List<Conversation> conversations) async {
    if (_prefs == null) await init();

    final data = jsonEncode(conversations.map((c) => c.toJson()).toList());
    await _prefs!.setString(_conversationsKey, data);
  }
}
