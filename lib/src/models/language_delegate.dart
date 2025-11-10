import 'package:flutter/widgets.dart';
import 'package:language_helper/language_helper.dart';

/// A [LocalizationsDelegate] that provides [LanguageHelper] instances to Flutter's
/// localization system.
///
/// This delegate integrates [LanguageHelper] with Flutter's built-in localization
/// infrastructure, allowing it to be used with [MaterialApp] or [CupertinoApp]
/// through the `localizationsDelegates` parameter.
///
/// Example:
/// ```dart
/// final languageHelper = LanguageHelper.instance;
/// await languageHelper.initial(data: []);
///
/// MaterialApp(
///   localizationsDelegates: [
///     LanguageDelegate(languageHelper),
///     // ... other delegates
///   ],
///   supportedLocales: languageHelper.locales,
///   locale: languageHelper.locale,
/// )
/// ```
class LanguageDelegate extends LocalizationsDelegate<LanguageHelper> {
  /// Creates a [LanguageDelegate] for the given [languageHelper].
  ///
  /// The [languageHelper] instance will be used to provide translations and
  /// manage locale changes.
  LanguageDelegate(this.languageHelper);

  /// The [LanguageHelper] instance managed by this delegate.
  final LanguageHelper languageHelper;

  /// Checks if the given [locale] is supported by the [languageHelper].
  ///
  /// Returns `true` if [locale] is in the list of supported locales,
  /// `false` otherwise.
  @override
  bool isSupported(Locale locale) {
    return languageHelper.locales.contains(locale);
  }

  /// Loads translations for the given [locale].
  ///
  /// Changes the [languageHelper] to use the specified [locale] and returns
  /// the helper instance. This method is called by Flutter's localization
  /// system when a locale change is requested.
  @override
  Future<LanguageHelper> load(Locale locale) async {
    await languageHelper.change(LanguageCodes.fromLocale(locale));
    return languageHelper;
  }

  /// Determines if the delegate should reload when the widget tree rebuilds.
  ///
  /// Returns `true` if the [languageHelper] instance has changed or if the
  /// current locale has changed, indicating that a reload is necessary.
  @override
  bool shouldReload(covariant LanguageDelegate old) {
    return languageHelper != old.languageHelper ||
        languageHelper.locale != old.languageHelper.locale;
  }
}
