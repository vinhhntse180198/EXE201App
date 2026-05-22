import '../utils/json_field.dart';

class SystemAnnouncement {
  const SystemAnnouncement({
    required this.title,
    required this.body,
    this.publishedAt,
  });

  final String title;
  final String body;
  final DateTime? publishedAt;

  factory SystemAnnouncement.fromJson(Map<String, dynamic> json) {
    final at = jsonStr(json, 'publishedAt') ?? jsonStr(json, 'createdAt');
    return SystemAnnouncement(
      title: jsonStr(json, 'title') ?? '',
      body: jsonStr(json, 'body') ?? jsonStr(json, 'message') ?? '',
      publishedAt: at != null ? DateTime.tryParse(at) : null,
    );
  }
}
