import 'dart:convert';

import 'package:language_helper/language_helper.dart';
import 'package:language_helper/src/utils/serializer.dart' as s;

extension LanguageDataSerializer on LanguageData {
  /// Converts this [LanguageData] to a JSON string.
  ///
  /// Serializes the entire language data structure (all languages and their
  /// translations) into a JSON string. [LanguageConditions] are converted
  /// to their map representation during serialization.
  ///
  /// This is useful for storing or transmitting translation data.
  ///
  /// Example:
  /// ```dart
  /// final jsonString = languageData.toJson();
  /// await File('backup.json').writeAsString(jsonString);
  /// ```
  String toJson() => jsonEncode(toMap());

  /// Converts this [LanguageData] to a serializable map.
  ///
  /// Transforms [LanguageCodes] keys to strings and [LanguageConditions]
  /// to map representations. This map can be serialized to JSON or used
  /// for other serialization purposes.
  ///
  /// Example:
  /// ```dart
  /// final map = languageData.toMap();
  /// // map = {'en': {'Hello': 'Hello'}, 'vi': {'Hello': 'Xin chào'}}
  /// ```
  Map<String, dynamic> toMap() => s.languageDataToMap(this);

  /// Deserializes a JSON string back to [LanguageData].
  ///
  /// Parses the JSON string and converts it back to [LanguageData] format,
  /// with string keys converted to [LanguageCodes] and condition maps converted
  /// back to [LanguageConditions] objects.
  ///
  /// This is the inverse operation of [toJson].
  ///
  /// Example:
  /// ```dart
  /// final json = await File('translations.json').readAsString();
  /// final languageData = LanguageDataSerializer.fromJson(json);
  /// ```
  static LanguageData fromJson(String json) {
    return fromMap(jsonDecode(json));
  }

  /// Converts a map structure back to [LanguageData].
  ///
  /// Transforms string keys back to [LanguageCodes] and condition maps
  /// back to [LanguageConditions]. This is the inverse operation of [toMap].
  ///
  /// Example:
  /// ```dart
  /// final map = {'en': {'Hello': 'Hello'}, 'vi': {'Hello': 'Xin chào'}};
  /// final languageData = LanguageDataSerializer.fromMap(map);
  /// ```
  static LanguageData fromMap(Map<String, dynamic> map) {
    return s.languageDataFromMap(map);
  }

  /// Converts JSON containing only translation values (single language) to a map.
  ///
  /// This static method is used when loading a single language's translations
  /// from a JSON file (e.g., `en.json`). It processes the values, converting
  /// [LanguageConditions] maps back to [LanguageConditions] objects where applicable.
  ///
  /// **Input format:** JSON string with translation keys and values
  /// ```json
  /// {
  ///   "Hello": "Hello",
  ///   "Count": {"param": "count", "conditions": {...}}
  /// }
  /// ```
  ///
  /// Used internally by [LanguageDataProvider.asset] and [LanguageDataProvider.network].
  static Map<String, dynamic> valuesFromJson(String json) {
    return s.languageDataValuesFromMap(jsonDecode(json));
  }
}
