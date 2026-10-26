Map<String, dynamic> asMap(dynamic value) {
  if (value is Map) {
    return value.map((key, item) => MapEntry(key.toString(), item));
  }
  return <String, dynamic>{};
}

List<dynamic> asList(dynamic value) => value is List ? value : const [];

List<T> mapList<T>(dynamic value, T Function(Map<String, dynamic> json) parse) {
  return asList(value).map((item) => parse(asMap(item))).toList();
}

int asInt(dynamic value, [int fallback = 0]) {
  if (value is int) return value;
  if (value is num) return value.round();
  if (value is String) return int.tryParse(value) ?? fallback;
  return fallback;
}

int? asIntOrNull(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.round();
  if (value is String) return int.tryParse(value);
  return null;
}

double asDouble(dynamic value, [double fallback = 0]) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? fallback;
  return fallback;
}

String asString(dynamic value, [String fallback = '']) {
  if (value == null) return fallback;
  return value.toString();
}

String? asStringOrNull(dynamic value) {
  if (value == null) return null;
  return value.toString();
}

bool asBool(dynamic value, [bool fallback = false]) {
  if (value is bool) return value;
  return fallback;
}
