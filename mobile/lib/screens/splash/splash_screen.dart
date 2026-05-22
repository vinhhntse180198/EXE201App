import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../config/app_flags.dart';
import '../../core/session/app_session.dart';
import '../../models/auth_response.dart';
import '../../services/profile_service.dart';
import '../../utils/post_login_nav.dart';
import '../../widgets/yume/yume_brand_mark.dart';
import '../../widgets/yume/yume_sakura_background.dart';
import '../auth/login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addPostFrameCallback((_) => _go());
  }

  Future<void> _go() async {
    if (_navigated || !mounted) return;

    final restored = await AppSession.instance.auth.restoreSession();
    if (!mounted || _navigated) return;

    _navigated = true;
    Widget next = const LoginScreen();
    if (restored != null) {
      AppSession.instance.applyAuth(restored);
      if (designMode) {
        next = buildPostLoginScreen(restored);
      } else {
        try {
          final profile = await ProfileService(AppSession.instance.api).fetchMyProfile();
          final auth = AuthResponse(
            accessToken: restored.accessToken,
            user: restored.user.copyWith(isPremium: profile.isPremium),
            needsPlacementTest: restored.needsPlacementTest,
          );
          AppSession.instance.applyAuth(auth);
          next = buildPostLoginScreen(auth);
        } catch (_) {
          await AppSession.instance.auth.logout();
          AppSession.instance.clear();
          next = const LoginScreen();
        }
      }
    }

    if (!mounted) return;
    await Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => next),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: YumeSakuraBackground(
        child: Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFFFF1F2), Color(0xFFFFFBFE), Color(0xFFF8FAFC)],
            ),
          ),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              YumeBrandMark(size: 72, title: 'YumeGo-ji'),
              SizedBox(height: 32),
              CircularProgressIndicator(color: Color(0xFFE11D48)),
              SizedBox(height: 16),
              Text('Đang khởi động...', style: TextStyle(color: Color(0xFF64748B))),
            ],
          ),
        ),
      ),
    );
  }
}
