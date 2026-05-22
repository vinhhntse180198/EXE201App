import '../../models/auth_response.dart';
import '../../models/chat_room.dart';
import '../../models/friend_models.dart';
import '../../models/game_item.dart';
import '../../models/progress_summary.dart';
import '../../models/user.dart';

/// Dữ liệu giả để chỉnh giao diện — không gọi API.
abstract final class MockData {
  static const user = User(
    id: 1,
    username: 'design_user',
    email: 'design@yume.app',
    role: 'Learner',
    levelId: 2,
    exp: 4200,
    xu: 150,
    isPremium: true,
  );

  static AuthResponse get auth => const AuthResponse(
        accessToken: 'design-token',
        user: user,
        needsPlacementTest: false,
      );

  static ProgressSummary get progressSummary => const ProgressSummary(
        exp: 4200,
        xu: 150,
        streakDays: 7,
        byLevel: [
          LevelCompletion(
            levelId: 1,
            levelCode: 'N5',
            levelName: 'JLPT N5',
            totalPublishedLessons: 20,
            completedLessons: 12,
            completionPercent: 60,
          ),
          LevelCompletion(
            levelId: 2,
            levelCode: 'N4',
            levelName: 'JLPT N4',
            totalPublishedLessons: 15,
            completedLessons: 3,
            completionPercent: 20,
          ),
        ],
      );

  static List<GameItem> get games => const [
        GameItem(id: 1, code: 'kana', name: 'Kana Match', description: 'Ghép hiragana/katakana'),
        GameItem(id: 2, code: 'kanji', name: 'Kanji Memory', description: 'Ghi nhớ kanji'),
      ];

  static List<ChatRoom> get chatRooms => const [
        ChatRoom(id: 1, name: 'Nhóm luyện Kanji', roomType: 'group', unreadCount: 1, createdBy: 1),
        ChatRoom(id: 2, name: 'Direct: 28_30', roomType: 'private', unreadCount: 0, peerUserId: 2, peerDisplayName: 'Yume Friend'),
      ];

  static List<FriendUser> get chatFriends => const [
        FriendUser(id: 2, username: 'yume_friend', displayName: 'Yume Friend', isOnline: true),
        FriendUser(id: 3, username: 'sakura_jp', displayName: 'Sakura', isOnline: false),
      ];

  /// Phòng level — mock user levelId=2 → N4.
  static List<ChatRoom> get levelChatRooms => const [
        ChatRoom(
          id: 20,
          name: 'Phòng N4',
          roomType: 'level',
          levelId: 2,
          slug: 'level-n4',
          description: 'Dành cho trình độ N4',
        ),
      ];
}
