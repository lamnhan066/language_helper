import 'package:flutter_test/flutter_test.dart';
import 'package:language_helper/language_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'language_data.dart';
import 'widgets.dart';

// Initial
final languageHelper = LanguageHelper.instance;

void main() async {
  // Use en as default language
  SharedPreferences.setMockInitialValues({});
  await languageHelper.initial(
    data: data,
    initialCode: LanguageCodes.en,
    useInitialCodeWhenUnavailable: false,
  );

  group('Test base translation', () {
    setUp(() {
      languageHelper.setUseInitialCodeWhenUnavailable(false);
      languageHelper.change(LanguageCodes.en);
    });

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
      languageHelper.change(LanguageCodes.vi);
      languageHelper.setUseInitialCodeWhenUnavailable(false);
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
      languageHelper.setUseInitialCodeWhenUnavailable(true);
      languageHelper.change(LanguageCodes.en);

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

    test('Translate with condition', () {
      languageHelper.setUseInitialCodeWhenUnavailable(true);
      languageHelper.change(LanguageCodes.en);

      expect('You have @{number} dollar'.trP({'number': 0}),
          equals('You have zero dollar'));
      expect('You have @{number} dollar'.trP({'number': 1}),
          equals('You have 1 dollar'));
      expect('You have @{number} dollar'.trP({'number': 2}),
          equals('You have 2 dollars'));
      expect('You have @{number} dollar'.trP({'number': 100}),
          equals('You have 100 dollars'));

      languageHelper.change(LanguageCodes.vi);
      expect('You have @{number} dollar'.trP({'number': 0}),
          equals('Bạn có 0 đô-la'));
      expect('You have @{number} dollar'.trP({'number': 1}),
          equals('Bạn có 1 đô-la'));
      expect('You have @{number} dollar'.trP({'number': 2}),
          equals('Bạn có 2 đô-la'));
      expect('You have @{number} dollar'.trP({'number': 100}),
          equals('Bạn có 100 đô-la'));
    });
  });

  group('Language Data serializer', () {
    languageHelper.setUseInitialCodeWhenUnavailable(true);
    languageHelper.change(LanguageCodes.en);

    final toJson = data.toJson();
    final fromJson = LanguageDataSerializer.fromJson(toJson);

    test('LanguageData ToJson and FromJson', () {
      expect(toJson, isA<String>());

      expect(fromJson, equals(data));
    });

    test('LanguageData ToJson and FromJson', () {
      expect(toJson, isA<String>());

      expect(fromJson, equals(data));
    });
  });

  group('Test widget', () {
    testWidgets('LanguageBuilder', (tester) async {
      // Use en as default language
      SharedPreferences.setMockInitialValues({});
      await languageHelper.initial(data: data, initialCode: LanguageCodes.en);

      await tester.pumpWidget(const LanguageHelperWidget());
      await tester.pumpAndSettle();

      // initial language is English
      final helloText = find.text('Hello');
      final xinChaoText = find.text('Xin Chào');
      final dollar100 = find.text('You have 100 dollars');
      final dollar10 = find.text('You have 10, dollars');

      expect(helloText, findsNWidgets(2));
      expect(xinChaoText, findsNothing);
      expect(dollar100, findsOneWidget);
      expect(dollar10, findsOneWidget);

      languageHelper.change(LanguageCodes.vi);
      await tester.pumpAndSettle();

      expect(helloText, findsOneWidget);
      expect(xinChaoText, findsOneWidget);
      expect(dollar100, findsNothing);
      expect(dollar10, findsNothing);
    });

    testWidgets('Lhb', (tester) async {
      // Use en as default language
      SharedPreferences.setMockInitialValues({});
      await languageHelper.initial(data: data, initialCode: LanguageCodes.en);

      await tester.pumpWidget(const TrWidget());
      await tester.pumpAndSettle();

      // initial language is English
      final helloText = find.text('Hello');
      final xinChaoText = find.text('Xin Chào');
      final dollar100 = find.text('You have 100 dollars');
      final dollar10 = find.text('You have 10, dollars');

      expect(helloText, findsNWidgets(2));
      expect(xinChaoText, findsNothing);
      expect(dollar100, findsOneWidget);
      expect(dollar10, findsOneWidget);

      languageHelper.change(LanguageCodes.vi);
      await tester.pumpAndSettle();

      expect(helloText, findsOneWidget);
      expect(xinChaoText, findsOneWidget);
      expect(dollar100, findsNothing);
      expect(dollar10, findsNothing);
    });
  });
}
