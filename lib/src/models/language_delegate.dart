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
/// await languageHelper.initial(
///   LanguageConfig(data: []),
/// );
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
  LanguageDelegate(this.languageHelper, {this.supportedCodes});

  /// The [LanguageHelper] instance managed by this delegate.
  final LanguageHelper languageHelper;

  /// The list of supported locales.
  ///
  /// If null, the supported locales will default to those supported by
  /// [languageHelper]. The [supportedCodes] should be set because the
  /// locales from [languageHelper] are loaded asynchronously and may not
  /// be available when the delegate is created.
  final Set<LanguageCodes>? supportedCodes;

  /// Returns true if [locale] is supported by [languageHelper].
  @override
  bool isSupported(Locale locale) {
    try {
      return supportedCodes?.contains(LanguageCodes.fromLocale(locale)) ??
          languageHelper.locales.contains(locale);
      // Unsupported locale will throw an exception or error
      // ignore: avoid_catches_without_on_clauses
    } catch (_) {
      return false;
    }
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
