part of '../language_helper.dart';

/// Resolves a fallback language code using only the language part of
/// [requested], when possible.
///
/// Resolution order:
/// 1. Same language + (same country or same script)
/// 2. Language-only code (e.g. `en` when `en_US` is requested)
/// 3. First available code sharing the same language
LanguageCodes? defaultFallbackCodeResolver(
  LanguageHelper helper,
  LanguageCodes requested,
) {
  final requestedLocale = requested.locale;
  final requestedLanguageCode = requestedLocale.languageCode.toLowerCase();
  final codes = helper.codes;

  helper._logger?.info(
    () =>
        'Trying to resolve fallback for $requested using only the '
        'language part of the code.',
  );

  if (requestedLanguageCode.isEmpty) {
    helper._logger?.info(() => 'Requested language is empty; no fallback.');
    return null;
  }

  final lang = requestedLocale.languageCode.toLowerCase();
  final country = requestedLocale.countryCode?.toLowerCase();
  final script = requestedLocale.scriptCode?.toLowerCase();

  // First look for a code with the same language and script.
  for (final code in codes) {
    final locale = code.locale;
    if (locale.languageCode.toLowerCase() != lang) continue;

    final sameScript =
        script != null && locale.scriptCode?.toLowerCase() == script;

    if (sameScript) {
      helper._logger?.info(
        () =>
            'Found fallback with same language and script: $code. '
            'This is preferred over a language-only code.',
      );
      return code;
    }
  }

  // If none found, look for a code with the same language and country.
  for (final code in codes) {
    final locale = code.locale;
    if (locale.languageCode.toLowerCase() != lang) continue;

    final sameCountry =
        country != null && locale.countryCode?.toLowerCase() == country;

    if (sameCountry) {
      helper._logger?.info(
        () => 'Found fallback with same language and country: $code.',
      );
      return code;
    }
  }

  // If none found, look for a code with the same language.
  for (final code in codes) {
    final locale = code.locale;
    if (locale.languageCode.toLowerCase() == lang) {
      helper._logger?.info(
        () => 'Found fallback with same language: $code.',
      );
      return code;
    }
  }

  helper._logger?.info(
    () => 'No suitable fallback found for "$requestedLanguageCode".',
  );
  return null;
}
