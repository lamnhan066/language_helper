import 'dart:convert';

import 'package:language_helper/language_helper.dart';
import 'package:language_helper/src/utils/serializer.dart' as s;

extension LanguageDataSerializer on LanguageData {
  /// Converts to a JSON string. [LanguageConditions] are converted to map
  /// representations.
  ///
  /// Example:
  /// ```dart
  /// final jsonString = languageData.toJson();
  /// await File('backup.json').writeAsString(jsonString);
  /// ```
  String toJson() => jsonEncode(toMap());

  /// Converts to a serializable map. Transforms [LanguageCodes] keys to
  /// strings and [LanguageConditions] to maps.
  ///
  /// Example:
  /// ```dart
  /// final map = languageData.toMap();
  /// // map = {'en': {'Hello': 'Hello'}, 'vi': {'Hello': 'Xin chào'}}
  /// ```
  Map<String, dynamic> toMap() => s.languageDataToMap(this);

  /// Deserializes a JSON string to [LanguageData]. Inverse of [toJson].
  ///
  /// Example:
  /// ```dart
  /// final json = await File('translations.json').readAsString();
  /// final languageData = LanguageDataSerializer.fromJson(json);
  /// ```
  static LanguageData fromJson(String json) {
    return fromMap(jsonDecode(json) as Map<String, dynamic>);
  }

  /// Converts a map to [LanguageData]. Inverse of [toMap].
  ///
  /// Example:
  /// ```dart
  /// final map = {'en': {'Hello': 'Hello'}, 'vi': {'Hello': 'Xin chào'}};
  /// final languageData = LanguageDataSerializer.fromMap(map);
  /// ```
  static LanguageData fromMap(Map<String, dynamic> map) {
    return s.languageDataFromMap(map);
  }

  /// Converts JSON with translation values (single language) to a map.
  /// Converts condition maps to [LanguageConditions]. Used internally by
  /// [LanguageDataProvider.asset] and [LanguageDataProvider.network].
  static Map<String, dynamic> valuesFromJson(String json) {
    return s.languageDataValuesFromMap(
      jsonDecode(json) as Map<String, dynamic>,
    );
  }
}
