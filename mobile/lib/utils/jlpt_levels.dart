import '../models/progress_summary.dart';

/// Mã JLPT từ levelId backend (1=N5 … 5=N1).
String levelCodeFromId(int? levelId) {
  switch (levelId) {
    case 1:
      return 'N5';
    case 2:
      return 'N4';
    case 3:
      return 'N3';
    case 4:
      return 'N2';
    case 5:
      return 'N1';
    default:
      return 'N5';
  }
}

/// Slug phòng chat level trên server (`ChatRoomCatalog`).
String levelChatSlugFromId(int? levelId) {
  switch (levelId) {
    case 1:
      return 'level-n5';
    case 2:
      return 'level-n4';
    case 3:
      return 'level-n3';
    case 4:
      return 'level-n2';
    case 5:
      return 'level-n1';
    default:
      return 'level-n5';
  }
}

/// Level kế tiếp để thi lên (null nếu chưa có level hoặc đã N1).
String? nextLevelCode(int? levelId) {
  if (levelId == null) return null;
  switch (levelId) {
    case 1:
      return 'N4';
    case 2:
      return 'N3';
    case 3:
      return 'N2';
    case 4:
      return 'N1';
    default:
      return null;
  }
}

/// Level kế tiếp chỉ khi đã có bài học publish (tránh gợi ý thi lên N2/N1 trống).
String? nextLevelCodeWithLessons(int? levelId, List<LevelCompletion> byLevel) {
  final next = nextLevelCode(levelId);
  if (next == null) return null;
  final nextId = levelIdFromCode(next);
  if (nextId == null) return null;
  final hasLessons = byLevel.any((l) => l.levelId == nextId && l.totalPublishedLessons > 0);
  return hasLessons ? next : null;
}

/// Map mã JLPT → levelId backend.
int? levelIdFromCode(String? code) {
  switch ((code ?? '').trim().toUpperCase()) {
    case 'N5':
      return 1;
    case 'N4':
      return 2;
    case 'N3':
      return 3;
    case 'N2':
      return 4;
    case 'N1':
      return 5;
    default:
      return null;
  }
}
