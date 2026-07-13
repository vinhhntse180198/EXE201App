import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../config/yume_colors.dart';
import '../../config/yume_perf.dart';
import '../../core/session/app_session.dart';
import '../../screens/account/account_screen.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/chat/chat_screen.dart';
import '../../screens/dashboard/dashboard_screen.dart';
import '../../screens/home/home_screen.dart';
import '../../screens/learn/learn_screen.dart';
import '../../screens/play/play_screen.dart';
import '../../screens/upgrade/upgrade_screen.dart';
import '../support_chatbot_sheet.dart';
import '../system_announcement_banner.dart';
import '../../services/presence_service.dart';
import '../learner_placement_guard.dart';
import '../yume/yume_brand_mark.dart';
import '../yume/yume_sakura_background.dart';
import 'yume_bottom_nav.dart';

/// Shell learner — top nav blur + bottom nav giống web LearnerTopNav.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> with LearnerPlacementGuard {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    if (AppSession.instance.isLoggedIn) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        Future<void>.delayed(const Duration(seconds: 2), () {
          if (mounted && AppSession.instance.isLoggedIn) {
            PresenceService.instance.start();
          }
        });
      });
      guardPlacementOnTab();
    }
  }

  @override
  void dispose() {
    PresenceService.instance.stop();
    super.dispose();
  }

  void _switchTab(int i) {
    if (!AppSession.instance.isLoggedIn && i != 0) {
      Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const LoginScreen()));
      return;
    }
    setState(() => _index = i);
    if (AppSession.instance.isLoggedIn) {
      guardPlacementOnTab();
    }
  }

  Widget _buildTabBody(bool loggedIn) {
    if (!loggedIn) {
      if (_index == 0) return HomeScreen(onOpenTab: _switchTab);
      return _guestLockedTab();
    }
    return switch (_index) {
      0 => HomeScreen(onOpenTab: _switchTab),
      1 => const DashboardScreen(),
      2 => const LearnScreen(),
      3 => const ChatScreen(),
      4 => const PlayScreen(),
      _ => const SizedBox.shrink(),
    };
  }

  Future<void> _logout() async {
    await AppSession.instance.auth.logout();
    AppSession.instance.clear();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = AppSession.instance.user?.user;
    final tabLabel = YumeBottomNav.items[_index].label;
    final loggedIn = AppSession.instance.isLoggedIn;

    final body = Column(
      children: [
        _LearnerAppBar(
          user: user,
          tabLabel: tabLabel,
          onSupport: () => SupportChatbotSheet.show(context),
          onAccount: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const AccountScreen()),
          ),
          onUpgrade: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const UpgradeScreen()),
          ),
          onLogout: _logout,
        ),
        const SystemAnnouncementBanner(),
        Expanded(
          child: _buildTabBody(loggedIn),
        ),
      ],
    );

    return Scaffold(
      backgroundColor: const Color(0xFFFFFBFE),
      body: yumeLiteUi ? body : YumeSakuraBackground(child: body),
      bottomNavigationBar: YumeBottomNav(
        currentIndex: loggedIn ? _index : 0,
        onTap: _switchTab,
      ),
    );
  }

  Widget _guestLockedTab() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock_outline, size: 48, color: YumeColors.primary),
            const SizedBox(height: 12),
            const Text('Cần đăng nhập', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
            const SizedBox(height: 8),
            const Text(
              'Bạn đang ở chế độ khách. Hãy đăng nhập để sử dụng tính năng này.',
              textAlign: TextAlign.center,
              style: TextStyle(color: YumeColors.muted),
            ),
            const SizedBox(height: 14),
            FilledButton(
              onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const LoginScreen())),
              child: const Text('Đăng nhập'),
            ),
          ],
        ),
      ),
    );
  }
}

class _LearnerAppBar extends StatelessWidget {
  const _LearnerAppBar({
    required this.user,
    required this.tabLabel,
    required this.onSupport,
    required this.onAccount,
    required this.onUpgrade,
    required this.onLogout,
  });

  final dynamic user;
  final String tabLabel;
  final VoidCallback onSupport;
  final VoidCallback onAccount;
  final VoidCallback onUpgrade;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final bar = Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: yumeLiteUi ? 1 : 0.94),
        border: Border(bottom: BorderSide(color: YumeColors.border.withValues(alpha: 0.35))),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              Image.asset(
                'assets/images/yume-logo.png',
                width: 36,
                height: 36,
                errorBuilder: (_, __, ___) => const YumeBrandMark(size: 36, showTitle: false),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tabLabel,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: YumeColors.ink),
                    ),
                    if (user != null)
                      Text(
                        user.username,
                        style: const TextStyle(fontSize: 11, color: YumeColors.muted),
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.smart_toy_outlined, size: 22),
                tooltip: 'Trợ lý',
                onPressed: onSupport,
              ),
              IconButton(
                icon: const Icon(Icons.person_outline, size: 22),
                onPressed: onAccount,
              ),
              IconButton(
                icon: const Icon(Icons.workspace_premium_outlined, size: 22, color: Color(0xFFF59E0B)),
                onPressed: onUpgrade,
              ),
              IconButton(icon: const Icon(Icons.logout, size: 22), onPressed: onLogout),
            ],
          ),
        ),
      ),
    );

    if (yumeLiteUi) return bar;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: bar,
      ),
    );
  }
}
