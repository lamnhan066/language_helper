library languages_helper;

import 'package:flutter/material.dart';

part 'src/language_helper.dart';
part 'src/language_codes.dart';
part 'src/language_notifier.dart';

typedef LanguageData = Map<LanguageCodes, Map<String, String>>;

extension LanguageHelperEx on String {
  String get tr => LanguageHelper.instance.translate(this);
}
