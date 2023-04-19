import 'package:language_helper/language_helper.dart';
import 'package:language_helper/src/utils/serializer.dart';

extension LanguageDataSerializerEx on LanguageData {
  /// Convert this [LanguageData] to JSON
  String toJson() => languageDataToJson(this);

  /// Convert the JSON back to the [LanguageData]
  static LanguageData fromJson(String json) => languageDataFromJson(json);
}
