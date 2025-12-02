import 'package:flutter/cupertino.dart' show CupertinoApp;
import 'package:flutter/material.dart' show MaterialApp;
import 'package:flutter/widgets.dart';
import 'package:language_helper/language_helper.dart';

/// A [LocalizationsDelegate] that integrates [LanguageHelper] with Flutter's
/// localization system. Use with [MaterialApp] or [CupertinoApp] via
/// `localizationsDelegates`.
///
/// Example:
/// ```dart
/// final languageHelper = LanguageHelper.instance;
/// await languageHelper.initial(data: []);
///
/// MaterialApp(
///   localizationsDelegates: [
///     LanguageDelegate(languageHelper),
///     ...languageHelper.delegates,
///   ],
///   supportedLocales: languageHelper.locales,
///   locale: languageHelper.locale,
/// )
/// ```
class LanguageDelegate extends LocalizationsDelegate<LanguageHelper> {
  /// Creates a delegate for the given [languageHelper].
  LanguageDelegate(this.languageHelper);

  /// The [LanguageHelper] instance managed by this delegate.
  final LanguageHelper languageHelper;

  /// Returns true if [locale] is supported by [languageHelper].
  @override
  bool isSupported(Locale locale) {
    return languageHelper.locales.contains(locale);
  }

  /// Changes [languageHelper] to use [locale] and returns the helper. Called
  /// by Flutter's localization system.
  @override
  Future<LanguageHelper> load(Locale locale) async {
    await languageHelper.change(LanguageCodes.fromLocale(locale));
    return languageHelper;
  }

  /// Returns true if [languageHelper] instance or current locale has changed.
  @override
  bool shouldReload(covariant LanguageDelegate old) {
    return languageHelper != old.languageHelper ||
        languageHelper.locale != old.languageHelper.locale;
  }
}
