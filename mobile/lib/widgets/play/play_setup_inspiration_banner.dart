import 'package:flutter/material.dart';

/// Banner “Cảm hứng học tập” — dùng chung setup Hiragana / Kanji Memory (khớp web).
class PlaySetupInspirationBanner extends StatelessWidget {
  const PlaySetupInspirationBanner({
    super.key,
    this.assetPath = 'assets/images/play/kanji-memory-stones.png',
    this.caption = 'Cảm hứng học tập từ thiên nhiên',
  });

  final String assetPath;
  final String caption;

  static const _zenUrl =
      'https://lh3.googleusercontent.com/aida-public/AB6AXuC3Ju_oFqE7vhueOnoRV2DE6LQMag2sV-_Pn70RrjHxzfqLZgiPul68BJwpAM7qxlxXi4SXV1HBlI0Vr6-OPFAtipgQIO3HCinqZb5P6E3UHWO_V66iLThyOsOHqIXqziVtM4EbDLxlhXKebsUpuKgS3xOTTk3qLLCn_6GXqpsL0cNG3ENY7b86u2QdDjOjmkoVn05I3Y6anpBFu2FYgkm-YBOvmE3aX8VQ6lJiDZfrXIXoCxOtEogai-h9CZROLNDLdeu4QnSTgHo';

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final h = (constraints.maxWidth * 0.48).clamp(120.0, 168.0);
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
                Image.asset(
                  assetPath,
                  fit: BoxFit.cover,
                  alignment: Alignment.center,
                  errorBuilder: (_, __, ___) => Image.network(
                    _zenUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Image.asset(
                      'assets/images/hero-japan.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.06),
                        Colors.black.withValues(alpha: 0.38),
                      ],
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.bottomLeft,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                    child: Text(
                      caption,
                      style: const TextStyle(
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
