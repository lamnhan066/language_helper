library languages_helper;

import 'package:devicelocale/devicelocale.dart';
import 'package:flutter/material.dart';

part 'src/language_codes.dart';
part 'src/language_helper.dart';
part 'src/language_notifier.dart';

typedef LanguageData = Map<LanguageCodes, Map<String, String>>;

extension LanguageHelperEx on String {
  /// Translate
  String get tr => LanguageHelper.instance.translate(this);

  /// Translate with parammeters
  /// ``` dart
  /// final text = 'result is @{param}'.trP({'param' : 'zero'});
  /// print(text); // -> 'result is zero'
  String trP([Map<String, dynamic> params = const {}]) {
    return LanguageHelper.instance.translate(this, params: params);
  }
}
