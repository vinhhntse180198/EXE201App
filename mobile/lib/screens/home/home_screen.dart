import 'package:flutter/material.dart';

import '../../config/app_flags.dart';
import '../../core/mock/mock_data.dart';
import '../../core/session/app_session.dart';
import '../../data/homepage_content.dart';
import '../../models/progress_summary.dart';
import '../../services/learn_service.dart';
import '../../widgets/common/error_view.dart';
import '../../widgets/common/loading_view.dart';
import '../../widgets/home/home_features_section.dart';
import '../../widgets/home/home_hanami_timeline.dart';
import '../../widgets/home/home_landing_footer.dart';
import '../../widgets/home/home_landing_hero.dart';
import '../../widgets/home/home_testimonials_section.dart';
import '../../widgets/yume/yume_stat_chip.dart';
import '../auth/login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.onOpenTab});

  final void Function(int tabIndex)? onOpenTab;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _learn = LearnService(AppSession.instance.api);

  ProgressSummary? _summary;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Guest mode: không gọi API yêu cầu auth.
    if (!designMode && AppSession.instance.isLoggedIn) _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final s = await _learn.fetchProgressSummary();
      if (mounted) setState(() => _summary = s);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _firstName(String raw) {
    final t = raw.trim();
    if (t.isEmpty) return '';
    return t.split(RegExp(r'\s+')).first;
  }

  void _onFeatureTap(int index) {
    if (index < 0 || index >= HomepageContent.features.length) return;
    widget.onOpenTab?.call(HomepageContent.features[index].tabIndex);
  }

  @override
  Widget build(BuildContext context) {
    final loggedIn = designMode || AppSession.instance.isLoggedIn;

    // Nếu user vừa đăng nhập và quay về Home, đảm bảo tự tải dữ liệu thật.
    if (loggedIn && !designMode && !_loading && _error == null && _summary == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_loading && _summary == null) _load();
      });
    }

    if (!designMode && _loading) {
      return const SizedBox.expand(child: LoadingView(message: 'Đang tải...'));
    }
    if (!designMode && _error != null) {
      return SizedBox.expand(child: ErrorView(message: _error!, onRetry: _load));
    }

    final user = designMode ? MockData.user : AppSession.instance.user?.user;
    final summary = designMode
        ? MockData.progressSummary
        : (_summary ?? const ProgressSummary(exp: 0, xu: 0, streakDays: 0, byLevel: []));

    final name = _firstName(user?.username ?? '');
    final welcome = loggedIn && name.isNotEmpty ? 'Chào $name 👋' : null;

    return SizedBox.expand(
      child: ColoredBox(
        color: Colors.white,
        child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                HomeLandingHero(
                  welcomeLine: welcome,
                  ctaLabel: loggedIn ? HomepageContent.heroCtaMember : HomepageContent.heroCtaGuest,
                  onCta: () {
                    if (loggedIn) {
                      widget.onOpenTab?.call(2);
                    } else {
                      Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const LoginScreen()));
                    }
                  },
                ),
                if (loggedIn)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: Row(
                      children: [
                        Expanded(
                          child: YumeStatChip(icon: Icons.star_rounded, label: 'EXP', value: '${summary.exp}'),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: YumeStatChip(icon: Icons.monetization_on_rounded, label: 'Xu', value: '${summary.xu}'),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: YumeStatChip(
                            icon: Icons.local_fire_department_rounded,
                            label: 'Nỗ lực',
                            value: '${summary.streakDays}',
                          ),
                        ),
                      ],
                    ),
                  ),
                HomeFeaturesSection(onFeatureTap: _onFeatureTap),
                const HomeHanamiTimeline(),
                const HomeTestimonialsSection(),
                const HomeLandingFooter(),
              ],
            ),
          ),
        ),
    );
  }
}
