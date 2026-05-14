part of '../language_helper.dart';

/// Resolves a fallback language code using only the language part of
/// [requested], when possible.
LanguageCodes? defaultFallbackCodeResolver(
  LanguageHelper helper,
  LanguageCodes requested,
) {
  try {
    final requestedLanguageCode = requested.locale.languageCode;

    helper._logger?.info(
      () =>
          'Trying language-only fallback for $requested => '
          'searching for $requestedLanguageCode',
    );

    final languageOnlyCode = LanguageCodes.fromCode(
      requestedLanguageCode,
    );

    if (helper.codes.contains(languageOnlyCode)) {
      helper._logger?.step(
        () =>
            'The `languageCode` only $languageOnlyCode is available in '
            '`data` => Change the language to $languageOnlyCode',
      );
      return languageOnlyCode;
    }

    for (final code in helper.codes) {
      if (code.locale.languageCode == requestedLanguageCode) {
        helper._logger?.step(
          () =>
              'A code with the same `languageCode` $code is available in '
              '`data` => Change the language to $code',
        );
        return code;
      }
    }

    helper._logger?.info(
      () =>
          'The `languageCode` only is not valid or not found in `data` => '
          'Cannot use the `languageCode` only.',
    );

    // Catch the error when the language code is not valid.
    // ignore: avoid_catches_without_on_clauses
  } catch (_) {
    helper._logger?.info(
      () =>
          'The `languageCode` only is not valid or not found in `data` => '
          'Cannot use the `languageCode` only.',
    );
    return null;
  }

  return null;
}
