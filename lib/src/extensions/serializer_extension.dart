import 'dart:convert';

import 'package:language_helper/language_helper.dart';
import 'package:language_helper/src/utils/serializer.dart';

extension LanguageDataSerializer on LanguageData {
  /// Convert this [LanguageData] to JSON
  String toJson() => jsonEncode(toMap());

  /// Conver this [LanguageData] to Map
  Map<String, dynamic> toMap() => languageDataToMap(this);

  /// Convert the JSON back to the [LanguageData]
  static LanguageData fromJson(String json) => fromMap(jsonDecode(json));

  /// Convert the Map back to the [LanguageData]
  static LanguageData fromMap(Map<String, dynamic> map) =>
      languageDataFromMap(map);
}
