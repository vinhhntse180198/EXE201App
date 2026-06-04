import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../config/app_flags.dart';
import '../../core/session/app_session.dart';
import '../../models/auth_response.dart';
import '../../services/profile_service.dart';
import '../../utils/post_login_nav.dart';
import '../../widgets/yume/yume_sakura_background.dart';
import '../../widgets/navigation/main_shell.dart';

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

    final startedAt = DateTime.now();
    final restored = await AppSession.instance.auth.restoreSession();
    if (!mounted || _navigated) return;

    _navigated = true;
    // Mặc định vào trang chủ (guest mode) như yêu cầu.
    Widget next = const MainShell();
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
          next = const MainShell();
        }
      }
    }

    if (!mounted) return;
    // Giữ splash tối thiểu để thấy logo.
    const minSplashMs = 900;
    final elapsed = DateTime.now().difference(startedAt).inMilliseconds;
    if (elapsed < minSplashMs) {
      await Future<void>.delayed(Duration(milliseconds: minSplashMs - elapsed));
    }
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
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 92,
                height: 92,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFE11D48).withValues(alpha: 0.12),
                      blurRadius: 26,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Image.asset(
                    'assets/images/yume-logo.png',
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Icon(Icons.school_rounded, size: 46, color: Color(0xFFE11D48)),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'YumeGo-Ji',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 26),
              const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.6, color: Color(0xFFE11D48)),
              ),
              const SizedBox(height: 14),
              const Text('Đang khởi động...', style: TextStyle(color: Color(0xFF64748B))),
            ],
          ),
        ),
      ),
    );
  }
}
