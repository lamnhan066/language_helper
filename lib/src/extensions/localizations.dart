import 'package:language_helper/src/language_helper.dart';
import 'package:material_ui/material_ui.dart';

/// Extension on [LanguageHelper] to get the standard localization
/// delegates.
extension LanguageLocalizations on LanguageHelper {
  /// Standard localization delegates for Material, Cupertino, and
  /// Widgets. Use with [MaterialApp.localizationsDelegates] to enable
  /// the built-in localizations.
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
  List<LocalizationsDelegate<dynamic>> get delegates =>
      GlobalMaterialLocalizations.delegates;
}
