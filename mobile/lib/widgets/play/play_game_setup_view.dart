import 'package:flutter/material.dart';

import '../../data/play_setup_content.dart';
import '../yume/yume_sakura_background.dart';

/// Màn setup trước khi chơi — scroll mượt, nút Bắt đầu cố định, không overflow.
class PlayGameSetupView extends StatelessWidget {
  const PlayGameSetupView({
    super.key,
    required this.slug,
    required this.gameName,
    required this.questionCount,
    required this.questionChoices,
    required this.onQuestionCountChanged,
    required this.onBack,
    required this.onStart,
    this.loading = false,
    this.error,
    this.onSwitchKana,
    this.activeKanaSlug,
    this.onOpenShop,
  });

  final String slug;
  final String gameName;
  final int questionCount;
  final List<int> questionChoices;
  final ValueChanged<int> onQuestionCountChanged;
  final VoidCallback onBack;
  final VoidCallback onStart;
  final bool loading;
  final String? error;
  final void Function(String slug)? onSwitchKana;
  final String? activeKanaSlug;
  final VoidCallback? onOpenShop;

  static const _accentRose = Color(0xFFBE123C);
  static const _gradientStart = Color(0xFFBE123C);
  static const _gradientEnd = Color(0xFFE11D48);

  @override
  Widget build(BuildContext context) {
    final title = PlaySetupContent.arcadeTitle(slug, gameName);
    final parts = PlaySetupContent.splitTitleAccent(title);
    final kana = PlaySetupContent.isKanaSlug(slug);
    final intro = PlaySetupContent.shortIntro(slug);
    final features = PlaySetupContent.featureRows(slug);
    final qLabel = PlaySetupContent.questionFieldLabel(slug);
    final rules = PlaySetupContent.rulesHint(slug);
    final active = activeKanaSlug ?? slug;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return YumeSakuraBackground(
      child: Stack(
        fit: StackFit.expand,
        children: [
          const _SetupZenWash(),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: TextButton(
                                onPressed: loading ? null : onBack,
                                style: TextButton.styleFrom(
                                  alignment: Alignment.centerLeft,
                                  padding: const EdgeInsets.only(left: 0, bottom: 4),
                                  foregroundColor: const Color(0xFF9F1239),
                                ),
                                child: const Text(
                                  '← Trò chơi',
                                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                                ),
                              ),
                            ),
                            if (onOpenShop != null)
                              IconButton(
                                icon: const Icon(Icons.storefront_outlined, size: 22),
                                tooltip: 'Cửa hàng',
                                onPressed: loading ? null : onOpenShop,
                              ),
                          ],
                        ),
                        RichText(
                          text: TextSpan(
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF0F172A),
                              height: 1.15,
                              letterSpacing: -0.3,
                            ),
                            children: [
                              if (parts.lead.isNotEmpty)
                                TextSpan(
                                  text: '${parts.lead} ',
                                  style: const TextStyle(fontWeight: FontWeight.w800),
                                ),
                              TextSpan(text: parts.accent, style: const TextStyle(color: _accentRose)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        _InfoCard(intro: intro, features: features),
                        const SizedBox(height: 12),
                        _ConfigCard(
                          qLabel: qLabel,
                          questionCount: questionCount,
                          choices: questionChoices,
                          onChanged: onQuestionCountChanged,
                          kana: kana,
                          activeSlug: active,
                          onSwitchKana: onSwitchKana,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          rules,
                          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.5),
                        ),
                        if (error != null) ...[
                          const SizedBox(height: 10),
                          Text(error!, style: const TextStyle(color: Color(0xFFDC2626), fontSize: 13)),
                        ],
                        const SizedBox(height: 16),
                        const _InspirationBanner(),
                        SizedBox(height: 12 + bottomInset),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(16, 8, 16, 8 + bottomInset),
                  child: _StartButton(loading: loading, onStart: onStart),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StartButton extends StatelessWidget {
  const _StartButton({required this.loading, required this.onStart});

  final bool loading;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [PlayGameSetupView._gradientStart, PlayGameSetupView._gradientEnd],
        ),
        boxShadow: [
          BoxShadow(
            color: PlayGameSetupView._accentRose.withValues(alpha: 0.28),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: loading ? null : onStart,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: loading
                ? const Center(
                    child: SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    ),
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Bắt đầu',
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900),
                      ),
                      SizedBox(width: 6),
                      Text('▶', style: TextStyle(color: Colors.white, fontSize: 14)),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class _SetupZenWash extends StatelessWidget {
  const _SetupZenWash();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFFFFFAFB),
              const Color(0xFFFDF4F6).withValues(alpha: 0.97),
              const Color(0xFFFAF5F7),
            ],
          ),
        ),
        child: Stack(
          children: [
            Positioned(top: -40, left: -20, child: _blob(const Color(0xFFFECDD3), 0.45, 280)),
            Positioned(top: 60, right: -30, child: _blob(const Color(0xFFFCE7F3), 0.5, 220)),
          ],
        ),
      ),
    );
  }

  Widget _blob(Color color, double alpha, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color.withValues(alpha: alpha)),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.intro, required this.features});

  final String intro;
  final List<PlaySetupFeature> features;

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(intro, style: const TextStyle(fontSize: 14, color: Color(0xFF475569), height: 1.55)),
          const SizedBox(height: 14),
          ...features.map(
            (f) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFECDD3).withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFBE123C).withValues(alpha: 0.12)),
                    ),
                    child: Text(f.icon, style: const TextStyle(fontSize: 18)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          f.title,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          f.description,
                          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.45),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConfigCard extends StatelessWidget {
  const _ConfigCard({
    required this.qLabel,
    required this.questionCount,
    required this.choices,
    required this.onChanged,
    required this.kana,
    required this.activeSlug,
    this.onSwitchKana,
  });

  final String qLabel;
  final int questionCount;
  final List<int> choices;
  final ValueChanged<int> onChanged;
  final bool kana;
  final String activeSlug;
  final void Function(String slug)? onSwitchKana;

  @override
  Widget build(BuildContext context) {
    final selected = choices.contains(questionCount) ? questionCount : choices.first;

    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text('⚙', style: TextStyle(fontSize: 16)),
              SizedBox(width: 6),
              Text(
                'Cấu hình lượt chơi',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(qLabel, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF64748B))),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: choices.map((n) {
              return _OptionChip(
                label: '$n câu',
                active: n == selected,
                onTap: () => onChanged(n),
              );
            }).toList(),
          ),
          if (kana && onSwitchKana != null) ...[
            const SizedBox(height: 16),
            const Text(
              'Chế độ bảng chữ',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _KanaModeChip(
                    label: 'Hiragana',
                    active: activeSlug == 'hiragana-match',
                    onTap: () => onSwitchKana!('hiragana-match'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _KanaModeChip(
                    label: 'Katakana',
                    active: activeSlug == 'katakana-match',
                    onTap: () => onSwitchKana!('katakana-match'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _OptionChip extends StatelessWidget {
  const _OptionChip({required this.label, required this.active, required this.onTap});

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            gradient: active
                ? const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFBE123C), Color(0xFFE11D48)],
                  )
                : null,
            color: active ? null : Colors.white,
            border: active ? null : Border.all(color: const Color(0xFF0F172A).withValues(alpha: 0.1)),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: const Color(0xFFBE123C).withValues(alpha: 0.22),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: active ? Colors.white : const Color(0xFF334155),
            ),
          ),
        ),
      ),
    );
  }
}

