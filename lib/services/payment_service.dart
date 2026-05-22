import '../models/premium_models.dart';
import 'api_client.dart';

class PaymentService {
  PaymentService(this._api);

  final ApiClient _api;

  Future<PremiumConfig> getPremiumConfig() async {
    final data = await _api.get('/api/Payment/premium/config');
    return PremiumConfig.fromJson(data as Map<String, dynamic>);
  }

  Future<PremiumIntent> createPremiumIntent() async {
    final data = await _api.post('/api/Payment/premium/intent', body: {});
    return PremiumIntent.fromJson(data as Map<String, dynamic>);
  }

  Future<PremiumIntent> confirmPremiumPayment(String token) async {
    final data = await _api.post(
      '/api/Payment/premium/confirm',
      body: {'token': token},
    );
    return PremiumIntent.fromJson(data as Map<String, dynamic>);
  }

  Future<PremiumIntent?> getMyLatestPremiumIntent() async {
    try {
      final data = await _api.get('/api/Payment/premium/me/latest');
      if (data == null) return null;
      return PremiumIntent.fromJson(data as Map<String, dynamic>);
    } on ApiException catch (e) {
      if (e.statusCode == 204) return null;
      rethrow;
    }
  }
}
