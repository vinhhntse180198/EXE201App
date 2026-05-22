import '../models/assessment.dart';
import 'api_client.dart';

class AssessmentService {
  AssessmentService(this._api);

  final ApiClient _api;

  Future<PlacementTestDefinition> fetchPlacementTest() async {
    final data = await _api.get('/api/PlacementTest');
    return PlacementTestDefinition.fromJson(data as Map<String, dynamic>);
  }

  Future<PlacementTestResult> submitPlacement(Map<int, String> answers) async {
    final data = await _api.post(
      '/api/PlacementTest/submit',
      body: {
        'answers': answers.entries
            .map((e) => {'questionId': e.key, 'selectedKey': e.value})
            .toList(),
      },
    );
    return PlacementTestResult.fromJson(data as Map<String, dynamic>);
  }

  Future<LevelUpTestDefinition> fetchLevelUpTest(String toLevel) async {
    final data = await _api.get('/api/LevelUpTest', query: {'toLevel': toLevel});
    return LevelUpTestDefinition.fromJson(data as Map<String, dynamic>);
  }

  Future<LevelUpTestResult> submitLevelUp({
    required int testId,
    required Map<int, String> answers,
  }) async {
    final data = await _api.post(
      '/api/LevelUpTest/submit',
      body: {
        'testId': testId,
        'answers': answers.entries
            .map((e) => {'questionId': e.key, 'selectedKey': e.value})
            .toList(),
      },
    );
    return LevelUpTestResult.fromJson(data as Map<String, dynamic>);
  }
}
