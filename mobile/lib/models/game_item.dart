import '../utils/json_field.dart';

class GameItem {
  const GameItem({
    required this.id,
    required this.code,
    required this.name,
    this.description,
    this.skillType,
    this.isPvp = false,
    this.isActive = true,
  });

  final int id;
  final String code;
  final String name;
  final String? description;
  final String? skillType;
  final bool isPvp;
  final bool isActive;

  factory GameItem.fromJson(Map<String, dynamic> json) {
    return GameItem(
      id: jsonInt(json, 'id') ?? 0,
      code: jsonStr(json, 'code') ?? jsonStr(json, 'slug') ?? jsonStr(json, 'gameCode') ?? '',
      name: jsonStr(json, 'name') ?? jsonStr(json, 'title') ?? 'Game',
      description: jsonStr(json, 'description'),
      skillType: jsonStr(json, 'skillType'),
      isPvp: jsonBool(json, 'isPvp'),
      isActive: jsonBool(json, 'isActive', defaultValue: true),
    );
  }
}
