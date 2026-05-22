import '../utils/json_field.dart';

class PowerUpItem {
  const PowerUpItem({
    required this.id,
    required this.slug,
    required this.name,
    this.description,
    this.effectType = '',
    this.xuPrice,
    this.isPremium = false,
    this.quantityOwned = 0,
  });

  final int id;
  final String slug;
  final String name;
  final String? description;
  final String effectType;
  final int? xuPrice;
  final bool isPremium;
  final int quantityOwned;

  bool get canBuyWithXu => xuPrice != null && xuPrice! > 0;

  factory PowerUpItem.fromJson(Map<String, dynamic> json) {
    return PowerUpItem(
      id: jsonInt(json, 'id') ?? 0,
      slug: jsonStr(json, 'slug') ?? '',
      name: jsonStr(json, 'name') ?? 'Vật phẩm',
      description: jsonStr(json, 'description'),
      effectType: jsonStr(json, 'effectType') ?? '',
      xuPrice: jsonInt(json, 'xuPrice'),
      isPremium: jsonBool(json, 'isPremium'),
      quantityOwned: jsonInt(json, 'quantityOwned') ?? 0,
    );
  }
}

class GameInventory {
  const GameInventory({required this.items});

  final List<PowerUpItem> items;

  factory GameInventory.fromJson(Map<String, dynamic> json) {
    final raw = jsonField(json, 'items');
    final list = raw is List ? raw.whereType<Map<String, dynamic>>().map(PowerUpItem.fromJson).toList() : <PowerUpItem>[];
    return GameInventory(items: _dedupeBySlug(list));
  }

  static List<PowerUpItem> _dedupeBySlug(List<PowerUpItem> rows) {
    final seen = <String>{};
    final out = <PowerUpItem>[];
    final sorted = [...rows]..sort((a, b) => a.id.compareTo(b.id));
    for (final r in sorted) {
      final slug = r.slug.trim().toLowerCase();
      if (slug.isEmpty || seen.add(slug)) out.add(r);
    }
    return out;
  }
}

class PurchasePowerUpResult {
  const PurchasePowerUpResult({required this.xuBalance, required this.quantityOwned});

  final int xuBalance;
  final int quantityOwned;

  factory PurchasePowerUpResult.fromJson(Map<String, dynamic> json) {
    return PurchasePowerUpResult(
      xuBalance: jsonInt(json, 'xuBalance') ?? 0,
      quantityOwned: jsonInt(json, 'quantityOwned') ?? 0,
    );
  }
}

class UsePowerUpResult {
  const UsePowerUpResult({this.hiddenOptionIndices = const []});

  final List<int> hiddenOptionIndices;

  factory UsePowerUpResult.fromJson(Map<String, dynamic> json) {
    final raw = jsonField(json, 'hiddenOptionIndices');
    if (raw is List) {
      return UsePowerUpResult(
        hiddenOptionIndices: raw.map((e) => (e as num).toInt()).toList(),
      );
    }
    return const UsePowerUpResult();
  }
}

class KanjiMemoryResult {
  const KanjiMemoryResult({
    required this.finalScore,
    required this.expEarned,
    required this.xuEarned,
  });

  final int finalScore;
  final int expEarned;
  final int xuEarned;

  factory KanjiMemoryResult.fromJson(Map<String, dynamic> json) {
    return KanjiMemoryResult(
      finalScore: jsonInt(json, 'finalScore') ?? 0,
      expEarned: jsonInt(json, 'expEarned') ?? 0,
      xuEarned: jsonInt(json, 'xuEarned') ?? 0,
    );
  }
}
