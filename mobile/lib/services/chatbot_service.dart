import 'api_client.dart';

class ChatbotService {
  ChatbotService(this._api);

  final ApiClient _api;

  Future<String> askGuest(String message) async {
    final data = await _api.post('/api/chatbot/guest', body: {'message': message});
    if (data is Map<String, dynamic>) {
      return data['reply'] as String? ??
          data['message'] as String? ??
          data['answer'] as String? ??
          'Không có phản hồi.';
    }
    return data?.toString() ?? '';
  }

  Future<Map<String, dynamic>> createModeratorSupportRoom() async {
    final data = await _api.post('/api/Chat/support/moderator');
    return data as Map<String, dynamic>;
  }
}
