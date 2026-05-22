import '../../models/game_item.dart';

/// Danh mục game mặc định — dùng khi API trả về rỗng (slug khớp DB YumegojiDB hiện tại).
abstract final class GameCatalog {
  static const List<GameItem> defaults = [
    GameItem(id: 10, code: 'hiragana-match', name: 'Hiragana Match', description: 'Nhận diện và ghép Hiragana', skillType: 'hiragana'),
    GameItem(id: 12, code: 'katakana-match', name: 'Katakana Match', description: 'Nhận diện và ghép Katakana', skillType: 'katakana'),
    GameItem(id: 11, code: 'kanji-memory', name: 'Kanji Memory', description: 'Lật bài ghi nhớ Kanji', skillType: 'kanji'),
    GameItem(id: 14, code: 'vocabulary-speed-quiz', name: 'Vocabulary Speed Quiz', description: 'Đố từ vựng tốc độ', skillType: 'vocabulary'),
    GameItem(id: 13, code: 'sentence-builder', name: 'Sentence Builder', description: 'Sắp xếp câu', skillType: 'grammar'),
    GameItem(id: 7, code: 'counter-quest', name: 'Counter Quest', description: 'Trợ từ đếm', skillType: 'counter'),
    GameItem(id: 9, code: 'flashcard-battle', name: 'Flashcard Battle', description: 'Đấu flashcard PvP', skillType: 'vocabulary', isPvp: true),
    GameItem(id: 6, code: 'boss-battle', name: 'Boss Battle', description: 'Boss theo chủ đề', skillType: 'mixed'),
    GameItem(id: 1, code: 'flashcard-vocabulary', name: 'Flashcard Battle', description: 'Đấu với Bot AI', skillType: 'vocabulary'),
    GameItem(id: 2, code: 'multiple-choice', name: 'Chọn đáp án đúng', description: 'Trắc nghiệm', skillType: 'mixed'),
  ];
}
