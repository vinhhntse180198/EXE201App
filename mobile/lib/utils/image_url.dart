import '../config/api_config.dart';

/// Ghép URL ảnh tĩnh từ backend (vd. `/uploads/...`).
String buildImageUrl(String? path) {
  if (path == null || path.isEmpty) return '';
  if (path.startsWith('http://') || path.startsWith('https://')) return path;
  final base = apiBaseUrl.replaceAll(RegExp(r'/$'), '');
  final normalized = path.startsWith('/') ? path : '/$path';
  return '$base$normalized';
}
