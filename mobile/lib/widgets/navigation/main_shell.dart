import 'dart:ui';

import 'package:flutter/material.dart';

import '../../config/yume_colors.dart';
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
    PresenceService.instance.start();
    guardPlacementOnTab();
  }

  @override
  void dispose() {
    PresenceService.instance.stop();
    super.dispose();
  }

  void _switchTab(int i) {
    setState(() => _index = i);
    guardPlacementOnTab();
  }

  late final List<Widget> _pages = [
    HomeScreen(onOpenTab: _switchTab),
    const DashboardScreen(),
    const LearnScreen(),
    const ChatScreen(),
    const PlayScreen(),
  ];

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

    return Scaffold(
      backgroundColor: const Color(0xFFFFFBFE),
      body: YumeSakuraBackground(
        child: Column(
          children: [
            _learnerAppBar(user, tabLabel),
            const SystemAnnouncementBanner(),
            Expanded(child: IndexedStack(index: _index, children: _pages)),
          ],
        ),
      ),
      bottomNavigationBar: YumeBottomNav(currentIndex: _index, onTap: _switchTab),
    );
  }

  Widget _learnerAppBar(dynamic user, String tabLabel) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.94),
            border: Border(bottom: BorderSide(color: YumeColors.border.withValues(alpha: 0.35))),
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Image.asset('assets/images/yume-logo.png', width: 36, height: 36, errorBuilder: (_, __, ___) => const YumeBrandMark(size: 36, showTitle: false)),
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
                    onPressed: () => SupportChatbotSheet.show(context),
                  ),
                  IconButton(
                    icon: const Icon(Icons.person_outline, size: 22),
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(builder: (_) => const AccountScreen()),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.workspace_premium_outlined, size: 22, color: Color(0xFFF59E0B)),
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(builder: (_) => const UpgradeScreen()),
                    ),
                  ),
                  IconButton(icon: const Icon(Icons.logout, size: 22), onPressed: _logout),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
