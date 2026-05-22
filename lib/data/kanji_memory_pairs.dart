import 'dart:math';

/// Cặp Kanji — nghĩa Việt (gom từ khóa N5, khớp web `kanjiMemoryFromLessons`).
class KanjiMemoryPair {
  const KanjiMemoryPair({required this.kanji, required this.meaning});

  final String kanji;
  final String meaning;
}

class KanjiMemoryPool {
  KanjiMemoryPool._();

  static const minPairs = 4;
  static const defaultPairTarget = 8;

  static const List<KanjiMemoryPair> all = [
    KanjiMemoryPair(kanji: '人', meaning: 'người'),
    KanjiMemoryPair(kanji: '女', meaning: 'phụ nữ'),
    KanjiMemoryPair(kanji: '男', meaning: 'đàn ông'),
    KanjiMemoryPair(kanji: '子', meaning: 'con, trẻ em'),
    KanjiMemoryPair(kanji: '山', meaning: 'núi'),
    KanjiMemoryPair(kanji: '川', meaning: 'sông'),
    KanjiMemoryPair(kanji: '水', meaning: 'nước'),
    KanjiMemoryPair(kanji: '火', meaning: 'lửa'),
    KanjiMemoryPair(kanji: '木', meaning: 'cây'),
    KanjiMemoryPair(kanji: '金', meaning: 'vàng, kim loại'),
    KanjiMemoryPair(kanji: '土', meaning: 'đất'),
    KanjiMemoryPair(kanji: '日', meaning: 'ngày, mặt trời'),
    KanjiMemoryPair(kanji: '月', meaning: 'tháng, mặt trăng'),
    KanjiMemoryPair(kanji: '年', meaning: 'năm'),
    KanjiMemoryPair(kanji: '時', meaning: 'giờ'),
    KanjiMemoryPair(kanji: '分', meaning: 'phút'),
    KanjiMemoryPair(kanji: '上', meaning: 'trên'),
    KanjiMemoryPair(kanji: '下', meaning: 'dưới'),
    KanjiMemoryPair(kanji: '中', meaning: 'giữa'),
    KanjiMemoryPair(kanji: '大', meaning: 'to, lớn'),
    KanjiMemoryPair(kanji: '小', meaning: 'nhỏ'),
    KanjiMemoryPair(kanji: '本', meaning: 'sách'),
    KanjiMemoryPair(kanji: '学', meaning: 'học'),
    KanjiMemoryPair(kanji: '校', meaning: 'trường'),
    KanjiMemoryPair(kanji: '先', meaning: 'trước'),
    KanjiMemoryPair(kanji: '生', meaning: 'sinh, sống'),
    KanjiMemoryPair(kanji: '友', meaning: 'bạn'),
    KanjiMemoryPair(kanji: '家', meaning: 'nhà'),
    KanjiMemoryPair(kanji: '国', meaning: 'nước'),
    KanjiMemoryPair(kanji: '駅', meaning: 'ga tàu'),
    KanjiMemoryPair(kanji: '車', meaning: 'xe'),
    KanjiMemoryPair(kanji: '電', meaning: 'điện'),
    KanjiMemoryPair(kanji: '話', meaning: 'nói chuyện'),
    KanjiMemoryPair(kanji: '食', meaning: 'ăn'),
    KanjiMemoryPair(kanji: '飲', meaning: 'uống'),
    KanjiMemoryPair(kanji: '買', meaning: 'mua'),
    KanjiMemoryPair(kanji: '店', meaning: 'cửa hàng'),
    KanjiMemoryPair(kanji: '見', meaning: 'nhìn'),
    KanjiMemoryPair(kanji: '行', meaning: 'đi'),
    KanjiMemoryPair(kanji: '来', meaning: 'đến'),
    KanjiMemoryPair(kanji: '新', meaning: 'mới'),
    KanjiMemoryPair(kanji: '古', meaning: 'cũ'),
  ];

  static int get maxSelectablePairs =>
      all.length < minPairs ? minPairs : all.length.clamp(minPairs, defaultPairTarget);

  static List<int> pairCountChoices() {
    final max = maxSelectablePairs;
    return [for (var n = minPairs; n <= max; n++) n];
  }

  static List<KanjiMemoryPair> pickRandom(int pairCount, {Random? rng}) {
    final random = rng ?? Random();
    final n = pairCount.clamp(1, all.length);
    final copy = List<KanjiMemoryPair>.from(all)..shuffle(random);
    return copy.take(n).toList();
  }
}
