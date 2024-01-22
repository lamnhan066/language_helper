import 'dart:convert';

import 'package:language_helper/language_helper.dart';
import 'package:language_helper/src/utils/serializer.dart' as s;

extension LanguageDataSerializer on LanguageData {
  /// Convert this [LanguageData] to JSON
  String toJson() => jsonEncode(toMap());

  /// Conver this [LanguageData] to Map
  Map<String, dynamic> toMap() => s.languageDataToMap(this);

  /// Export to json files for `LanguageDataProvider`. Default `path` is set to '.'.
  ///
  /// Generated path:
  /// `path`
  ///  |- resources
  ///  |  |- language_helper
  ///  |  |  |- json
  ///  |  |  |  |- codes.json
  ///  |  |  |  |  |- languages
  ///  |  |  |  |  |  |- en.json
  ///  |  |  |  |  |  |- vi.json
  void exportJson([String path = '.']) => s.exportJson(this, path);

  /// Convert the JSON back to the [LanguageData]
  static LanguageData fromJson(String json) {
    return fromMap(jsonDecode(json));
  }

  /// Convert the Map back to the [LanguageData]
  static LanguageData fromMap(Map<String, dynamic> map) {
    return s.languageDataFromMap(map);
  }

  /// Convert the JSON with values-only to Map<String, dynamic> where `dynamic`
  /// is `String` or `LanguageConditions`.
  static Map<String, dynamic> valuesFromJson(String json) {
    return s.languageDataValuesFromMap(jsonDecode(json));
  }
}
