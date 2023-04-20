import '../../language_helper.dart';

Map<String, dynamic> languageDataToMap(LanguageData data) {
  return data.map((key, value) {
    value = value.map((key, value) {
      if (value is LanguageConditions) {
        return MapEntry(key, value.toMap());
      }

      return MapEntry(key, value);
    });

    return MapEntry(key.code, value);
  });
}

LanguageData languageDataFromMap(Map<String, dynamic> map) {
  return map.map((key, value) {
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
