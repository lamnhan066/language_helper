import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:language_helper/src/language_helper.dart';

extension LanguageLocalizations on LanguageHelper {
  /// Get the flutter default localizations
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

  /// Get the flutter default localizations
  ///
  /// Includes:
  ///     GlobalMaterialLocalizations.delegate
  ///      GlobalWidgetsLocalizations.delegate
  ///      GlobalCupertinoLocalizations.delegat
  @Deprecated('Use the `delegates` insteads')
  List<LocalizationsDelegate> get delegate => delegates;
}
