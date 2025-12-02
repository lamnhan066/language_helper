import '../../language_helper.dart';

/// Converts [LanguageData] to a serializable map. Transforms [LanguageCodes]
/// keys to strings and [LanguageConditions] to map representations. Used for
/// JSON serialization and export.
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

/// Converts a map back to [LanguageData]. Reverses [languageDataToMap] by
/// converting string keys to [LanguageCodes] and condition maps to
/// [LanguageConditions]. Used for JSON deserialization.
LanguageData languageDataFromMap(Map<String, dynamic> map) {
  return map.map((key, value) {
    // Reorganize the `value` back to String and LanguageCondition
    value = languageDataValuesFromMap(value);
    return MapEntry(LanguageCodes.fromCode(key), value.cast<String, dynamic>());
  });
}

/// Converts translation values from a map, converting condition maps to
/// [LanguageConditions]. Used internally by [languageDataFromMap] to process
/// values for each language code.
Map<String, dynamic> languageDataValuesFromMap(Map<String, dynamic> map) {
  return map.map((key, value) {
    //  Try to decode the data back to the LanguageCondition
    if (value is Map) {
      return MapEntry(
        key,
        LanguageConditions.fromMap(value.cast<String, dynamic>()),
      );
    }

    return MapEntry(key, value);
  });
}
