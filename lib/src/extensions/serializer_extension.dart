import 'dart:convert';

import 'package:language_helper/language_helper.dart';
import 'package:language_helper/src/utils/serializer.dart' as s;

extension LanguageDataSerializer on LanguageData {
  /// Convert this [LanguageData] to JSON
  String toJson() => jsonEncode(toMap());

  /// Convert this [LanguageData] to Map
  Map<String, dynamic> toMap() => s.languageDataToMap(this);

  /// Convert the JSON back to the [LanguageData]
  static LanguageData fromJson(String json) {
    return fromMap(jsonDecode(json));
  }

  /// Convert the Map back to the [LanguageData]
  static LanguageData fromMap(Map<String, dynamic> map) {
    return s.languageDataFromMap(map);
  }

  /// Convert the JSON with values-only to `Map<String, dynamic>` where `dynamic`
  /// is `String` or `LanguageConditions`.
  static Map<String, dynamic> valuesFromJson(String json) {
    return s.languageDataValuesFromMap(jsonDecode(json));
  }
}
