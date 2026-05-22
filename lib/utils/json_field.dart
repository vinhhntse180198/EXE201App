/// Đọc field JSON camelCase hoặc PascalCase (ASP.NET).
dynamic jsonField(Map<String, dynamic> json, String camelKey) {
  if (json.containsKey(camelKey)) return json[camelKey];
  if (camelKey.isEmpty) return null;
  final pascal = camelKey[0].toUpperCase() + camelKey.substring(1);
  return json[pascal];
}

int? jsonInt(Map<String, dynamic> json, String key) {
  final v = jsonField(json, key);
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse('$v');
}

String? jsonStr(Map<String, dynamic> json, String key) {
  final v = jsonField(json, key);
  return v?.toString();
}

bool jsonBool(Map<String, dynamic> json, String key, {bool defaultValue = false}) {
  final v = jsonField(json, key);
  if (v is bool) return v;
  if (v == 1 || v == 'true' || v == 'True') return true;
  return defaultValue;
}

/// ASP.NET có thể trả mảng trực tiếp hoặc bọc `{ "value": [...] }`.
List<dynamic> jsonApiList(dynamic data) {
  if (data is List) return data;
  if (data is Map) {
    final m = Map<String, dynamic>.from(data);
    for (final key in ['value', 'Value', 'items', 'Items', 'data', 'Data', 'results', 'Results']) {
      final v = jsonField(m, key);
      if (v is List) return v;
    }
  }
  return [];
}

List<Map<String, dynamic>> jsonApiMapList(dynamic data) {
  return jsonApiList(data)
      .whereType<Map>()
      .map((e) => Map<String, dynamic>.from(e))
      .toList();
}

/// Object JSON hoặc bọc `{ "value": { ... } }` (ASP.NET).
Map<String, dynamic>? jsonApiMap(dynamic data) {
  if (data == null) return null;
  if (data is Map) {
    final m = Map<String, dynamic>.from(data);
    final wrapped = jsonField(m, 'value');
    if (wrapped is Map) return Map<String, dynamic>.from(wrapped);
    return m;
  }
  return null;
}
