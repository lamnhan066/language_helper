import 'package:flutter_test/flutter_test.dart';
import 'package:language_helper/language_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('defaultFallbackCodeResolver', () {
    test('returns null when requested language code is not in codes', () async {
      SharedPreferences.setMockInitialValues({});
      final helper = LanguageHelper('TestNotInCodes');
      await helper.initial(
        [
          LanguageDataProvider.data({
            LanguageCodes.en: {'Hello': 'Hello'},
            LanguageCodes.vi: {'Hello': 'Xin chào'},
          }),
        ],
        config: const LanguageConfig(isAutoSave: false),
      );

      final result = defaultFallbackCodeResolver(
        helper,
        LanguageCodes.fr, // French not in codes
      );

      expect(result, isNull);
      await helper.dispose();
    });

    test('returns code with same language when requested', () async {
      SharedPreferences.setMockInitialValues({});
      final helper = LanguageHelper('TestSameLanguage');
      await helper.initial(
        [
          LanguageDataProvider.data({
            LanguageCodes.en: {'Hello': 'Hello'},
            LanguageCodes.vi: {'Hello': 'Xin chào'},
          }),
        ],
        config: const LanguageConfig(isAutoSave: false),
      );

      final result = defaultFallbackCodeResolver(
        helper,
        LanguageCodes.en,
      );

      expect(result, equals(LanguageCodes.en));
      await helper.dispose();
    });

    test(
      'returns initialCode when fallbackToInitialCode is true and no match',
      () async {
        SharedPreferences.setMockInitialValues({});
        final helper = LanguageHelper('TestFallbackToInitial');
        await helper.initial(
          [
            LanguageDataProvider.data({
              LanguageCodes.en: {'Hello': 'Hello'},
              LanguageCodes.vi: {'Hello': 'Xin chào'},
            }),
          ],
          config: const LanguageConfig(
            initialCode: LanguageCodes.vi,
            isAutoSave: false,
          ),
        );

        final result = defaultFallbackCodeResolver(
          helper,
          LanguageCodes.fr, // French not in codes
        );

        expect(result, equals(LanguageCodes.vi));
        await helper.dispose();
      },
    );

    test(
      'returns initialCode when initialCode is in codes and no match',
      () async {
        SharedPreferences.setMockInitialValues({});
        final helper = LanguageHelper('TestInitialInCodes');
        await helper.initial(
          [
            LanguageDataProvider.data({
              LanguageCodes.en: {'Hello': 'Hello'},
              LanguageCodes.vi: {'Hello': 'Xin chào'},
            }),
          ],
          config: const LanguageConfig(
            initialCode: LanguageCodes.vi, // In codes
            isAutoSave: false,
          ),
        );

        final result = defaultFallbackCodeResolver(
          helper,
          LanguageCodes.fr,
        );

        expect(result, equals(LanguageCodes.vi));
        await helper.dispose();
      },
    );

    test('returns null when fallbackToInitialCode is false', () async {
      SharedPreferences.setMockInitialValues({});
      final helper = LanguageHelper('TestNoFallbackInitial');
      await helper.initial(
        [
          LanguageDataProvider.data({
            LanguageCodes.en: {'Hello': 'Hello'},
            LanguageCodes.vi: {'Hello': 'Xin chào'},
          }),
        ],
        config: const LanguageConfig(
          initialCode: LanguageCodes.vi,
          fallbackToInitialCode: false,
          isAutoSave: false,
        ),
      );

      final result = defaultFallbackCodeResolver(
        helper,
        LanguageCodes.fr,
      );

      expect(result, isNull);
      await helper.dispose();
    });

    test('handles empty codes list', () async {
      SharedPreferences.setMockInitialValues({});
      final helper = LanguageHelper('TestEmptyCodes');
      await helper.initial(
        [],
        config: const LanguageConfig(isAutoSave: false),
      );

      final result = defaultFallbackCodeResolver(
        helper,
        LanguageCodes.en,
      );

      // When codes list is empty (temporary provider added),
      // fallback to same language
      expect(result, equals(LanguageCodes.en));
      await helper.dispose();
    });
  });
}
