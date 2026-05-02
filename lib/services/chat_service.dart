import 'api_service.dart';

class ChatService {
  static Future<List<Map<String, dynamic>>> getConversations() async {
    final response = await ApiService.get('/chat/conversations');
    final List<dynamic> data = response.data['data'] ?? [];
    return data.cast<Map<String, dynamic>>();
  }

  static Future<Map<String, dynamic>> createConversation() async {
    final response = await ApiService.post('/chat/conversations', data: {});
    return response.data['data'] as Map<String, dynamic>;
  }

  static Future<List<Map<String, dynamic>>> getMessages(String conversationId) async {
    final response = await ApiService.get('/chat/conversations/$conversationId/messages');
    final List<dynamic> data = response.data['data'] ?? [];
    return data.cast<Map<String, dynamic>>();
  }

  static Future<Map<String, dynamic>> sendMessage(String conversationId, String content, {String role = 'user'}) async {
    final response = await ApiService.post('/chat/conversations/$conversationId/messages', data: {
      'content': content,
      'role': role,
    });
    return response.data['data'] as Map<String, dynamic>;
  }

  static Future<void> deleteConversation(String conversationId) async {
    await ApiService.delete('/chat/conversations/$conversationId');
  }
}
