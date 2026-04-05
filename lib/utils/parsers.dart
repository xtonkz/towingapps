Map<String, dynamic> ensureJsonMap(dynamic value) {
  if (value is Map<String, dynamic>) {
    return value;
  }

  if (value is Map) {
    return value.map(
      (key, dynamic item) => MapEntry(key.toString(), item),
    );
  }

  return const <String, dynamic>{};
}

List<Map<String, dynamic>> ensureJsonMapList(dynamic value) {
  if (value is! List) {
    return const <Map<String, dynamic>>[];
  }

  return value
      .whereType<Map>()
      .map<Map<String, dynamic>>(ensureJsonMap)
      .toList(growable: false);
}

String parseString(dynamic value, {String fallback = ''}) {
  if (value == null) {
    return fallback;
  }

  final parsed = value.toString().trim();
  return parsed.isEmpty ? fallback : parsed;
}

String firstNonEmptyString(
  Iterable<dynamic> values, {
  String fallback = '',
}) {
  for (final value in values) {
    final parsed = parseString(value);
    if (parsed.isNotEmpty) {
      return parsed;
    }
  }

  return fallback;
}

int? parseNullableInt(dynamic value) {
  if (value == null) {
    return null;
  }

  if (value is int) {
    return value;
  }

  if (value is num) {
    return value.toInt();
  }

  return int.tryParse(parseString(value));
}

int parseInt(dynamic value, {int fallback = 0}) {
  return parseNullableInt(value) ?? fallback;
}

int firstPositiveInt(Iterable<dynamic> values, {int fallback = 0}) {
  for (final value in values) {
    final parsed = parseNullableInt(value);
    if (parsed != null && parsed > 0) {
      return parsed;
    }
  }

  return fallback;
}

double? parseDouble(dynamic value) {
  if (value == null) {
    return null;
  }

  if (value is num) {
    return value.toDouble();
  }

  return double.tryParse(parseString(value));
}

bool parseBool(dynamic value, {bool fallback = false}) {
  if (value is bool) {
    return value;
  }

  final normalized = parseString(value).toLowerCase();
  if (normalized.isEmpty) {
    return fallback;
  }

  if (const ['1', 'true', 'yes', 'active'].contains(normalized)) {
    return true;
  }

  if (const ['0', 'false', 'no', 'inactive'].contains(normalized)) {
    return false;
  }

  return fallback;
}

DateTime? parseDateTime(dynamic value) {
  final raw = parseString(value);
  if (raw.isEmpty) {
    return null;
  }

  return DateTime.tryParse(raw);
}

String joinNonEmpty(
  Iterable<String> values, {
  String separator = ' • ',
}) {
  return values.where((value) => value.trim().isNotEmpty).join(separator);
}
