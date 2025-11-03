import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:language_helper/src/language_helper.dart';

extension LanguageLocalizations on LanguageHelper {
  /// Gets the Flutter default localizations.
  ///
  /// Includes:
  ///     GlobalMaterialLocalizations.delegate
  ///      GlobalWidgetsLocalizations.delegate
  ///      GlobalCupertinoLocalizations.delegate
  List<LocalizationsDelegate> get delegates => [
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ];
}
