import '../models/lesson_detail.dart';
import 'html_strip.dart';

final _japanese = RegExp(r'[\u3040-\u309F\u30A0-\u30FF\u4E00-\u9FFF]');
final _vietnamese = RegExp(
  r'[àáạảãâầấậẩẫăằắặẳẵèéẹẻẽêềếệểễìíịỉĩòóọỏõôồốộổỗơờớợởỡùúụủũưừứựửữỳýỵỷỹđÀÁẠẢÃÂẦẤẬẨẪĂẰẮẶẲẴÈÉẸẺẼÊỀẾỆỂỄÌÍỊỈĨÒÓỌỎÕÔỒỐỘỔỖƠỜỚỢỞỠÙÚỤỦŨƯỪỨỰỬỮỲÝỴỶỸĐ]',
);

/// Trích từng đoạn `<p>...</p>` (hoặc khối tương đương) từ HTML bài học.
List<String> extractParagraphsFromHtml(String? html) {
  if (html == null || html.trim().isEmpty) return const [];

  final blocks = <String>[];
  final pRe = RegExp(r'<p[^>]*>(.*?)</p>', caseSensitive: false, dotAll: true);
  for (final m in pRe.allMatches(html)) {
    final text = stripHtml(m.group(1)).trim();
    if (text.isNotEmpty) blocks.add(text);
  }

  if (blocks.isNotEmpty) return blocks;

  final plain = stripHtml(html).trim();
  if (plain.isEmpty) return const [];
  return plain.split(RegExp(r'\n\s*\n')).map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
}

bool hasJapanese(String text) => _japanese.hasMatch(text);

bool _looksMeaningLine(String text) {
  if (_vietnamese.hasMatch(text)) return true;
  final t = text.trim();
  if (t.length < 4) return false;
  // Tiếng Việt không dấu / nhãn tiếng Anh viết hoa (vd: BUỔI SÁNG).
  if (RegExp(r'^[A-ZÀ-Ỹ0-9\s\-\(\)\.,!?～〜・…]+$').hasMatch(t)) return true;
  return RegExp(r'[a-zA-Z]{4,}').hasMatch(t) && !hasJapanese(t);
}

bool isSlideMarkerLine(String text) => text.startsWith('---') && text.contains('Slide');

/// Còn nội dung thực sự sau khi bỏ marker slide import rỗng.
List<String> meaningfulParagraphs(List<String> paragraphs) {
  return paragraphs.where((p) => !isSlideMarkerLine(p)).toList();
}

bool isPlaceholderLessonContent(
  String? html, {
  required int vocabCount,
  required int kanjiCount,
  required int grammarCount,
}) {
  if (vocabCount + kanjiCount + grammarCount > 0) return false;
  return meaningfulParagraphs(extractParagraphsFromHtml(html)).isEmpty;
}

bool _isSlideMarker(String text) => isSlideMarkerLine(text);

/// Parse từ vựng kiểu 3 dòng: JP / đọc / nghĩa (phổ biến trong content HTML import).
List<VocabularyItem> parseVocabularyFromHtml(String? html) {
  final paras = extractParagraphsFromHtml(html);
  if (paras.length < 3) return const [];

  final items = <VocabularyItem>[];
  var i = 0;
  while (i + 2 < paras.length) {
    final jp = paras[i];
    final reading = paras[i + 1];
    final meaning = paras[i + 2];

    if (_isSlideMarker(jp)) {
      i++;
      continue;
    }

    if (hasJapanese(jp) &&
        hasJapanese(reading) &&
        _looksMeaningLine(meaning) &&
        jp.length <= 24 &&
        reading.length <= 32) {
      items.add(
        VocabularyItem(
          id: -(items.length + 1),
          wordJp: jp,
          reading: reading,
          meaningVi: meaning,
        ),
      );
      i += 3;
      continue;
    }
    i++;
  }
  return items;
}

/// Gộp từ vựng API + từ vựng suy ra từ HTML (ưu tiên API).
List<VocabularyItem> effectiveVocabulary(LessonDetail detail) {
  if (detail.vocabulary.isNotEmpty) return detail.vocabulary;
  return parseVocabularyFromHtml(detail.content);
}

/// Các đoạn nội dung còn lại sau khi trừ các dòng đã parse thành từ vựng.
List<String> contentParagraphsExcludingParsedVocab(String? html, List<VocabularyItem> parsed) {
  final all = extractParagraphsFromHtml(html);
  if (parsed.isEmpty) return all;

  final used = <String>{};
  for (final v in parsed) {
    used.add(v.wordJp.trim());
    used.add((v.reading ?? '').trim());
    used.add((v.meaningVi ?? '').trim());
  }

  return all.where((p) {
    if (_isSlideMarker(p)) return true;
    return !used.contains(p);
  }).toList();
}
