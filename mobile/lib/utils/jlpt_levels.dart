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

/// Level kế tiếp để thi lên (null nếu đã N1).
String? nextLevelCode(int? levelId) {
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
      return 'N4';
  }
}
