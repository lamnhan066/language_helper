import '../../language_helper.dart';

/// Converts [LanguageData] to a serializable map structure.
///
/// This function transforms [LanguageData] (where keys are [LanguageCodes])
/// into a map where language codes are represented as strings. It also converts
/// [LanguageConditions] objects to their map representation.
///
/// The resulting map structure:
/// ```dart
/// {
///   'en': {
///     'Hello': 'Hello',
///     'Count': LanguageConditions(...) // Converted to map
///   },
///   'vi': {...}
/// }
/// ```
///
/// Used for JSON serialization and export operations.
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

/// Converts a map structure back to [LanguageData].
///
/// This function reverses the transformation done by [languageDataToMap],
/// converting string keys back to [LanguageCodes] and map representations
/// back to [LanguageConditions] objects where applicable.
///
/// **Input format:**
/// ```dart
/// {
///   'en': {
///     'Hello': 'Hello',
///     'Count': {'param': 'count', 'conditions': {...}} // Converted back to LanguageConditions
///   },
///   'vi': {...}
/// }
/// ```
///
/// Used for JSON deserialization when loading translation data from JSON files.
LanguageData languageDataFromMap(Map<String, dynamic> map) {
  return map.map((key, value) {
    // Reorganize the `value` back to String and LanguageCondition
    value = languageDataValuesFromMap(value);
    return MapEntry(LanguageCodes.fromCode(key), value.cast<String, dynamic>());
  });
}

/// Converts translation values from a map, handling [LanguageConditions].
///
/// This function processes the translation values (strings and condition maps)
/// within a single language's data. It identifies map structures that represent
/// [LanguageConditions] and converts them back to [LanguageConditions] objects.
///
/// Used internally by [languageDataFromMap] to process translation values
/// for each language code.
///
/// **Process:**
/// - String values remain as strings
/// - Map values that match [LanguageConditions] structure are converted to [LanguageConditions]
/// - Other map values remain as maps
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