class _KanaModeChip extends StatelessWidget {
  const _KanaModeChip({required this.label, required this.active, required this.onTap});

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            gradient: active
                ? const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFBE123C), Color(0xFFE11D48)],
                  )
                : null,
            color: active ? null : Colors.white,
            border: active ? null : Border.all(color: const Color(0xFF0F172A).withValues(alpha: 0.1)),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: const Color(0xFFBE123C).withValues(alpha: 0.28),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          padding: const EdgeInsets.symmetric(vertical: 11),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: active ? Colors.white : const Color(0xFF334155),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GlassCard extends StatelessWidget {
  const _GlassCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF0F172A).withValues(alpha: 0.05)),
      ),
      child: child,
    );
  }
}

class _InspirationBanner extends StatelessWidget {
  const _InspirationBanner();

  static const _zenUrl =
      'https://lh3.googleusercontent.com/aida-public/AB6AXuC3Ju_oFqE7vhueOnoRV2DE6LQMag2sV-_Pn70RrjHxzfqLZgiPul68BJwpAM7qxlxXi4SXV1HBlI0Vr6-OPFAtipgQIO3HCinqZb5P6E3UHWO_V66iLThyOsOHqIXqziVtM4EbDLxlhXKebsUpuKgS3xOTTk3qLLCn_6GXqpsL0cNG3ENY7b86u2QdDjOjmkoVn05I3Y6anpBFu2FYgkm-YBOvmE3aX8VQ6lJiDZfrXIXoCxOtEogai-h9CZROLNDLdeu4QnSTgHo';

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final h = (constraints.maxWidth * 0.52).clamp(140.0, 200.0);
        return ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: SizedBox(
            height: h,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: Color.lerp(const Color(0xFFF8FAFC), const Color(0xFFFCE7F3), 0.5),
                  ),
                ),
                Image.network(
                  _zenUrl,
                  fit: BoxFit.cover,
                  alignment: Alignment.center,
                  filterQuality: FilterQuality.high,
                  errorBuilder: (context, error, stack) => Image.asset(
                    'assets/images/hero-japan.png',
                    fit: BoxFit.cover,
                  ),
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.08),
                        Colors.black.withValues(alpha: 0.35),
                      ],
                    ),
                  ),
                ),
                const Align(
                  alignment: Alignment.bottomLeft,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(14, 0, 14, 14),
                    child: Text(
                      'Cảm hứng học tập từ thiên nhiên',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        height: 1.25,
                        shadows: [Shadow(color: Color(0x66000000), blurRadius: 6)],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
