import 'dart:async';

import '../core/session/app_session.dart';
import 'social_service.dart';

/// Heartbeat online — khớp web `usePresenceHeartbeat` (45s).
class PresenceService {
  PresenceService._();
  static final PresenceService instance = PresenceService._();

  Timer? _timer;
  final _social = SocialService(AppSession.instance.api);

  void start() {
    stop();
    _ping('online');
    _timer = Timer.periodic(const Duration(seconds: 45), (_) => _ping('online'));
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    _ping('offline');
  }

  Future<void> _ping(String status) async {
    if (!AppSession.instance.isLoggedIn) return;
    try {
      await _social.updatePresence(status: status);
    } catch (_) {}
  }
}
