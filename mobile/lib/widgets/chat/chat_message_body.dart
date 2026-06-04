import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../config/yume_colors.dart';
import '../../utils/image_url.dart';

/// Nội dung tin chat — text hoặc ảnh (data URI / URL / uploads).
class ChatMessageBody extends StatelessWidget {
  const ChatMessageBody({
    super.key,
    required this.content,
    this.messageType,
    this.maxImageHeight = 220,
  });

  final String content;
  final String? messageType;
  final double maxImageHeight;

  static Uint8List? decodeDataUriImage(String raw) {
    final trimmed = raw.trim();
    final match = RegExp(r'^data:image/[^;]+;base64,(.+)$', dotAll: true).firstMatch(trimmed);
    if (match == null) return null;
    try {
      return base64Decode(match.group(1)!.replaceAll(RegExp(r'\s'), ''));
    } catch (_) {
      return null;
    }
  }

  static String? resolveImageUrl(String raw, {String? messageType}) {
    final t = raw.trim();
    if (t.isEmpty || t.startsWith('data:image/')) return null;

    if (t.startsWith('http://') || t.startsWith('https://')) {
      return _looksLikeImageRef(t) ? t : null;
    }

    if (t.startsWith('/uploads/') || _looksLikeImageRef(t)) {
      final url = buildImageUrl(t);
      return url.isEmpty ? null : url;
    }

    final type = (messageType ?? '').toLowerCase();
    if (type == 'image' && t.isNotEmpty) {
      final path = t.startsWith('/') ? t : '/$t';
      final url = buildImageUrl(path);
      return url.isEmpty ? null : url;
    }

    return null;
  }

  static bool _looksLikeImageRef(String value) {
    return RegExp(r'\.(png|jpe?g|gif|webp)(\?|$)', caseSensitive: false).hasMatch(value) ||
        value.startsWith('/uploads/');
  }

  static bool _looksLikeRawBase64(String value) {
    if (value.length < 120) return false;
    final sample = value.length > 400 ? value.substring(0, 400) : value;
    return RegExp(r'^[A-Za-z0-9+/=\s]+$').hasMatch(sample);
  }

  @override
  Widget build(BuildContext context) {
    final body = content.trim();
    if (body.isEmpty) {
      return const Text('—', style: TextStyle(color: YumeColors.muted));
    }

    final bytes = decodeDataUriImage(body);
    if (bytes != null) {
      return _MemoryImagePreview(bytes: bytes, maxHeight: maxImageHeight);
    }

    final url = resolveImageUrl(body, messageType: messageType);
    if (url != null) {
      return _NetworkImagePreview(url: url, maxHeight: maxImageHeight);
    }

    if (body.startsWith('data:image/')) {
      return const Text('[Không đọc được ảnh]', style: TextStyle(color: YumeColors.muted, fontSize: 12));
    }

    if (_looksLikeRawBase64(body)) {
      return const Row(
        children: [
          Icon(Icons.image_outlined, size: 18, color: YumeColors.muted),
          SizedBox(width: 6),
          Text('Ảnh đính kèm', style: TextStyle(color: YumeColors.muted, fontStyle: FontStyle.italic)),
        ],
      );
    }

    return Text(body, style: const TextStyle(height: 1.35));
  }
}

class _MemoryImagePreview extends StatelessWidget {
  const _MemoryImagePreview({required this.bytes, required this.maxHeight});

  final Uint8List bytes;
  final double maxHeight;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight, maxWidth: double.infinity),
        child: Image.memory(
          bytes,
          fit: BoxFit.contain,
          gaplessPlayback: true,
          errorBuilder: (_, __, ___) => const Text('[Ảnh lỗi]', style: TextStyle(color: YumeColors.muted, fontSize: 12)),
        ),
      ),
    );
  }
}

class _NetworkImagePreview extends StatelessWidget {
  const _NetworkImagePreview({required this.url, required this.maxHeight});

  final String url;
  final double maxHeight;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight, maxWidth: double.infinity),
        child: Image.network(
          url,
          fit: BoxFit.contain,
          gaplessPlayback: true,
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return SizedBox(
              height: 80,
              child: Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    value: progress.expectedTotalBytes != null
                        ? progress.cumulativeBytesLoaded / progress.expectedTotalBytes!
                        : null,
                  ),
                ),
              ),
            );
          },
          errorBuilder: (_, __, ___) => const Text('[Không tải được ảnh]', style: TextStyle(color: YumeColors.muted, fontSize: 12)),
        ),
      ),
    );
  }
}
