import 'dart:convert';

import '../../language_helper.dart';

String languageDataToJson(LanguageData data) {
  return jsonEncode(data.map((key, value) {
    if (value is LanguageCondition) {
      return MapEntry(key.code, (value as LanguageCondition).toMap());
    }
    return MapEntry(key.code, value);
  }));
}

LanguageData languageDataFromJson(String data) {
  final decoded = jsonDecode(data) as Map<String, dynamic>;

  return decoded.map((key, value) {
    // Reorganize the `value` back to String and LanguageCondition
    value = value.map((key, value) {
      //  Try to decode the data back to the LanguageCondition
      try {
        final decoded = jsonDecode(value);
        if (decoded is Map) {
          return MapEntry(
              key, LanguageCondition.fromMap(decoded.cast<String, dynamic>()));
        }
      } catch (_) {}

      return MapEntry(key, value);
    });
    return MapEntry(LanguageCodes.fromCode(key), value.cast<String, dynamic>());
  });
}
