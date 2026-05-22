import 'api_client.dart';

class LearnAiMessage {
  const LearnAiMessage({required this.role, required this.content});

  final String role;
  final String content;

  Map<String, dynamic> toJson() => {'role': role, 'content': content};
}

class LearnAiService {
  LearnAiService(this._api);

  final ApiClient _api;

  Future<String> chat({
    required List<LearnAiMessage> messages,
    List<String>? imagesBase64,
  }) async {
    final data = await _api.post(
      '/api/learn/ai/chat',
      body: {
        'messages': messages.map((m) => m.toJson()).toList(),
        if (imagesBase64 != null && imagesBase64.isNotEmpty) 'imagesBase64': imagesBase64,
      },
    );
    if (data is Map<String, dynamic>) {
      return data['message'] as String? ?? data['Message'] as String? ?? '';
    }
    return '';
  }

  Future<ExtractDocumentResult> extractDocument({
    required List<int> bytes,
    required String filename,
  }) async {
    final data = await _api.postMultipart(
      '/api/learn/ai/extract-document',
      fieldName: 'file',
      bytes: bytes,
      filename: filename,
    );
    if (data is! Map<String, dynamic>) {
      return const ExtractDocumentResult(plainText: '');
    }
    return ExtractDocumentResult(
      plainText: data['plainText'] as String? ?? data['PlainText'] as String? ?? '',
      warning: data['warning'] as String? ?? data['Warning'] as String?,
    );
  }
}

class ExtractDocumentResult {
  const ExtractDocumentResult({required this.plainText, this.warning});

  final String plainText;
  final String? warning;
}
