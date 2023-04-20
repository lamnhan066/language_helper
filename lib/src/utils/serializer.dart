import 'dart:convert';

import '../../language_helper.dart';

String languageDataToJson(LanguageData data) {
  return jsonEncode(data.map((key, value) {
    value = value.map((key, value) {
      if (value is LanguageConditions) {
        return MapEntry(key, value.toMap());
      }

      return MapEntry(key, value);
    });

    return MapEntry(key.code, value);
  }));
}

LanguageData languageDataFromJson(String data) {
  final decoded = jsonDecode(data) as Map<String, dynamic>;

  return decoded.map((key, value) {
    // Reorganize the `value` back to String and LanguageCondition
    value = (value as Map<String, dynamic>).map((key, value) {
      //  Try to decode the data back to the LanguageCondition
      if (value is Map) {
        return MapEntry(
          key,
          LanguageConditions.fromMap(value.cast<String, dynamic>()),
        );
      }

      return MapEntry(key, value);
    });
    return MapEntry(LanguageCodes.fromCode(key), value.cast<String, dynamic>());
  });
}
