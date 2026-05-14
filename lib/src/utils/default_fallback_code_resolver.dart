part of '../language_helper.dart';

/// Resolves a fallback language code using only the language part of
/// [requested], when possible.
LanguageCodes? defaultFallbackCodeResolver(
  LanguageHelper helper,
  LanguageCodes requested,
) {
  final requestedLocale = requested.locale;
  final codes = helper.codes;

  helper._logger?.info(
    () =>
        'Trying to resolve fallback for $requested using only the language '
        'part of the code.',
  );

  // 1) Prefer an exact match on language + country or script.
  for (final code in codes) {
    final locale = code.locale;
    final isSameLanguage = locale.languageCode == requestedLocale.languageCode;
    final isSameCountry =
        locale.countryCode != null &&
        requestedLocale.countryCode != null &&
        locale.countryCode == requestedLocale.countryCode;
    final isSameScript =
        locale.scriptCode != null &&
        requestedLocale.scriptCode != null &&
        locale.scriptCode == requestedLocale.scriptCode;

    if (isSameLanguage && (isSameCountry || isSameScript)) {
      helper._logger?.step(
        () =>
            'A code with the same `languageCode` and either the same '
            '`countryCode` or `scriptCode` $code is available in `data` '
            '=> Change the language to $code',
      );
      return code;
    }
  }

  // 2) Try a language-only fallback.
  final requestedLanguageCode = requestedLocale.languageCode;
  if (requestedLanguageCode.isEmpty) {
    helper._logger?.info(() => 'Requested language is empty; no fallback.');
    return null;
  }

  helper._logger?.info(
    () =>
        'Trying language-only fallback for $requested => '
        'searching for $requestedLanguageCode',
  );

  try {
    final languageOnlyCode = LanguageCodes.fromCode(requestedLanguageCode);

    if (codes.contains(languageOnlyCode)) {
      helper._logger?.step(
        () =>
            'The `languageCode` only $languageOnlyCode is available in `data` '
            '=> Change the language to $languageOnlyCode',
      );
      return languageOnlyCode;
    }
  } on FormatException catch (_) {
    helper._logger?.info(
      () => 'The `languageCode` only is not a valid code => Cannot use it.',
    );
    return null;
    // This can happen if the `languageCode` is not a valid ISO 639 code, or if
    // it contains invalid characters. In this case, we cannot use it as
    // a fallback.
    // ignore: avoid_catching_errors
  } on StateError catch (_) {
    helper._logger?.info(
      () => 'The `languageCode` only is not a valid code => Cannot use it.',
    );
    return null;
    // This can happen if the `languageCode` only is not a valid code in the
    // `LanguageCodes` enum. In this case, we cannot use it as a fallback.
    // ignore: avoid_catches_without_on_clauses
  } catch (e, st) {
    helper._logger?.warning(
      () => 'Unexpected error while resolving fallback: $e\n$st',
    );
    return null;
  }

  // 3) Fallback to the first available code with the same language.
  for (final code in codes) {
    if (code.locale.languageCode == requestedLanguageCode) {
      helper._logger?.step(
        () =>
            'A code with the same `languageCode` $code is available in `data` '
            '=> Change the language to $code',
      );
      return code;
    }
  }

  helper._logger?.info(
    () =>
        'No suitable language-only fallback found in `data` => Cannot '
        'use the `languageCode` only.',
  );

  return null;
}
