import 'package:flutter/foundation.dart';
import 'package:language_helper/src/language_helper.dart';

/// Improve code coverage for debug logs
bool isTestingDebugLog = false;

/// Internal function, print debug log
void printDebug(Object? Function() object) {
  assert(() {
    if (isTestingDebugLog) {
      object();
    }
    return true;
  }());

  if (LanguageHelper.instance.isDebug) {
    debugPrint('[Language Helper] ${object()}');
  }
}
