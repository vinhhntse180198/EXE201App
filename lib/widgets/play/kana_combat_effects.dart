/// Trạng thái FX combat — khớp web `kanaBattleAnim`, `kanaFxSlash`, `kanaFloats`.
class KanaCombatEffects {
  const KanaCombatEffects({
    this.anim = KanaBattleAnim.idle,
    this.slashFx = false,
    this.orbFx = false,
    this.screenFlash = KanaScreenFlash.none,
    this.floats = const [],
  });

  final KanaBattleAnim anim;
  final bool slashFx;
  final bool orbFx;
  final KanaScreenFlash screenFlash;
  final List<KanaCombatFloat> floats;

  static const idle = KanaCombatEffects();
}

enum KanaBattleAnim { idle, player, enemy }

enum KanaScreenFlash { none, whiteHit, redHit }

class KanaCombatFloat {
  const KanaCombatFloat({required this.id, required this.text, required this.tone});

  final String id;
  final String text;
  final KanaFloatTone tone;
}

enum KanaFloatTone { dmg, bonus, miss }

const kanaCombatDmg = 35;
const kanaCombatKillBonus = 25;
const kanaCombatWinScore = 100;
