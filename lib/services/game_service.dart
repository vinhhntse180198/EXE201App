import 'package:flutter/foundation.dart';

import '../core/catalog/game_catalog.dart';
import '../models/game_inventory.dart';
import '../models/game_item.dart';
import '../models/game_question.dart';
import '../models/game_play_meta.dart';
import '../models/leaderboard_entry.dart';
import '../models/pvp_room.dart';
import '../utils/json_field.dart';
import 'api_client.dart';

class GameFetchResult {
  const GameFetchResult({required this.games, this.usedCatalogFallback = false});

  final List<GameItem> games;
  final bool usedCatalogFallback;
}

class GameService {
  GameService(this._api);

  final ApiClient _api;

  Future<GameFetchResult> fetchGames() async {
    final data = await _api.get('/api/game');
    final List<dynamic> raw;
    if (data is List) {
      raw = data;
    } else if (data is Map<String, dynamic>) {
      final nested = data['items'] ??
          data['Items'] ??
          data['value'] ??
          data['Value'] ??
          data['data'] ??
          data['Data'];
      raw = nested is List ? nested : [];
    } else {
      if (kDebugMode) {
        debugPrint('Game API: unexpected type ${data.runtimeType}');
      }
      raw = [];
    }

    final parsed = raw
        .whereType<Map<String, dynamic>>()
        .map(GameItem.fromJson)
        .where((g) => g.code.trim().isNotEmpty)
        .toList();

    if (parsed.isNotEmpty) {
      return GameFetchResult(games: parsed);
    }

    if (kDebugMode) {
      debugPrint('Game API: 0 games — dùng catalog mặc định. Chạy scripts/seed_games.sql trên DB.');
    }
    return const GameFetchResult(games: GameCatalog.defaults, usedCatalogFallback: true);
  }

  Future<List<GameAchievement>> fetchAchievements() async {
    final data = await _api.get('/api/game/achievements');
    return parseGameAchievementsList(data);
  }

  Future<List<GameLeaderboardEntry>> fetchLeaderboard({
    String period = 'weekly',
    String sortBy = 'score',
    String? gameSlug,
    int? levelId,
    bool friendsOnly = false,
  }) async {
    final query = <String, String>{
      'period': period,
      'sortBy': sortBy,
      if (gameSlug != null && gameSlug.isNotEmpty) 'gameSlug': gameSlug,
      if (levelId != null) 'levelId': '$levelId',
      if (friendsOnly) 'friendsOnly': 'true',
    };
    final data = await _api.get('/api/game/leaderboard', query: query);
    return _parseGameLeaderboard(data);
  }

  Future<List<ExpLeaderboardEntry>> fetchExpLeaderboard({int limit = 50}) async {
    final data = await _api.get(
      '/api/game/exp-leaderboard',
      query: {'limit': '${limit.clamp(1, 100)}'},
    );
    return _parseExpLeaderboard(data);
  }

  static List<GameLeaderboardEntry> _parseGameLeaderboard(dynamic data) {
    final out = <GameLeaderboardEntry>[];
    for (final row in jsonApiMapList(data)) {
      out.add(GameLeaderboardEntry.fromJson(row));
    }
    return out;
  }

  static List<ExpLeaderboardEntry> _parseExpLeaderboard(dynamic data) {
    final out = <ExpLeaderboardEntry>[];
    for (final row in jsonApiMapList(data)) {
      out.add(ExpLeaderboardEntry.fromJson(row));
    }
    return out;
  }

  Future<GameInventory> fetchInventory() async {
    final data = await _api.get('/api/game/inventory');
    if (data is Map<String, dynamic>) return GameInventory.fromJson(data);
    return const GameInventory(items: []);
  }

  Future<PurchasePowerUpResult> purchasePowerUp({
    required String powerUpSlug,
    int quantity = 1,
  }) async {
    final data = await _api.post(
      '/api/game/inventory/purchase',
      body: {'powerUpSlug': powerUpSlug, 'quantity': quantity},
    );
    return PurchasePowerUpResult.fromJson(data as Map<String, dynamic>);
  }

  Future<UsePowerUpResult> usePowerUp({
    required int sessionId,
    required String powerUpSlug,
    int? questionId,
  }) async {
    final body = <String, dynamic>{
      'sessionId': sessionId,
      'powerUpSlug': powerUpSlug,
    };
    if (questionId != null) body['questionId'] = questionId;
    final data = await _api.post('/api/game/inventory/use', body: body);
    return UsePowerUpResult.fromJson(data as Map<String, dynamic>);
  }

  Future<KanjiMemoryResult> completeKanjiMemory({
    required int totalPairs,
    required int matchedPairs,
  }) async {
    final data = await _api.post(
      '/api/game/kanji-memory/complete',
      body: {'totalPairs': totalPairs, 'matchedPairs': matchedPairs},
    );
    return KanjiMemoryResult.fromJson(data as Map<String, dynamic>);
  }

  Future<List<GameHistoryEntry>> fetchHistory({int page = 1, int pageSize = 20}) async {
    final data = await _api.get(
      '/api/game/history',
      query: {'page': '$page', 'pageSize': '$pageSize'},
    );
    return parseGameHistoryList(data);
  }

  Future<Map<String, dynamic>> createPvpRoom({required String gameSlug, int? levelId}) async {
    final data = await _api.post(
      '/api/game/pvp/create',
      body: {
        'gameSlug': gameSlug,
        if (levelId != null) 'levelId': levelId,
      },
    );
    return data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> joinPvpRoom(String roomCode) async {
    final data = await _api.post('/api/game/pvp/join', body: {'roomCode': roomCode.trim()});
    return data as Map<String, dynamic>;
  }

  Future<PvpRoom> fetchPvpRoom(String roomCode) async {
    final data = await _api.get('/api/game/pvp/${roomCode.trim().toUpperCase()}');
    return PvpRoom.fromJson(data as Map<String, dynamic>);
  }

  Future<DailyChallenge?> fetchDailyChallenge() async {
    final data = await _api.get('/api/game/daily-challenge');
    return parseDailyChallenge(data);
  }

  Future<GameSessionStart> startSession({
    required String gameSlug,
    int questionCount = 10,
    bool useLessonVocabulary = true,
    String mode = 'solo',
  }) async {
    final data = await _api.post(
      '/api/game/session/start',
      body: {
        'gameSlug': gameSlug,
        'setId': null,
        'mode': mode,
        'questionCount': questionCount,
        'useLessonVocabulary': useLessonVocabulary,
      },
    );
    return GameSessionStart.fromJson(data as Map<String, dynamic>);
  }

  Future<Map<String, dynamic>> submitAnswer({
    required int sessionId,
    required int questionId,
    required int questionOrder,
    int? chosenIndex,
    String? powerUpUsed,
  }) async {
    final body = <String, dynamic>{
      'sessionId': sessionId,
      'questionId': questionId,
      'questionOrder': questionOrder,
      if (chosenIndex != null) 'chosenIndex': chosenIndex,
      if (powerUpUsed != null && powerUpUsed.isNotEmpty) 'powerUpUsed': powerUpUsed,
    };
    final data = await _api.post('/api/game/session/answer', body: body);
    return data as Map<String, dynamic>;
  }

  Future<GameSessionSummary> endSession(int sessionId) async {
    final data = await _api.post('/api/game/session/$sessionId/end');
    return GameSessionSummary.fromJson(data as Map<String, dynamic>);
  }
}
