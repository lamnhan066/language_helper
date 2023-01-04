import 'package:flutter_test/flutter_test.dart';
import 'package:language_helper/language_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  SharedPreferences.setMockInitialValues({});
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

    test('Translate with parameters in multiple cases of text', () {
      expect('@number is a started text'.trP({'number': 100}),
          equals('100 is a started text'));
      expect('@{number} is a started text'.trP({'number': 100}),
          equals('100 is a started text'));

      expect(
          'The @number @{number}, @number is a middle text'
              .trP({'number': 100}),
          equals('The 100 100, 100 is a middle text'));

      expect('This text will end with @number'.trP({'number': 100}),
          equals('This text will end with 100'));
      expect('This text will end with @{number}'.trP({'number': 100}),
          equals('This text will end with 100'));
    });
  });
}
