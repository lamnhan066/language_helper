import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:language_helper/src/language_helper.dart';

extension LanguageLocalizations on LanguageHelper {
  /// Gets the standard Flutter localization delegates for Material, Cupertino, and Widgets.
  ///
  /// This extension provides the default [LocalizationsDelegate] instances required
  /// for Flutter's built-in localization system. These delegates handle localization
  /// for Material Design, Cupertino (iOS-style), and basic widgets.
  ///
  /// **Included delegates:**
  /// - [GlobalMaterialLocalizations.delegate] - Material Design localization
  /// - [GlobalWidgetsLocalizations.delegate] - Widget-level localization
  /// - [GlobalCupertinoLocalizations.delegate] - Cupertino (iOS-style) localization
  ///
  /// Use this with [MaterialApp.localizationsDelegates] to enable Flutter's
  /// built-in localizations alongside your custom translations.
  ///
  /// Example:
  /// ```dart
  /// MaterialApp(
  ///   localizationsDelegates: [
  ///     ...languageHelper.delegates, // Flutter built-in localizations
  ///     // Add your custom delegates here if needed
  ///   ],
  ///   supportedLocales: languageHelper.locales,
  ///   locale: languageHelper.locale,
  ///   // ...
  /// )
  /// ```
  List<LocalizationsDelegate> get delegates => [
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ];
}
