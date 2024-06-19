import 'package:flutter/foundation.dart';
import 'package:language_helper/src/language_helper.dart';

/// Internal function, print debug log
void printDebug(Object? Function() object) => LanguageHelper.instance.isDebug
    ? debugPrint('[Language Helper] ${object()}')
    : null;
