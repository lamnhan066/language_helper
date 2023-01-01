import 'package:flutter_test/flutter_test.dart';
import 'package:language_helper/language_helper.dart';

LanguageData data = {
  LanguageCodes.en: {
    'Hello': 'Hello',
    'You have @number dollars': 'You have @number dollars',
  },
  LanguageCodes.vi: {
    'Hello': 'Xin Chào',
    'You have @number dollars': 'Bạn có @number đô-la',
  }
};

void main() {
  // Initial
  final languageHelper = LanguageHelper.instance;

  // Use en as default language
  languageHelper.initial(data: data, initialCode: LanguageCodes.en);

  group('', () {
    test('Test with default language', () {
      expect('Hello'.tr, equals('Hello'));

      expect('You have @number dollars'.trP({'number': '100'}),
          equals('You have 100 dollars'));
    });

    test('Test with vi language', () {
      languageHelper.change(LanguageCodes.vi);

      expect('Hello'.tr, equals('Xin Chào'));

      expect('You have @number dollars'.trP({'number': '100'}),
          equals('Bạn có 100 đô-la'));
    });

    test(
        'Test with undefined language when useInitialCodeWhenUnavailable = false',
        () {
      languageHelper.change(LanguageCodes.cu);

      expect('Hello'.tr, equals('Xin Chào'));

      expect('You have @number dollars'.trP({'number': '100'}),
          equals('Bạn có 100 đô-la'));
    });

    test(
        'Test with undefined language when useInitialCodeWhenUnavailable = true',
        () {
      languageHelper.setUseInitialCodeWhenUnavailable(true);
      languageHelper.change(LanguageCodes.cu);

      expect('Hello'.tr, equals('Hello'));

      expect('You have @number dollars'.trP({'number': '100'}),
          equals('You have 100 dollars'));
    });
  });
}
