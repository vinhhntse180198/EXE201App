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
import '../../widgets/yume/yume_sakura_background.dart';
import '../../widgets/yume/yume_stat_chip.dart';

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
    if (!designMode) _load();
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
    if (!designMode && _loading) {
      return const SizedBox.expand(child: LoadingView(message: 'Đang tải...'));
    }
    if (!designMode && _error != null) {
      return SizedBox.expand(child: ErrorView(message: _error!, onRetry: _load));
    }

    if (!designMode && AppSession.instance.user?.user == null) {
      return const SizedBox.expand(
        child: Center(child: Text('Chưa đăng nhập — thoát app và đăng nhập lại.')),
      );
    }

    final user = designMode ? MockData.user : AppSession.instance.user!.user;
    final summary = designMode
        ? MockData.progressSummary
        : (_summary ?? const ProgressSummary(exp: 0, xu: 0, streakDays: 0, byLevel: []));

    final name = _firstName(user.username);
    final welcome = name.isNotEmpty ? 'Chào $name 👋' : null;

    return SizedBox.expand(
      child: YumeSakuraBackground(
        child: ColoredBox(
          color: Colors.white,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                HomeLandingHero(
                  welcomeLine: welcome,
                  ctaLabel: HomepageContent.heroCtaMember,
                  onCta: () => widget.onOpenTab?.call(2),
                ),
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
                          label: 'Streak',
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
      ),
    );
  }
}
