/// Ảnh power-up — khớp web `ART_BY_SLUG` (`frontend/src/pages/Play/PlayShop.jsx`).
class PlayPowerupArt {
  PlayPowerupArt._();

  static const _base = 'assets/images/play';

  static const Map<String, String> _bySlug = {
    'fifty-fifty': '$_base/powerup-5050.png',
    'time-freeze': '$_base/powerup-time-freeze.png',
    'double-points': '$_base/powerup-double.png',
    'skip': '$_base/powerup-skip.png',
    'heart': '$_base/powerup-heart.png',
  };

  static String assetForSlug(String slug) {
    final key = slug.trim().toLowerCase();
    return _bySlug[key] ?? _bySlug['fifty-fifty']!;
  }
}
