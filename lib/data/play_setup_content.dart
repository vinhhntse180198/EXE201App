/// Nội dung màn setup trò chơi — khớp web `KanaMatchGame` / `PlayGameSetupPro`.
class PlaySetupContent {
  static const kanaQuestionChoices = [5, 10, 15, 20, 25, 30, 35, 40, 46];
  static const defaultQuestionChoices = [5, 10, 15, 20];

  static String arcadeTitle(String slug, String? metaName) {
    final s = slug.toLowerCase().replaceAll('_', '-');
    const map = {
      'hiragana-match': '🥷 HIRAGANA MATCH',
      'katakana-match': '🥷 KATAKANA MATCH',
    };
    if (map.containsKey(s)) return map[s]!;
    if (metaName != null && metaName.trim().isNotEmpty) return metaName.trim();
    return _prettySlug(s);
  }

  static ({String lead, String accent}) splitTitleAccent(String title) {
    final parts = title.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return (lead: '', accent: 'Game');
    if (parts.length == 1) return (lead: '', accent: parts.first);
    final accent = parts.last;
    final lead = parts.sublist(0, parts.length - 1).join(' ');
    return (lead: lead, accent: accent);
  }

  static bool isKanaSlug(String slug) {
    final s = slug.toLowerCase().replaceAll('_', '-');
    return s == 'hiragana-match' || s == 'katakana-match';
  }

  static String shortIntro(String slug) {
    if (isKanaSlug(slug)) {
      return 'Kiểm tra khả năng phản xạ và ghi nhớ bảng chữ cái Hiragana/Katakana qua thử thách ghép đôi romaji đầy kịch tính.';
    }
    return 'Sẵn sàng cho thử thách — đọc kỹ gợi ý dưới đây trước khi bắt đầu phiên.';
  }

  static List<PlaySetupFeature> featureRows(String slug) {
    if (isKanaSlug(slug)) {
      return const [
        PlaySetupFeature(
          icon: '⏱',
          title: '8 giây mỗi câu',
          description: 'Phải chọn romaji đúng trước khi đồng hồ về 0 — luyện phản xạ đọc bảng chữ.',
        ),
        PlaySetupFeature(
          icon: '★',
          title: 'Tính điểm linh hoạt',
          description: 'Chơi qua API: theo cấu hình server; điểm combat tối đa 100 khi hạ đối thủ.',
        ),
      ];
    }
    return const [
      PlaySetupFeature(
        icon: '🎮',
        title: 'Mẹo',
        description: 'Đọc phần chi tiết phía dưới rồi nhấn Bắt đầu khi đã sẵn sàng.',
      ),
    ];
  }

  static String questionFieldLabel(String slug) {
    if (isKanaSlug(slug)) {
      return 'Số lượng câu hỏi (tối đa 46)';
    }
    return 'Số câu trong phiên';
  }

  static String rulesHint(String slug) {
    if (isKanaSlug(slug)) {
      return '8 giây mỗi câu (Hiragana/Katakana). Điểm combat tối đa 100 khi hạ spirit đối thủ. '
          'Dùng vật phẩm từ túi đồ khi chơi qua API.';
    }
    return 'Lần đầu vào game, server có thể cấp túi đồ mở đầu — dùng thanh power-up khi chơi API.';
  }

  static String _prettySlug(String slug) {
    if (slug.isEmpty) return 'Game';
    return slug
        .split('-')
        .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }
}

class PlaySetupFeature {
  const PlaySetupFeature({
    required this.icon,
    required this.title,
    required this.description,
  });

  final String icon;
  final String title;
  final String description;
}
