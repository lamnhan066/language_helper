import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:language_helper/src/language_helper.dart';

extension LanguageLocalizations on LanguageHelper {
  /// Standard Flutter localization delegates for Material, Cupertino, and
  /// Widgets. Use with [MaterialApp.localizationsDelegates] to enable
  /// Flutter's built-in localizations.
  ///
  /// Example:
  /// ```dart
  /// MaterialApp(
  ///   localizationsDelegates: [
  ///     ...languageHelper.delegates,
  ///     LanguageDelegate(languageHelper),
  ///   ],
  ///   supportedLocales: languageHelper.locales,
  ///   locale: languageHelper.locale,
  /// )
  /// ```
  List<LocalizationsDelegate> get delegates => [
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ];
}
