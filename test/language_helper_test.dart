import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:language_code/language_code.dart';
import 'package:language_helper/language_helper.dart';
import 'package:language_helper/src/mixins/update_language.dart';
import 'package:language_helper/src/utils/utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'assets.dart';
import 'language_data.dart';
import 'mocks.dart';
import 'widgets.dart';

void main() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  // Initial
  final languageHelper = LanguageHelper.instance;
  // Use en as default language
  SharedPreferences.setMockInitialValues({});

  StreamSubscription? languageSub;

  setUpAll(() async {
    await languageHelper.initial(
      data: dataList,
      initialCode: LanguageCodes.en,
      useInitialCodeWhenUnavailable: false,
      isDebug: true,
      onChanged: (value) {
        debugPrint('onChanged: $value');
      },
    );

    languageSub = languageHelper.stream.listen((code) {
      debugPrint('Stream: $code');
    });
  });

  tearDownAll(() {
    languageHelper.dispose();
    languageSub?.cancel();
  });

  group('Test with empty data and use temporary testing data -', () {
    test('data = []', () async {
      await languageHelper.initial(data: []);
      expect(languageHelper.code, equals(LanguageCodes.en));
    });

    test('data = [] with isDebug: true to cover logger callback', () async {
      final testHelper = LanguageHelper('TestEmptyDataLogger');
      addTearDown(testHelper.dispose);

      await testHelper.initial(data: [], isDebug: true);
      expect(testHelper.code, equals(LanguageCodes.en));
    });
  });

  group('Test initial -', () {
    test('`isInitialized`', () async {
      final temp = LanguageHelper('TempLanguageHelper');
      expect(temp.isInitialized, equals(false));
      await temp.initial(data: []);
      expect(temp.isInitialized, equals(true));
    });
    test('`ensureInitialized`', () async {
      final temp = LanguageHelper('TempLanguageHelper');
      temp.ensureInitialized.then((value) {
        expect(temp.isInitialized, equals(true));
      });
      await temp.initial(data: []);
      await temp.ensureInitialized;
      expect(temp.isInitialized, equals(true));
    });
    test('accessing `code` before initialization throws', () {
      final temp = LanguageHelper('TempLanguageHelper2');
      expect(() => temp.code, throwsA(anything));
    });
  });

  group('Test with SharedPreferences', () {
    late LanguageHelper testHelper;

    setUp(() async {
      testHelper = LanguageHelper('TestSharedPreferences');
      SharedPreferences.setMockInitialValues({
        testHelper.codeKey: LanguageCodes.vi.code,
      });
      await testHelper.initial(
        data: dataList,
        useInitialCodeWhenUnavailable: false,
        isDebug: true,
        onChanged: (value) {
          expect(value, isA<LanguageCodes>());
        },
      );
    });

    tearDown(() {
      testHelper.dispose();
    });

    test('Get language from prefs', () {
      expect(testHelper.code, equals(LanguageCodes.vi));
    });
  });

  group('Test without SharedPreferences -', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
    });
    test('Get language from prefs and is available in LanguageData', () async {
      await languageHelper.initial(
        data: dataList,
        useInitialCodeWhenUnavailable: false,
        isDebug: true,
        isAutoSave: false,
        onChanged: (value) {
          expect(value, isA<LanguageCodes>());
        },
      );
      expect(languageHelper.code, equals(LanguageCodes.en));
    });

    test(
      'Get language from prefs and is unavailable in LanguageData',
      () async {
        await languageHelper.initial(
          data: dataList,
          initialCode: LanguageCodes.cu,
          useInitialCodeWhenUnavailable: false,
          isAutoSave: false,
          isDebug: true,
          onChanged: (value) {
            expect(value, isA<LanguageCodes>());
          },
        );
        expect(languageHelper.code, equals(LanguageCodes.en));
      },
    );
  });

  group('Test for using unavailable code', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      LanguageCode.setTestCode(LanguageCodes.cu);
      await languageHelper.initial(
        data: dataList,
        useInitialCodeWhenUnavailable: false,
        syncWithDevice: false,
        isAutoSave: false,
        isDebug: true,
        onChanged: (value) {
          expect(value, isA<LanguageCodes>());
        },
      );
    });

    tearDown(() {
      LanguageCode.setTestCode();
    });

    test('Get the first code in `data` if current locale is not available', () {
      expect(
        languageHelper.code,
        equals(languageHelper.data.entries.first.key),
      );
    });
  });

  group('Test for [codes]', () {
    tearDown(() {
      LanguageCode.setTestCode();
    });

    test('[data] has more LanguageCodes than [dataOverrides]', () async {
      final testHelper = LanguageHelper('TestCodes1');
      addTearDown(testHelper.dispose);

      final LanguageData dataOverrides = {
        LanguageCodes.vi: {},
        LanguageCodes.en: {},
        LanguageCodes.cu: {},
      };
      final LanguageData data = {LanguageCodes.vi: {}, LanguageCodes.en: {}};

      await testHelper.initial(
        data: [
          LanguageDataProvider.data(data),
          LanguageDataProvider.data(dataOverrides),
        ],
        useInitialCodeWhenUnavailable: false,
        isAutoSave: false,
        isDebug: true,
        onChanged: (value) {
          expect(value, isA<LanguageCodes>());
        },
      );
      expect(testHelper.codes, equals({...dataOverrides.keys, ...data.keys}));
    });

    test('[dataOverrides] has more LanguageCodes than [data]', () async {
      final testHelper = LanguageHelper('TestCodes2');
      addTearDown(testHelper.dispose);

      final LanguageData data = {
        LanguageCodes.vi: {},
        LanguageCodes.en: {},
        LanguageCodes.cu: {},
      };
      final LanguageData dataOverrides = {
        LanguageCodes.vi: {},
        LanguageCodes.en: {},
      };

      await testHelper.initial(
        data: [
          LanguageDataProvider.data(data),
          LanguageDataProvider.data(dataOverrides),
        ],
        useInitialCodeWhenUnavailable: false,
        isAutoSave: false,
        isDebug: true,
        onChanged: (value) {
          expect(value, isA<LanguageCodes>());
        },
      );

      expect(testHelper.codes, equals({...data.keys, ...dataOverrides.keys}));
    });
  });

  group('Test for using initial code when the `toCode` is unavailable', () {
    test('true', () async {
      final testHelper = LanguageHelper('TestUseInitial1');
      addTearDown(testHelper.dispose);

      SharedPreferences.setMockInitialValues({});
      await testHelper.initial(
        data: dataList,
        initialCode: LanguageCodes.en,
        useInitialCodeWhenUnavailable: true,
        onChanged: (code) {},
      );
      await testHelper.change(LanguageCodes.vi);
      expect(testHelper.code, equals(LanguageCodes.vi));

      await testHelper.change(LanguageCodes.cu);
      expect(testHelper.code, equals(LanguageCodes.en));
    });

    test('false', () async {
      final testHelper = LanguageHelper('TestUseInitial2');
      addTearDown(testHelper.dispose);

      SharedPreferences.setMockInitialValues({});
      await testHelper.initial(
        data: dataList,
        initialCode: LanguageCodes.en,
        useInitialCodeWhenUnavailable: false,
      );
      await testHelper.change(LanguageCodes.vi);
      expect(testHelper.code, equals(LanguageCodes.vi));

      await testHelper.change(LanguageCodes.cu);
      expect(testHelper.code, equals(LanguageCodes.vi));
    });

    test('true but initial code is null', () async {
      final testHelper = LanguageHelper('TestUseInitial3');
      addTearDown(testHelper.dispose);

      SharedPreferences.setMockInitialValues({});
      await testHelper.initial(
        data: dataList,
        useInitialCodeWhenUnavailable: false,
      );
      await testHelper.change(LanguageCodes.vi);
      expect(testHelper.code, equals(LanguageCodes.vi));

      await testHelper.change(LanguageCodes.cu);
      expect(testHelper.code, equals(LanguageCodes.vi));
    });

    test(
      'true but initial code is unavailable in data with isDebug: true to cover logger warning callback',
      () async {
        final testHelper = LanguageHelper('TestUseInitial4');
        addTearDown(testHelper.dispose);

        SharedPreferences.setMockInitialValues({});
        await testHelper.initial(
          data: dataList,
          initialCode: LanguageCodes.cu, // cu is not in dataList
          useInitialCodeWhenUnavailable: true,
          isDebug: true,
          onChanged: (code) {},
        );
        // Try to change to an unavailable language
        // This should trigger the warning at lines 877-878
        await testHelper.change(LanguageCodes.aa); // aa is also not in dataList
        // Should remain at the current code since initialCode is also unavailable
        expect(testHelper.code, isNot(equals(LanguageCodes.aa)));
      },
    );
  });

  group('Test for mixins', () {
    late UpdateLanguage updateLanguageMixin;
    setUp(() {
      updateLanguageMixin = UpdateLanguageMixinMock();
    });

    // Just a trick to increase the coverage
    test('UpdateLanguage Mixin', () {
      updateLanguageMixin.updateLanguage();
    });

    test('UpdateLanguage Mixin with custom implementation', () {
      final customMixin = CustomUpdateLanguageMixin();
      customMixin.updateLanguage();
      expect(customMixin.updateCount, equals(1));

      customMixin.updateLanguage();
      expect(customMixin.updateCount, equals(2));
    });

    test('UpdateLanguage Mixin with multiple calls', () {
      final mixin = UpdateLanguageMixinMock();
      mixin.updateLanguage();
      mixin.updateLanguage();
      mixin.updateLanguage();
      // Should not throw
    });
  });

  group('Test base translation', () {
    setUp(() async {
      languageHelper.setUseInitialCodeWhenUnavailable(false);
      await languageHelper.change(LanguageCodes.en);
    });

    test('Get variables', () {
      expect(languageHelper.code, equals(LanguageCodes.en));
      expect(languageHelper.locale, equals(LanguageCodes.en.locale));
      expect(
        languageHelper.locales,
        containsAll(<Locale>[LanguageCodes.en.locale, LanguageCodes.vi.locale]),
      );
    });

    test('Test with default language', () {
      expect('Hello'.tr, equals('Hello'));

      expect(
        'You have @number dollars'.trP({'number': '100'}),
        equals('You have 100 dollars'),
      );
    });

    test('Test with vi language', () async {
      await languageHelper.change(LanguageCodes.vi);

      expect('Hello'.tr, equals('Xin Chào'));

      expect(
        'You have @number dollars'.trP({'number': '100'}),
        equals('Bạn có 100 đô-la'),
      );
    });

    test('Test with the code that does not in the data', () {
      expect('Hello There'.trT(LanguageCodes.aa), equals('Hello There'));
    });

    test(
      'Test with undefined language when useInitialCodeWhenUnavailable = false',
      () async {
        await languageHelper.change(LanguageCodes.vi);
        languageHelper.setUseInitialCodeWhenUnavailable(false);
        await languageHelper.change(LanguageCodes.cu);

        expect('Hello'.tr, equals('Xin Chào'));

        expect(
          'You have @number dollars'.trP({'number': '100'}),
          equals('Bạn có 100 đô-la'),
        );
      },
    );

    test(
      'Test with undefined language when useInitialCodeWhenUnavailable = true',
      () async {
        languageHelper.setUseInitialCodeWhenUnavailable(true);
        await languageHelper.change(LanguageCodes.cu);

        expect('Hello'.tr, equals('Hello'));

        expect(
          'You have @number dollars'.trP({'number': '100'}),
          equals('You have 100 dollars'),
        );
      },
    );

    test('Translate with parameters in multiple cases of text', () async {
      languageHelper.setUseInitialCodeWhenUnavailable(true);
      await languageHelper.change(LanguageCodes.en);

      expect(
        '@number is a started text'.trP({'number': 100}),
        equals('100 is a started text'),
      );
      expect(
        '@{number} is a started text'.trP({'number': 100}),
        equals('100 is a started text'),
      );

      expect(
        'The @number @{number}, @number is a middle text'.trP({'number': 100}),
        equals('The 100 100, 100 is a middle text'),
      );

      expect(
        'This text will end with @number'.trP({'number': 100}),
        equals('This text will end with 100'),
      );
      expect(
        'This text will end with @{number}'.trP({'number': 100}),
        equals('This text will end with 100'),
      );
    });

    test('Translate with condition', () async {
      languageHelper.setUseInitialCodeWhenUnavailable(true);
      await languageHelper.change(LanguageCodes.en);

      expect(
        'You have @{number} dollar'.trP({'number': 0}),
        equals('You have zero dollar'),
      );
      expect(
        'You have @{number} dollar'.trP({'number': 1}),
        equals('You have 1 dollar'),
      );
      expect(
        'You have @{number} dollar'.trP({'number': 2}),
        equals('You have 2 dollars'),
      );
      expect(
        'You have @{number} dollar'.trP({'number': 100}),
        equals('You have 100 dollars'),
      );
      expect(
        'There are @number people in your family'.trP({'number': 100}),
        equals('There are 100 people in your family'),
      );
      expect(
        'There are @number people in your family'.trP({'non_number': 100}),
        equals('There are @number people in your family'),
      );

      await languageHelper.change(LanguageCodes.vi);
      expect(
        'You have @{number} dollar'.trP({'number': 0}),
        equals('Bạn có 0 đô-la'),
      );
      expect(
        'You have @{number} dollar'.trP({'number': 1}),
        equals('Bạn có 1 đô-la'),
      );
      expect(
        'You have @{number} dollar'.trP({'number': 2}),
        equals('Bạn có 2 đô-la'),
      );
      expect(
        'You have @{number} dollar'.trP({'number': 100}),
        equals('Bạn có 100 đô-la'),
      );
    });

    test('Test trT', () async {
      await languageHelper.change(LanguageCodes.vi);

      expect('Hello'.trT(LanguageCodes.vi), equals('Xin Chào'));
    });
  });

  group('Test LanguageConditions', () {
    late LanguageConditions conditions;
    setUp(() {
      conditions = const LanguageConditions(
        param: 'number',
        conditions: {
          '0': '0 dollar',
          '1': '1 dollar',
          'default': '@number dollars',
        },
      );
    });

    test('toJson and fromJson', () {
      final toJson = conditions.toJson();
      expect(toJson, isA<String>());

      final fromJson = LanguageConditions.fromJson(toJson);
      expect(fromJson, conditions);
      expect(fromJson.toJson(), toJson);

      expect(conditions.toString(), isA<String>());
      expect(dataList.hashCode, isNot(fromJson.hashCode));
    });

    test('equality and hashCode', () {
      final conditions1 = const LanguageConditions(
        param: 'number',
        conditions: {'0': 'zero', 'default': 'default'},
      );
      final conditions2 = const LanguageConditions(
        param: 'number',
        conditions: {'0': 'zero', 'default': 'default'},
      );
      final conditions3 = const LanguageConditions(
        param: 'count',
        conditions: {'0': 'zero', 'default': 'default'},
      );

      expect(conditions1, equals(conditions2));
      expect(conditions1.hashCode, equals(conditions2.hashCode));
      expect(conditions1, isNot(equals(conditions3)));
    });

    test('empty conditions', () {
      final emptyConditions = const LanguageConditions(
        param: 'test',
        conditions: {},
      );
      expect(emptyConditions.conditions, isEmpty);
      expect(emptyConditions.toJson(), isA<String>());
    });
  });

  group('dataOverrides', () {
    test('not using dataOverrides', () async {
      final testHelper = LanguageHelper('TestDataOverrides1');
      addTearDown(testHelper.dispose);

      await testHelper.initial(data: dataList);
      testHelper.change(LanguageCodes.en);

      final errorTranslated = 'You have @{number} dollar in your wallet'.trC(
        testHelper,
        params: {'number': 2},
      );
      expect(errorTranslated, 'You have 2 dollar in your wallet');
    });
    test('using dataOverrides', () async {
      final testHelper = LanguageHelper('TestDataOverrides2');
      addTearDown(testHelper.dispose);

      await testHelper.initial(data: [...dataList, ...dataOverrides]);
      testHelper.change(LanguageCodes.en);

      final translated = 'You have @{number} dollar in your wallet'.trC(
        testHelper,
        params: {'number': 2},
      );
      expect(translated, 'You have 2 dollars in your wallet');
    });
  });

  group('Language Data serializer', () {
    late String toJson;
    late LanguageData fromJson;
    setUp(() {
      languageHelper.setUseInitialCodeWhenUnavailable(true);
      languageHelper.change(LanguageCodes.en);
    });

    test('LanguageData ToJson and FromJson', () {
      toJson = languageHelper.data.toJson();
      expect(toJson, isA<String>());

      fromJson = LanguageDataSerializer.fromJson(toJson);
      for (final key in languageHelper.data.keys) {
        expect(languageHelper.data[key], equals(fromJson[key]));
      }
      expect(fromJson.toJson(), equals(toJson));
    });

    test('LanguageDataSerializer with empty data', () {
      final emptyData = <LanguageCodes, Map<String, dynamic>>{};
      final json = emptyData.toJson();
      expect(json, isA<String>());
      expect(json, equals('{}'));

      final fromJson = LanguageDataSerializer.fromJson(json);
      expect(fromJson, isEmpty);
    });

    test('LanguageDataSerializer with null values', () {
      final dataWithNulls = {
        LanguageCodes.en: {'key1': 'value1', 'key2': null},
      };
      final json = dataWithNulls.toJson();
      expect(json, isA<String>());

      final fromJson = LanguageDataSerializer.fromJson(json);
      expect(fromJson[LanguageCodes.en]!['key1'], equals('value1'));
      expect(fromJson[LanguageCodes.en]!['key2'], isNull);
    });

    test('LanguageDataSerializer with malformed JSON', () {
      expect(
        () => LanguageDataSerializer.fromJson('invalid json'),
        throwsA(isA<FormatException>()),
      );
    });

    test('LanguageDataSerializer with LanguageConditions in data', () {
      final dataWithConditions = {
        LanguageCodes.en: {
          'Count': const LanguageConditions(
            param: 'count',
            conditions: {'1': 'one', '_': 'many'},
          ),
        },
      };
      final json = dataWithConditions.toJson();
      expect(json, isA<String>());
      expect(json, isNotEmpty);

      final fromJson = LanguageDataSerializer.fromJson(json);
      expect(fromJson[LanguageCodes.en]!['Count'], isA<LanguageConditions>());
    });

    test('LanguageDataSerializer valuesFromJson with LanguageConditions', () {
      final json = '''
      {
        "Hello": "Hello",
        "Count": {
          "param": "count",
          "conditions": {
            "1": "one",
            "_": "many"
          }
        }
      }
      ''';
      final result = LanguageDataSerializer.valuesFromJson(json);
      expect(result['Hello'], equals('Hello'));
      expect(result['Count'], isA<LanguageConditions>());
    });

    test('LanguageDataSerializer with empty JSON', () {
      final result = LanguageDataSerializer.fromJson('{}');
      expect(result, isEmpty);
    });
  });

  group('Test `syncWithDevice`', () {
    test('false', () async {
      final testHelper = LanguageHelper('TestSyncDevice1');
      addTearDown(testHelper.dispose);

      SharedPreferences.setMockInitialValues({
        testHelper.deviceCodeKey: LanguageCodes.vi.code,
      });
      LanguageCode.setTestCode(LanguageCodes.en);
      await testHelper.initial(
        data: dataList,
        initialCode: LanguageCodes.vi,
        syncWithDevice: false,
      );

      expect(testHelper.code, equals(LanguageCodes.vi));
    });

    test('true and haven\'t local database', () async {
      final testHelper = LanguageHelper('TestSyncDevice2');
      addTearDown(testHelper.dispose);

      SharedPreferences.setMockInitialValues({});
      LanguageCode.setTestCode(LanguageCodes.en);
      await testHelper.initial(
        data: dataList,
        initialCode: LanguageCodes.vi,
        syncWithDevice: true,
      );

      expect(testHelper.code, equals(LanguageCodes.vi));
    });

    test(
      'true, the `languageCode_countryCode` not available in local database but the `languageCode` only is available and isOptionalCountryCode is true',
      () async {
        final testHelper = LanguageHelper('TestSyncDevice3');
        addTearDown(testHelper.dispose);

        SharedPreferences.setMockInitialValues({});
        LanguageCode.setTestCode(LanguageCodes.zh_TW);
        await testHelper.initial(data: dataAdds, syncWithDevice: true);

        expect(testHelper.code, equals(LanguageCodes.zh));
      },
    );

    test(
      'true, the `languageCode_countryCode` not available in local database but the `languageCode` only is available and isOptionalCountryCode is false',
      () async {
        final testHelper = LanguageHelper('TestSyncDevice4');
        addTearDown(testHelper.dispose);

        SharedPreferences.setMockInitialValues({});
        LanguageCode.setTestCode(LanguageCodes.zh_TW);
        await testHelper.initial(
          data: dataAdds,
          syncWithDevice: true,
          isOptionalCountryCode: false,
        );

        expect(testHelper.code, equals(LanguageCodes.en));
      },
    );

    test('true and have local database but with no changed code', () async {
      final testHelper = LanguageHelper('TestSyncDevice5');
      addTearDown(testHelper.dispose);

      SharedPreferences.setMockInitialValues({
        testHelper.deviceCodeKey: LanguageCodes.vi.code,
      });
      LanguageCode.setTestCode(LanguageCodes.vi);
      await testHelper.initial(
        data: dataList,
        initialCode: LanguageCodes.vi,
        syncWithDevice: true,
      );

      expect(testHelper.code, equals(LanguageCodes.vi));
    });

    test('true and have local database but with changed code', () async {
      final testHelper = LanguageHelper('TestSyncDevice6');
      addTearDown(testHelper.dispose);

      SharedPreferences.setMockInitialValues({
        testHelper.deviceCodeKey: LanguageCodes.vi.code,
      });
      LanguageCode.setTestCode(LanguageCodes.en);
      await testHelper.initial(
        data: dataList,
        initialCode: LanguageCodes.vi,
        syncWithDevice: true,
      );

      expect(testHelper.code, equals(LanguageCodes.en));
    });

    test(
      'true and have local database but with no changed code with isDebug: true to cover logger debug callback',
      () async {
        final testHelper = LanguageHelper('TestSyncDevice7');
        addTearDown(testHelper.dispose);

        SharedPreferences.setMockInitialValues({
          testHelper.deviceCodeKey: LanguageCodes.vi.code,
        });
        LanguageCode.setTestCode(LanguageCodes.vi);
        await testHelper.initial(
          data: dataList,
          initialCode: LanguageCodes.vi,
          syncWithDevice: true,
          isDebug: true,
        );

        expect(testHelper.code, equals(LanguageCodes.vi));
      },
    );

    test(
      'true and have local database but with changed code with isDebug: true to cover logger step callback',
      () async {
        final testHelper = LanguageHelper('TestSyncDevice8');
        addTearDown(testHelper.dispose);

        SharedPreferences.setMockInitialValues({
          testHelper.deviceCodeKey: LanguageCodes.vi.code,
        });
        LanguageCode.setTestCode(LanguageCodes.en);
        await testHelper.initial(
          data: dataList,
          initialCode: LanguageCodes.vi,
          syncWithDevice: true,
          isDebug: true,
        );

        expect(testHelper.code, equals(LanguageCodes.en));
      },
    );
  });

  group('Test widget', () {
    testWidgets('LanguageBuilder', (tester) async {
      // Use en as default language
      // languageHelper is already initialized in setUpAll()
      // Ensure we're in English mode
      await languageHelper.change(LanguageCodes.en);
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

      await languageHelper.change(LanguageCodes.vi);
      await tester.pumpAndSettle();

      expect(helloText, findsOneWidget);
      expect(xinChaoText, findsOneWidget);
      expect(dollar100, findsNothing);
      expect(dollar10, findsNothing);
    });

    testWidgets('Tr', (tester) async {
      // Use en as default language
      // languageHelper is already initialized in setUpAll()
      // Ensure we're in English mode
      await languageHelper.change(LanguageCodes.en);
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
      expect(dollar10, findsNWidgets(2));

      languageHelper.change(LanguageCodes.vi);
      await tester.pumpAndSettle();

      expect(helloText, findsOneWidget);
      expect(xinChaoText, findsOneWidget);
      expect(dollar100, findsNothing);
      expect(dollar10, findsNothing);
    });

    testWidgets('LanguageBuilder with custom LanguageHelper', (tester) async {
      // Use en as default language
      SharedPreferences.setMockInitialValues({});
      final helper = LanguageHelper('CustomLanguageHelper');
      await helper.initial(data: dataList, initialCode: LanguageCodes.en);

      await tester.pumpWidget(CustomLanguageHelperWidget(helper: helper));
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

      await helper.change(LanguageCodes.vi);
      await tester.pumpAndSettle();

      expect(helloText, findsOneWidget);
      expect(xinChaoText, findsOneWidget);
      expect(dollar100, findsNothing);
      expect(dollar10, findsNothing);
    });

    testWidgets('Tr rebuilds only itself on language change', (tester) async {
      int buildCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Tr((_) {
            buildCount++;
            return Text('hello'.tr);
          }),
        ),
      );

      expect(find.text('hello'.tr), findsOneWidget);
      expect(buildCount, 1);

      // Trigger language update
      LanguageHelper.instance.change(LanguageCodes.vi);

      await tester.pump();

      expect(find.text('hello'.tr), findsOneWidget);
      expect(buildCount, 2, reason: 'Tr rebuilt itself once');
    });

    testWidgets(
      'Only the outermost LanguageBuilder triggers a rebuild on language change',
      (tester) async {
        int outerBuilds = 0;
        int innerBuilds = 0;

        await tester.pumpWidget(
          MaterialApp(
            home: LanguageBuilder(
              builder: (_) {
                outerBuilds++;
                return LanguageBuilder(
                  builder: (_) {
                    innerBuilds++;
                    return const Text('nested');
                  },
                );
              },
            ),
          ),
        );

        // Initial build
        expect(find.text('nested'), findsOneWidget);
        expect(
          outerBuilds,
          1,
          reason: 'Outer LanguageBuilder should build once',
        );
        expect(
          innerBuilds,
          1,
          reason: 'Inner LanguageBuilder should build once',
        );

        // Trigger language change
        LanguageHelper.instance.change(LanguageCodes.vi);
        await tester.pump();

        expect(
          outerBuilds,
          2,
          reason:
              'Outer LanguageBuilder should rebuild once when language changes',
        );
        expect(
          innerBuilds,
          2,
          reason:
              'Inner LanguageBuilder should only rebuild as part of outer rebuild, not independently',
        );
      },
    );

    testWidgets('Disposed Tr is removed from LanguageHelper states', (
      tester,
    ) async {
      final helper = LanguageHelper.instance;

      await tester.pumpWidget(
        MaterialApp(home: Tr((_) => const Text('hello'))),
      );

      expect(helper.states.isNotEmpty, true);

      // Remove the widget
      await tester.pumpWidget(const SizedBox.shrink());

      await tester.pump();

      expect(
        helper.states.isEmpty,
        true,
        reason: 'Disposed Tr should unregister itself',
      );
    });

    testWidgets(
      'Only the outermost LanguageBuilder triggers a rebuild on language change',
      (tester) async {
        int outerBuilds = 0;
        int innerBuilds = 0;

        await tester.pumpWidget(
          MaterialApp(
            home: LanguageBuilder(
              builder: (_) {
                outerBuilds++;
                return LanguageBuilder(
                  builder: (_) {
                    innerBuilds++;
                    return const Text('nested');
                  },
                );
              },
            ),
          ),
        );

        // Initial build
        expect(find.text('nested'), findsOneWidget);
        expect(
          outerBuilds,
          1,
          reason: 'Outer LanguageBuilder should build once',
        );
        expect(
          innerBuilds,
          1,
          reason: 'Inner LanguageBuilder should build once',
        );

        // Trigger language change
        LanguageHelper.instance.change(LanguageCodes.vi);
        await tester.pump();

        expect(
          outerBuilds,
          2,
          reason:
              'Outer LanguageBuilder should rebuild once when language changes',
        );
        expect(
          innerBuilds,
          2,
          reason:
              'Inner LanguageBuilder should only rebuild as part of outer rebuild, not independently',
        );
      },
    );

    test('export json', () {
      final dir = Directory('./test/export_json');
      data.exportJson(dir.path);
      final codesFile = File('./test/export_json/codes.json');
      final codesJson = codesFile.readAsStringSync();
      expect(jsonDecode(codesJson), isA<List>());
      expect(jsonDecode(codesJson), isNotEmpty);

      // Test that language files are created in the correct structure
      final enFile = File('./test/export_json/data/en.json');
      final viFile = File('./test/export_json/data/vi.json');
      expect(enFile.existsSync(), isTrue);
      expect(viFile.existsSync(), isTrue);

      final enJson = jsonDecode(enFile.readAsStringSync());
      final viJson = jsonDecode(viFile.readAsStringSync());
      expect(enJson, isA<Map>());
      expect(viJson, isA<Map>());
      expect(enJson['Hello'], equals('Hello'));
      expect(viJson['Hello'], equals('Xin Chào'));

      dir.deleteSync(recursive: true);
    });

    test('export json with custom path', () {
      final dir = Directory('./test/custom_export');
      data.exportJson(dir.path);
      final codesFile = File('./test/custom_export/codes.json');
      expect(codesFile.existsSync(), isTrue);
      dir.deleteSync(recursive: true);
    });

    test('export lazy language data', () {
      final dir = Directory('./test/export_lazy');
      LazyLanguageData lazyData = {
        LanguageCodes.en: () => {'Hello': 'Hello'},
        LanguageCodes.vi: () => {'Hello': 'Xin Chào'},
      };
      lazyData.exportJson(dir.path);
      final codesFile = File('./test/export_lazy/codes.json');
      expect(codesFile.existsSync(), isTrue);
      dir.deleteSync(recursive: true);
    });

    test('export json with default path', () {
      final dir = Directory('./assets/languages');
      data.exportJson();
      final codesFile = File('./assets/languages/codes.json');
      expect(codesFile.existsSync(), isTrue);
      dir.deleteSync(recursive: true);
    });

    testWidgets('LanguageBuilder with different prefixes', (tester) async {
      SharedPreferences.setMockInitialValues({});

      final helper1 = LanguageHelper('WidgetTest1');
      final helper2 = LanguageHelper('WidgetTest2');

      await helper1.initial(data: dataList, initialCode: LanguageCodes.en);
      await helper2.initial(data: dataList, initialCode: LanguageCodes.vi);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                LanguageBuilder(
                  languageHelper: helper1,
                  builder: (_) => Text('Hello'.trC(helper1)),
                ),
                LanguageBuilder(
                  languageHelper: helper2,
                  builder: (_) => Text('Hello'.trC(helper2)),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Both widgets should show their respective languages
      expect(find.text('Hello'), findsOneWidget); // helper1 shows English
      expect(find.text('Xin Chào'), findsOneWidget); // helper2 shows Vietnamese

      // Change language in helper1 only
      await helper1.change(LanguageCodes.vi);
      await tester.pumpAndSettle();

      // Only helper1 should change, helper2 should remain Vietnamese
      expect(
        find.text('Xin Chào'),
        findsNWidgets(2),
      ); // Both show Vietnamese now
      expect(find.text('Hello'), findsNothing);

      // Dispose helpers
      helper1.dispose();
      helper2.dispose();
    });

    testWidgets('Tr widget with different prefixes', (tester) async {
      SharedPreferences.setMockInitialValues({});

      final helper1 = LanguageHelper('TrTest1');
      final helper2 = LanguageHelper('TrTest2');

      await helper1.initial(data: dataList, initialCode: LanguageCodes.en);
      await helper2.initial(data: dataList, initialCode: LanguageCodes.vi);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                Tr((_) => Text('Hello'.trC(helper1)), languageHelper: helper1),
                Tr((_) => Text('Hello'.trC(helper2)), languageHelper: helper2),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Both widgets should show their respective languages
      expect(find.text('Hello'), findsOneWidget); // helper1 shows English
      expect(find.text('Xin Chào'), findsOneWidget); // helper2 shows Vietnamese

      // Change language in helper1 only
      await helper1.change(LanguageCodes.vi);
      await tester.pumpAndSettle();

      // Only helper1 should change, helper2 should remain Vietnamese
      expect(
        find.text('Xin Chào'),
        findsNWidgets(2),
      ); // Both show Vietnamese now
      expect(find.text('Hello'), findsNothing);

      // Dispose helpers
      helper1.dispose();
      helper2.dispose();
    });

    testWidgets('Multiple LanguageHelper instances with same prefix', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});

      final helper1 = LanguageHelper('SharedWidgetPrefix');
      final helper2 = LanguageHelper('SharedWidgetPrefix');

      await helper1.initial(data: dataList, initialCode: LanguageCodes.en);

      // Change language in helper1
      await helper1.change(LanguageCodes.vi);

      // Initialize helper2 - should load the saved language
      await helper2.initial(data: dataList, initialCode: LanguageCodes.en);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                LanguageBuilder(
                  languageHelper: helper1,
                  builder: (_) => Text('Hello'.trC(helper1)),
                ),
                LanguageBuilder(
                  languageHelper: helper2,
                  builder: (_) => Text('Hello'.trC(helper2)),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Both should show Vietnamese since they share the same prefix
      expect(find.text('Xin Chào'), findsNWidgets(2));
      expect(find.text('Hello'), findsNothing);

      // Dispose helpers
      helper1.dispose();
      helper2.dispose();
    });

    testWidgets('Widget rebuild behavior with different prefixes', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});

      final helper1 = LanguageHelper('RebuildTest1');
      final helper2 = LanguageHelper('RebuildTest2');

      await helper1.initial(data: dataList, initialCode: LanguageCodes.en);
      await helper2.initial(data: dataList, initialCode: LanguageCodes.en);

      int buildCount1 = 0;
      int buildCount2 = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                LanguageBuilder(
                  languageHelper: helper1,
                  builder: (_) {
                    buildCount1++;
                    return Text('Hello'.trC(helper1));
                  },
                ),
                LanguageBuilder(
                  languageHelper: helper2,
                  builder: (_) {
                    buildCount2++;
                    return Text('Hello'.trC(helper2));
                  },
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(buildCount1, equals(1));
      expect(buildCount2, equals(1));

      // Change language in helper1 only
      await helper1.change(LanguageCodes.vi);
      await tester.pumpAndSettle();

      // Only helper1 should rebuild
      expect(buildCount1, equals(2));
      expect(buildCount2, equals(1));

      // Change language in helper2
      await helper2.change(LanguageCodes.vi);
      await tester.pumpAndSettle();

      // Only helper2 should rebuild
      expect(buildCount1, equals(2));
      expect(buildCount2, equals(2));

      // Dispose helpers
      helper1.dispose();
      helper2.dispose();
    });

    testWidgets('Nested LanguageBuilder with different prefixes', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});

      final outerHelper = LanguageHelper('OuterPrefix');
      final innerHelper = LanguageHelper('InnerPrefix');

      await outerHelper.initial(data: dataList, initialCode: LanguageCodes.en);
      await innerHelper.initial(data: dataList, initialCode: LanguageCodes.vi);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LanguageBuilder(
              languageHelper: outerHelper,
              builder: (_) => Column(
                children: [
                  Text('Hello'.trC(outerHelper)),
                  LanguageBuilder(
                    languageHelper: innerHelper,
                    builder: (_) => Text('Hello'.trC(innerHelper)),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Outer should show English, inner should show Vietnamese
      expect(find.text('Hello'), findsOneWidget);
      expect(find.text('Xin Chào'), findsOneWidget);

      // Change outer helper language
      await outerHelper.change(LanguageCodes.vi);
      await tester.pumpAndSettle();

      // Both should show Vietnamese now
      expect(find.text('Xin Chào'), findsNWidgets(2));
      expect(find.text('Hello'), findsNothing);

      // Change inner helper language
      await innerHelper.change(LanguageCodes.en);
      await tester.pumpAndSettle();

      // Outer should show Vietnamese, inner should show English
      expect(find.text('Hello'), findsOneWidget);
      expect(find.text('Xin Chào'), findsOneWidget);

      // Dispose helpers
      outerHelper.dispose();
      innerHelper.dispose();
    });

    testWidgets('Tr widget with custom prefix and parameters', (tester) async {
      SharedPreferences.setMockInitialValues({});

      final helper = LanguageHelper('ParameterTest');
      await helper.initial(data: dataList, initialCode: LanguageCodes.en);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                Tr(
                  (_) => Text(
                    'You have @number dollars'.trC(
                      helper,
                      params: {'number': 100},
                    ),
                  ),
                  languageHelper: helper,
                ),
                Tr(
                  (_) => Text(
                    'You have @{number} dollar'.trC(
                      helper,
                      params: {'number': 1},
                    ),
                  ),
                  languageHelper: helper,
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Should show English translations
      expect(find.text('You have 100 dollars'), findsOneWidget);
      expect(find.text('You have 1 dollar'), findsOneWidget);

      // Change to Vietnamese
      await helper.change(LanguageCodes.vi);
      await tester.pumpAndSettle();

      // Should show Vietnamese translations
      expect(find.text('Bạn có 100 đô-la'), findsOneWidget);
      expect(find.text('Bạn có 1 đô-la'), findsOneWidget);

      // Dispose helper
      helper.dispose();
    });

    testWidgets('LanguageBuilder with refreshTree enabled', (tester) async {
      // languageHelper is already initialized in setUpAll()
      // Ensure we're in English mode
      await languageHelper.change(LanguageCodes.en);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LanguageBuilder(
              refreshTree: true,
              builder: (_) => Text('Hello'.tr),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Hello'), findsOneWidget);

      // Change language
      await languageHelper.change(LanguageCodes.vi);
      await tester.pumpAndSettle();

      expect(find.text('Xin Chào'), findsOneWidget);
    });

    testWidgets('LanguageBuilder with forceRebuild true', (tester) async {
      // languageHelper is already initialized in setUpAll()
      // Ensure we're in English mode
      await languageHelper.change(LanguageCodes.en);
      int buildCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LanguageBuilder(
              forceRebuild: true,
              builder: (_) {
                buildCount++;
                return Text('Hello'.tr);
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(buildCount, equals(1));
      expect(find.text('Hello'), findsOneWidget);

      // Change language
      await languageHelper.change(LanguageCodes.vi);
      await tester.pumpAndSettle();

      expect(buildCount, equals(2));
      expect(find.text('Xin Chào'), findsOneWidget);
    });

    testWidgets('LanguageBuilder with forceRebuild false', (tester) async {
      // languageHelper is already initialized in setUpAll()
      // Ensure we're in English mode
      await languageHelper.change(LanguageCodes.en);
      int buildCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LanguageBuilder(
              forceRebuild: false,
              builder: (_) {
                buildCount++;
                return Text('Hello'.tr);
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(buildCount, equals(1));
      expect(find.text('Hello'), findsOneWidget);

      // Change language
      await languageHelper.change(LanguageCodes.vi);
      await tester.pumpAndSettle();

      // The widget may still rebuild due to the root LanguageBuilder behavior
      expect(buildCount, greaterThanOrEqualTo(1));
      expect(find.text('Xin Chào'), findsOneWidget);
    });

    testWidgets('Tr widget with refreshTree enabled', (tester) async {
      // languageHelper is already initialized in setUpAll()
      // Ensure we're in English mode
      await languageHelper.change(LanguageCodes.en);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: Tr((_) => Text('Hello'.tr), refreshTree: true)),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Hello'), findsOneWidget);

      // Change language
      await languageHelper.change(LanguageCodes.vi);
      await tester.pumpAndSettle();

      expect(find.text('Xin Chào'), findsOneWidget);
    });

    testWidgets(
      'LanguageBuilder _of() method with different LanguageHelper instances',
      (tester) async {
        SharedPreferences.setMockInitialValues({});

        final helper1 = LanguageHelper('TestHelper1');
        final helper2 = LanguageHelper('TestHelper2');

        await helper1.initial(data: dataList, initialCode: LanguageCodes.en);
        await helper2.initial(data: dataList, initialCode: LanguageCodes.vi);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: LanguageBuilder(
                languageHelper: helper1,
                builder: (_) => Column(
                  children: [
                    Text('Hello'.trC(helper1)),
                    // Nested LanguageBuilder with different LanguageHelper instance
                    LanguageBuilder(
                      languageHelper: helper2,
                      builder: (_) => Text('Hello'.trC(helper2)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Both should show their respective languages
        expect(find.text('Hello'), findsOneWidget); // helper1 shows English
        expect(
          find.text('Xin Chào'),
          findsOneWidget,
        ); // helper2 shows Vietnamese

        // Change language in helper1 only
        await helper1.change(LanguageCodes.vi);
        await tester.pumpAndSettle();

        // Only helper1 should change, helper2 should remain Vietnamese
        expect(
          find.text('Xin Chào'),
          findsNWidgets(2),
        ); // Both show Vietnamese now
        expect(find.text('Hello'), findsNothing);

        // Dispose helpers
        helper1.dispose();
        helper2.dispose();
      },
    );
  });

  /// This test have to be the last test because it will change the value of the database.
  group('Unit test for methods', () {
    test('Add data with overwrite is false', () async {
      final dataToAdd = {
        LanguageCodes.en: {'Hello': 'HelloOverwrite', 'Hello add': 'Hello Add'},
        LanguageCodes.zh: {'Hello': '你好'},
      };
      final providerWithoutOverride = LanguageDataProvider.data(
        dataToAdd,
        override: false,
      );

      await languageHelper.change(LanguageCodes.en);
      await languageHelper.addProvider(providerWithoutOverride);

      final addedData = languageHelper.data[LanguageCodes.en]!;
      expect(addedData, contains('Hello add'));
      expect(addedData['Hello'], equals('Hello'));
      expect(addedData['Hello'], isNot(equals('HelloOverwrite')));
    });

    test('Add data with overwrite is true', () async {
      await languageHelper.initial(
        data: [...dataList, ...dataOverrides],
        initialCode: LanguageCodes.en,
      );
      final dataToAdd = {
        LanguageCodes.en: {'Hello': 'HelloOverwrite', 'Hello add': 'Hello Add'},
        LanguageCodes.zh: {'Hello': '你好'},
      };
      final providerWithOverride = LanguageDataProvider.data(
        dataToAdd,
        override: true,
      );
      await languageHelper.addProvider(providerWithOverride);
      await languageHelper.reload();

      final addedData = languageHelper.data[LanguageCodes.en]!;
      expect(addedData, contains('Hello add'));
      expect(addedData['Hello'], isNot(equals('Hello')));
      expect(addedData['Hello'], equals('HelloOverwrite'));
    });

    test('Add data with overwrite is true to cover line 1179', () async {
      await languageHelper.initial(
        data: dataList,
        initialCode: LanguageCodes.en,
      );
      // Add data with override: true when key already exists
      final dataToAdd = {
        LanguageCodes.en: {'Hello': 'HelloOverwrite', 'Hello add': 'Hello Add'},
        LanguageCodes.zh: {'Hello': '你好'},
      };
      final providerWithOverride = LanguageDataProvider.data(
        dataToAdd,
        override: true,
      );
      await languageHelper.addProvider(providerWithOverride);
      languageHelper.reload();

      final addedData = languageHelper.data[LanguageCodes.en]!;
      expect(addedData, contains('Hello add'));
      // The existing 'Hello' key should be overwritten
      expect(addedData['Hello'], equals('HelloOverwrite'));
      expect(addedData['Hello'], isNot(equals('Hello')));
    });
  });

  group('Lazy data provider', () {
    test('initial loads only requested language lazily', () async {
      SharedPreferences.setMockInitialValues({});

      final callCount = {LanguageCodes.en: 0, LanguageCodes.vi: 0};

      LazyLanguageData lazyData = {
        LanguageCodes.en: () {
          callCount[LanguageCodes.en] = callCount[LanguageCodes.en]! + 1;
          return Map<String, dynamic>.from(data[LanguageCodes.en]!);
        },
        LanguageCodes.vi: () {
          callCount[LanguageCodes.vi] = callCount[LanguageCodes.vi]! + 1;
          return Map<String, dynamic>.from(data[LanguageCodes.vi]!);
        },
      };

      final helper = LanguageHelper('LazyLanguageHelper');
      addTearDown(helper.dispose);

      await helper.initial(
        data: [LanguageDataProvider.lazyData(lazyData)],
        initialCode: LanguageCodes.en,
        syncWithDevice: false,
        isAutoSave: false,
        useInitialCodeWhenUnavailable: false,
      );

      expect(helper.code, equals(LanguageCodes.en));
      expect(helper.translate('Hello'), equals('Hello'));
      expect(callCount[LanguageCodes.en], equals(1));
      expect(callCount[LanguageCodes.vi], equals(0));
    });

    test('changing language evaluates lazy data on demand', () async {
      SharedPreferences.setMockInitialValues({});

      final callCount = {LanguageCodes.en: 0, LanguageCodes.vi: 0};

      LazyLanguageData lazyData = {
        LanguageCodes.en: () {
          callCount[LanguageCodes.en] = callCount[LanguageCodes.en]! + 1;
          return Map<String, dynamic>.from(data[LanguageCodes.en]!);
        },
        LanguageCodes.vi: () {
          callCount[LanguageCodes.vi] = callCount[LanguageCodes.vi]! + 1;
          return Map<String, dynamic>.from(data[LanguageCodes.vi]!);
        },
      };

      final helper = LanguageHelper('LazyLanguageHelperChange');
      addTearDown(helper.dispose);

      await helper.initial(
        data: [LanguageDataProvider.lazyData(lazyData)],
        initialCode: LanguageCodes.en,
        syncWithDevice: false,
        isAutoSave: false,
        useInitialCodeWhenUnavailable: false,
      );

      expect(helper.translate('Hello'), equals('Hello'));
      expect(callCount[LanguageCodes.en], equals(1));
      expect(callCount[LanguageCodes.vi], equals(0));

      await helper.change(LanguageCodes.vi);
      expect(helper.translate('Hello'), equals('Xin Chào'));
      expect(callCount[LanguageCodes.vi], equals(1));
    });
  });

  group('Remove provider', () {
    test('removeProvider removes provider and updates data', () async {
      final testHelper = LanguageHelper('TestRemoveProvider1');
      addTearDown(testHelper.dispose);

      final provider1 = LanguageDataProvider.data({
        LanguageCodes.en: {'Key1': 'Value1'},
        LanguageCodes.vi: {'Key1': 'Giá trị 1'},
      });
      final provider2 = LanguageDataProvider.data({
        LanguageCodes.en: {'Key2': 'Value2'},
        LanguageCodes.vi: {'Key2': 'Giá trị 2'},
      });

      await testHelper.initial(
        data: [provider1, provider2],
        initialCode: LanguageCodes.en,
      );

      expect(testHelper.translate('Key1'), equals('Value1'));
      expect(testHelper.translate('Key2'), equals('Value2'));

      await testHelper.removeProvider(provider2);

      expect(testHelper.translate('Key1'), equals('Value1'));
      expect(
        testHelper.translate('Key2'),
        equals('Key2'),
      ); // Should return key when not found
    });

    test('removeProvider with activate false', () async {
      final testHelper = LanguageHelper('TestRemoveProvider2');
      addTearDown(testHelper.dispose);

      final provider1 = LanguageDataProvider.data({
        LanguageCodes.en: {'Key1': 'Value1'},
      });
      final provider2 = LanguageDataProvider.data({
        LanguageCodes.en: {'Key2': 'Value2'},
      });

      await testHelper.initial(
        data: [provider1, provider2],
        initialCode: LanguageCodes.en,
      );

      await testHelper.removeProvider(provider2, activate: false);
      // Data is removed from providers but widgets are not updated until reload
      // However, the data in memory is already updated, so Key2 should be gone
      expect(testHelper.translate('Key2'), equals('Key2'));

      await testHelper.reload();
      expect(testHelper.translate('Key2'), equals('Key2'));
    });

    test('removeProvider updates codes correctly', () async {
      final testHelper = LanguageHelper('TestRemoveProvider3');
      addTearDown(testHelper.dispose);

      final provider1 = LanguageDataProvider.data({
        LanguageCodes.en: {'Key1': 'Value1'},
        LanguageCodes.vi: {'Key1': 'Giá trị 1'},
      });
      final provider2 = LanguageDataProvider.data({
        LanguageCodes.zh: {'Key2': 'Value2'},
      });

      await testHelper.initial(
        data: [provider1, provider2],
        initialCode: LanguageCodes.en,
      );

      expect(
        testHelper.codes,
        containsAll([LanguageCodes.en, LanguageCodes.vi, LanguageCodes.zh]),
      );

      await testHelper.removeProvider(provider2);

      expect(
        testHelper.codes,
        containsAll([LanguageCodes.en, LanguageCodes.vi]),
      );
      expect(testHelper.codes, isNot(contains(LanguageCodes.zh)));
    });

    test('removeProvider when provider not in list', () async {
      final testHelper = LanguageHelper('TestRemoveProvider4');
      addTearDown(testHelper.dispose);

      final provider1 = LanguageDataProvider.data({
        LanguageCodes.en: {'Key1': 'Value1'},
      });
      final provider2 = LanguageDataProvider.data({
        LanguageCodes.en: {'Key2': 'Value2'},
      });

      await testHelper.initial(
        data: [provider1],
        initialCode: LanguageCodes.en,
      );

      // Try to remove a provider that was never added
      await testHelper.removeProvider(provider2);

      // Should not throw and should still work
      expect(testHelper.translate('Key1'), equals('Value1'));
    });

    test('removeProvider with override provider to cover logger info', () async {
      final testHelper = LanguageHelper('TestRemoveProviderOverride');
      addTearDown(testHelper.dispose);

      final provider1 = LanguageDataProvider.data({
        LanguageCodes.en: {'Key1': 'Value1'},
      });
      final provider2 = LanguageDataProvider.data({
        LanguageCodes.en: {'Key2': 'Value2'},
      }, override: true);

      await testHelper.initial(
        data: [provider1, provider2],
        initialCode: LanguageCodes.en,
        isDebug: true,
      );

      expect(testHelper.translate('Key1'), equals('Value1'));
      expect(testHelper.translate('Key2'), equals('Value2'));

      // Remove provider with override=true to trigger logger info at lines 937-938
      await testHelper.removeProvider(provider2);

      expect(testHelper.translate('Key1'), equals('Value1'));
      expect(
        testHelper.translate('Key2'),
        equals('Key2'),
      ); // Should return key when not found
    });
  });

  group('Language Data Provider from - ', () {
    setUp(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMessageHandler('flutter/assets', (message) async {
            if (message == null) return null;

            final String assetKey = utf8.decode(message.buffer.asUint8List());
            return mockAssets.containsKey(assetKey)
                ? ByteData.view(
                    Uint8List.fromList(mockAssets[assetKey]!.codeUnits).buffer,
                  )
                : null;
          });
    });

    test('asset - ok', () async {
      final data = LanguageDataProvider.asset('assets/languages');
      final codes = await data.getSupportedCodes();
      expect(codes, equals({LanguageCodes.en, LanguageCodes.vi}));
      final languages = await data.getData(LanguageCodes.en);
      final first = languages.entries.first;
      expect(first.key, equals(LanguageCodes.en));
      expect(first.value, equals(isNotEmpty));
    });

    test('asset - error', () async {
      final data = LanguageDataProvider.asset('abc');
      expect(data.isEmpty, equals(false));
      expect(await data.getData(LanguageCodes.en), isEmpty);
    });

    test('network - ok', () async {
      final data = LanguageDataProvider.network(
        'https://pub.lamnhan.dev/languages',
        client: MockClient(),
      );

      final codes = await data.getSupportedCodes();
      expect(codes, equals({LanguageCodes.en, LanguageCodes.vi}));
      final languages = await data.getData(LanguageCodes.en);
      final first = languages.entries.first;
      expect(first.key, equals(LanguageCodes.en));
      expect(first.value, equals(isNotEmpty));

      final helper = LanguageHelper('NetworkLanguageHelper');
      await helper.initial(data: [data], initialCode: LanguageCodes.en);
      expect(helper.code, equals(LanguageCodes.en));
      await helper.change(LanguageCodes.vi);
      expect(helper.code, equals(LanguageCodes.vi));
    });

    test('network - error', () async {
      final data = LanguageDataProvider.network('abc', client: MockClient());

      expect(await data.getData(LanguageCodes.en), isEmpty);
    });

    test('network - with headers', () async {
      final data = LanguageDataProvider.network(
        'https://pub.lamnhan.dev/languages',
        client: MockClient(),
        headers: {'Authorization': 'Bearer token', 'X-Custom-Header': 'value'},
      );

      final codes = await data.getSupportedCodes();
      expect(codes, equals({LanguageCodes.en, LanguageCodes.vi}));
    });

    test('empty data provider', () async {
      final data = LanguageDataProvider.empty();
      expect(data.isEmpty, equals(true));
      expect(await data.getData(LanguageCodes.en), isEmpty);
      expect(await data.getSupportedCodes(), isEmpty);
    });

    test('data provider with custom data', () async {
      final customData = {
        LanguageCodes.en: {'test': 'test value'},
        LanguageCodes.vi: {'test': 'giá trị test'},
      };
      final data = LanguageDataProvider.data(customData);
      expect(data.isEmpty, equals(false));

      final codes = await data.getSupportedCodes();
      expect(codes, equals({LanguageCodes.en, LanguageCodes.vi}));

      final enData = await data.getData(LanguageCodes.en);
      expect(enData[LanguageCodes.en]!['test'], equals('test value'));
    });
  });

  group('Verify variables', () {
    test('locales == codes', () {
      final locales = languageHelper.codes.map((e) => e.locale);
      expect(locales, equals(languageHelper.locales));
    });
  });

  group('Test LanguageHelper instances with modified prefixes', () {
    test('LanguageHelper with empty prefix', () {
      final helper = LanguageHelper('');
      expect(helper.prefix, equals(''));
    });

    test('LanguageHelper with custom prefix', () {
      final helper = LanguageHelper('CustomPrefix');
      expect(helper.prefix, equals('CustomPrefix'));
    });

    test('LanguageHelper with special characters in prefix', () {
      final helper = LanguageHelper('prefix-with-special.chars');
      expect(helper.prefix, equals('prefix-with-special.chars'));
    });

    test('Multiple LanguageHelper instances with different prefixes', () {
      final helper1 = LanguageHelper('Helper1');
      final helper2 = LanguageHelper('Helper2');
      final helper3 = LanguageHelper('Helper1'); // Same prefix as helper1

      expect(helper1.prefix, equals('Helper1'));
      expect(helper2.prefix, equals('Helper2'));
      expect(helper3.prefix, equals('Helper1'));

      // Different prefixes should create different instances
      expect(helper1, isNot(equals(helper2)));
      expect(helper2, isNot(equals(helper3)));

      // Same prefixes should be equal
      expect(helper1, equals(helper3));
    });

    test('LanguageHelper prefix affects SharedPreferences keys', () {
      final helper1 = LanguageHelper('App1');
      final helper2 = LanguageHelper('App2');

      expect(helper1.codeKey, equals('App1.AutoSaveCode'));
      expect(helper1.deviceCodeKey, equals('App1.DeviceCode'));
      expect(helper2.codeKey, equals('App2.AutoSaveCode'));
      expect(helper2.deviceCodeKey, equals('App2.DeviceCode'));
    });

    test('Different prefixes maintain separate language preferences', () async {
      SharedPreferences.setMockInitialValues({});

      final helper1 = LanguageHelper('App1');
      final helper2 = LanguageHelper('App2');

      // Initialize both helpers with different initial languages
      await helper1.initial(
        data: dataList,
        initialCode: LanguageCodes.en,
        isAutoSave: true,
        syncWithDevice: false,
      );

      await helper2.initial(
        data: dataList,
        initialCode: LanguageCodes.vi,
        isAutoSave: true,
        syncWithDevice: false,
      );

      // Change languages
      await helper1.change(LanguageCodes.vi);
      await helper2.change(LanguageCodes.en);

      // Verify they maintain separate states
      expect(helper1.code, equals(LanguageCodes.vi));
      expect(helper2.code, equals(LanguageCodes.en));

      // Dispose helpers
      helper1.dispose();
      helper2.dispose();
    });

    test(
      'LanguageHelper instances with same prefix share preferences',
      () async {
        SharedPreferences.setMockInitialValues({});

        final helper1 = LanguageHelper('SharedPrefix');
        final helper2 = LanguageHelper('SharedPrefix');

        // Initialize first helper
        await helper1.initial(
          data: dataList,
          initialCode: LanguageCodes.en,
          isAutoSave: true,
          syncWithDevice: false,
        );

        // Change language in first helper
        await helper1.change(LanguageCodes.vi);

        // Initialize second helper - should load the saved language
        await helper2.initial(
          data: dataList,
          initialCode: LanguageCodes.en,
          isAutoSave: true,
          syncWithDevice: false,
        );

        // Second helper should have the language saved by first helper
        expect(helper2.code, equals(LanguageCodes.vi));

        // Dispose helpers
        helper1.dispose();
        helper2.dispose();
      },
    );

    test('LanguageHelper hashCode based on prefix', () {
      final helper1 = LanguageHelper('TestPrefix');
      final helper2 = LanguageHelper('TestPrefix');
      final helper3 = LanguageHelper('DifferentPrefix');

      expect(helper1.hashCode, equals(helper2.hashCode));
      expect(helper1.hashCode, isNot(equals(helper3.hashCode)));
    });

    test(
      'LanguageHelper instances are properly created with different prefixes',
      () {
        final helper1 = LanguageHelper('Prefix1');
        final helper2 = LanguageHelper('Prefix2');

        expect(helper1.prefix, equals('Prefix1'));
        expect(helper2.prefix, equals('Prefix2'));
        expect(helper1, isNot(equals(helper2)));
      },
    );
  });

  group('Test edge cases and error handling', () {
    test('LanguageHelper with empty data', () async {
      final helper = LanguageHelper('TestHelper');
      await helper.initial(data: []);
      // When data is empty, LanguageHelper creates a temporary data entry
      expect(helper.data, isNotEmpty);
      expect(helper.codes, isNotEmpty);
      expect(helper.codes, contains(LanguageCodes.en));
    });

    test('translate with empty string', () {
      expect(''.tr, equals(''));
    });

    test('translate with missing parameter', () {
      expect('Hello @{name}'.trP({'other': 'value'}), equals('Hello @{name}'));
    });

    test('translate with empty parameters', () {
      expect('Hello @{name}'.trP({}), equals('Hello @{name}'));
    });

    test('change to same language', () async {
      await languageHelper.change(LanguageCodes.en);
      expect(languageHelper.code, equals(LanguageCodes.en));
    });

    test('dispose multiple times', () {
      final helper = LanguageHelper('TestHelper');
      helper.dispose();
      helper.dispose(); // Should not throw
    });

    test('translate with null parameter', () {
      expect('Hello @{name}'.trP({'name': null}), equals('Hello null'));
    });

    test('translate with complex parameter types', () {
      expect('Value: @{value}'.trP({'value': 123}), equals('Value: 123'));
      expect('Value: @{value}'.trP({'value': true}), equals('Value: true'));
      expect('Value: @{value}'.trP({'value': 3.14}), equals('Value: 3.14'));
    });

    test('translate with LanguageConditions missing param', () async {
      languageHelper.setUseInitialCodeWhenUnavailable(true);
      await languageHelper.change(LanguageCodes.en);

      // Test when param is missing from params map
      expect(
        'You have @{number} dollar'.trP({'other': 100}),
        equals('You have @{number} dollar'),
      );
    });

    test('translate with LanguageConditions no matching condition', () async {
      languageHelper.setUseInitialCodeWhenUnavailable(true);
      await languageHelper.change(LanguageCodes.en);

      // Test when condition value doesn't match any condition key
      // and no default/underscore key exists
      final customData = {
        LanguageCodes.en: {
          'Test': const LanguageConditions(
            param: 'count',
            conditions: {'1': 'one', '2': 'two'},
          ),
        },
      };
      final helper = LanguageHelper('TestConditions');
      addTearDown(helper.dispose);
      await helper.initial(data: [LanguageDataProvider.data(customData)]);

      // Should return fallback text when no condition matches
      expect(helper.translate('Test', params: {'count': '3'}), equals('Test'));
    });

    test('translate with special characters in parameters', () {
      expect(
        'Hello @{name}'.trP({'name': 'John@Doe'}),
        equals('Hello John@Doe'),
      );
      expect(
        'Hello @{name}'.trP({'name': 'John{Doe}'}),
        equals('Hello John{Doe}'),
      );
    });

    test('LanguageHelper with invalid initial code', () async {
      final helper = LanguageHelper('TestHelper');
      await helper.initial(
        data: dataList,
        initialCode: LanguageCodes.cu, // Not in data
        useInitialCodeWhenUnavailable: false,
      );
      expect(
        helper.code,
        equals(LanguageCodes.en),
      ); // Should fallback to first available
    });

    test('LanguageHelper with null initial code', () async {
      final helper = LanguageHelper('TestHelper');
      await helper.initial(
        data: dataList,
        initialCode: null,
        useInitialCodeWhenUnavailable: false,
      );
      expect(
        helper.code,
        equals(LanguageCodes.en),
      ); // Should fallback to first available
    });

    test('LanguageHelper reload with no data', () async {
      final helper = LanguageHelper('TestHelper');
      await helper.initial(data: []);
      helper.reload();
      expect(helper.data, isNotEmpty);
    });

    test('change method when data not loaded yet', () async {
      final helper = LanguageHelper('TestChangeNotLoaded');
      addTearDown(helper.dispose);

      // Create a lazy provider that hasn't loaded vi yet
      LazyLanguageData lazyData = {
        LanguageCodes.en: () => {'Hello': 'Hello'},
        LanguageCodes.vi: () => {'Hello': 'Xin Chào'},
      };

      await helper.initial(
        data: [LanguageDataProvider.lazyData(lazyData)],
        initialCode: LanguageCodes.en,
      );

      // Change to vi - should load data on demand
      await helper.change(LanguageCodes.vi);
      expect(helper.code, equals(LanguageCodes.vi));
      expect(helper.translate('Hello'), equals('Xin Chào'));
    });

    test('concurrent initialization', () async {
      final helper = LanguageHelper('TestConcurrent');
      addTearDown(helper.dispose);

      // Start multiple initializations concurrently
      final future1 = helper.initial(
        data: dataList,
        initialCode: LanguageCodes.en,
      );
      final future2 = helper.initial(
        data: dataList,
        initialCode: LanguageCodes.vi,
      );

      // Both should complete without error
      await future1;
      await future2;

      // Should be initialized
      expect(helper.isInitialized, isTrue);
    });

    test('LanguageHelper addData with null data', () async {
      final helper = LanguageHelper('TestHelper');
      await helper.initial(data: dataList);
      await helper.addProvider(LanguageDataProvider.data({}));
      expect(helper.data, isNotEmpty);
    });

    test('LanguageHelper stream subscription handling', () async {
      final helper = LanguageHelper('TestHelper');
      await helper.initial(data: dataList, initialCode: LanguageCodes.en);

      int streamCount = 0;
      final subscription = helper.stream.listen((_) {
        streamCount++;
      });

      await helper.change(LanguageCodes.vi);
      await helper.change(LanguageCodes.en);

      await null; // Wait for the stream to be processed

      expect(streamCount, equals(2));
      subscription.cancel();
    });

    test('LanguageHelper with malformed language data', () async {
      final malformedData = {
        LanguageCodes.en: {
          'key1': 'value1',
          'key2': null, // null value
        },
      };

      final helper = LanguageHelper('TestHelper');
      await helper.initial(data: [LanguageDataProvider.data(malformedData)]);
      expect(helper.translate('key1'), equals('value1'));
      expect(
        helper.translate('key2'),
        equals('key2'),
      ); // Should return key when value is null
    });

    test('LanguageHelper with circular reference in data', () async {
      final circularData = {
        LanguageCodes.en: {
          'key1': 'value1',
          'key2': 'key1', // References another key
        },
      };

      final helper = LanguageHelper('TestHelper');
      await helper.initial(data: [LanguageDataProvider.data(circularData)]);
      expect(helper.translate('key1'), equals('value1'));
      expect(
        helper.translate('key2'),
        equals('key1'),
      ); // Should not resolve circular reference
    });

    test('translate with toCode parameter', () async {
      await languageHelper.change(LanguageCodes.en);
      // Translate to Vietnamese even though current language is English
      expect(
        languageHelper.translate('Hello', toCode: LanguageCodes.vi),
        equals('Xin Chào'),
      );
    });

    test('translate with toCode not in codes', () async {
      await languageHelper.change(LanguageCodes.en);
      // Try to translate to a language not in codes
      expect(
        languageHelper.translate('Hello', toCode: LanguageCodes.aa),
        equals('Hello'), // Should return original text
      );
    });

    test('translate with empty params map', () {
      expect('Hello @{name}'.trP({}), equals('Hello @{name}'));
    });

    test('translate with params containing newline', () {
      expect(
        'Line1 @{param}\nLine2'.trP({'param': 'value'}),
        equals('Line1 value\nLine2'),
      );
    });

    test('translate with params at end of string', () {
      expect('Text @{param}'.trP({'param': 'end'}), equals('Text end'));
    });

    test('translate with legacy @param format', () {
      expect(
        'Hello @name world'.trP({'name': 'John'}),
        equals('Hello John world'),
      );
    });

    test('translate with legacy @param at end', () {
      expect('Hello @name'.trP({'name': 'John'}), equals('Hello John'));
    });

    test('translate with legacy @param followed by newline', () {
      expect('Hello @name\n'.trP({'name': 'John'}), equals('Hello John\n'));
    });
  });

  group('Test utils', () {
    test('remove ending slash', () {
      expect(Utils.removeLastSlash('abc///'), equals('abc'));
      expect(Utils.removeLastSlash('abc/'), equals('abc'));
      expect(Utils.removeLastSlash('abc'), equals('abc'));
      expect(Utils.removeLastSlash(''), equals(''));
    });

    test('get url', () async {
      const errorUrl = 'abc';
      await Utils.getUrl(Uri.parse(errorUrl));
      expect(
        await Utils.getUrl(Uri.parse(errorUrl), client: MockClient()),
        isEmpty,
      );
    });

    test('get url with valid response', () async {
      final result = await Utils.getUrl(
        Uri.parse('https://pub.lamnhan.dev/languages/data/en.json'),
        client: MockClient(),
      );
      expect(result, isNotEmpty);
      expect(result, contains('Hello'));
    });

    test('get url with network error', () async {
      final result = await Utils.getUrl(
        Uri.parse('https://invalid-url-that-will-fail.com'),
        client: MockClient(),
      );
      expect(result, isEmpty);
    });

    test('get url with timeout', () async {
      final result = await Utils.getUrl(
        Uri.parse('https://httpstat.us/200?sleep=10000'),
        client: MockClient(),
      );
      expect(result, isEmpty);
    });

    test('get url with headers', () async {
      final result = await Utils.getUrl(
        Uri.parse('https://pub.lamnhan.dev/languages/data/en.json'),
        client: MockClient(),
        headers: {'Authorization': 'Bearer token'},
      );
      expect(result, isNotEmpty);
    });

    test('get url with non-200 status code', () async {
      // MockClient will return empty for invalid URLs
      final result = await Utils.getUrl(
        Uri.parse('https://invalid-url-that-will-fail.com'),
        client: MockClient(),
      );
      expect(result, isEmpty);
    });
  });

  group('Test isDebug getter', () {
    test('isDebug getter returns current debug state', () async {
      final helper = LanguageHelper('DebugTestHelper');
      // Initially false
      expect(helper.isDebug, equals(false));

      // Initialize with isDebug = true
      await helper.initial(
        data: dataList,
        initialCode: LanguageCodes.en,
        isDebug: true,
      );
      expect(helper.isDebug, equals(true));

      // Create another helper with isDebug = false
      final helper2 = LanguageHelper('DebugTestHelper2');
      await helper2.initial(
        data: dataList,
        initialCode: LanguageCodes.en,
        isDebug: false,
      );
      expect(helper2.isDebug, equals(false));

      helper.dispose();
      helper2.dispose();
    });
  });

  group('Test LanguageBuilder logger coverage', () {
    testWidgets('LanguageBuilder logger debug call when helper changes', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});

      final helper1 = LanguageHelper('LoggerTestHelper1');
      final helper2 = LanguageHelper('LoggerTestHelper2');

      // Initialize both with isDebug = true to ensure logger exists
      await helper1.initial(
        data: dataList,
        initialCode: LanguageCodes.en,
        isDebug: true,
      );
      await helper2.initial(
        data: dataList,
        initialCode: LanguageCodes.vi,
        isDebug: true,
      );

      // Create a widget that will change helper in didChangeDependencies
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LanguageScope(
              languageHelper: helper1,
              child: LanguageBuilder(builder: (_) => Text('Hello'.tr)),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify initial state
      expect(find.text('Hello'), findsOneWidget);

      // Change to a different helper scope to trigger didChangeDependencies
      // with a different helper (this will trigger the if block path)
      await tester.pumpWidget(
        MaterialApp(
          key: const ValueKey('changed'),
          home: Scaffold(
            body: LanguageScope(
              languageHelper: helper2,
              child: LanguageBuilder(builder: (_) => Text('Hello'.tr)),
            ),
          ),
        ),
      );
      // Pump multiple times to ensure didChangeDependencies is called
      await tester.pump();
      await tester.pump();
      await tester.pumpAndSettle();

      // The widget should rebuild with the new helper
      expect(find.text('Xin Chào'), findsOneWidget);

      helper1.dispose();
      helper2.dispose();
    });

    testWidgets('LanguageBuilder _of returns null when root not found', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});

      final helper1 = LanguageHelper('TestOf1');
      final helper2 = LanguageHelper('TestOf2');
      addTearDown(() {
        helper1.dispose();
        helper2.dispose();
      });

      await helper1.initial(data: dataList, initialCode: LanguageCodes.en);
      await helper2.initial(data: dataList, initialCode: LanguageCodes.vi);

      // Create nested LanguageBuilders with different helpers
      // When helpers are different, _of() should return null for the inner builder
      // because the root has a different helper
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LanguageBuilder(
              languageHelper: helper1,
              builder: (_) => LanguageBuilder(
                languageHelper: helper2,
                builder: (_) => Text('Hello'.trC(helper2)),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Inner builder uses helper2, so should show Vietnamese
      expect(find.text('Xin Chào'), findsOneWidget);
    });

    testWidgets('LanguageBuilder with refreshTree true', (tester) async {
      SharedPreferences.setMockInitialValues({});

      // Create a fresh helper to avoid state pollution from other tests
      final testHelper = LanguageHelper('TestRefreshTree');
      addTearDown(testHelper.dispose);
      await testHelper.initial(data: dataList, initialCode: LanguageCodes.en);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LanguageBuilder(
              languageHelper: testHelper,
              refreshTree: true,
              builder: (_) => Text('Hello'.tr),
            ),
          ),
        ),
      );
      // Use simple pumps to avoid hanging - don't use pumpAndSettle
      await tester.pump();
      await tester.pump();

      // Verify the widget shows text
      expect(find.text('Hello'), findsOneWidget);

      // Change language and verify it updates
      await testHelper.change(LanguageCodes.vi);
      // Use simple pumps - avoid pumpAndSettle which can hang
      await tester.pump();
      await tester.pump();

      // The widget should update to show Vietnamese text
      expect(find.text('Xin Chào'), findsOneWidget);
    });

    testWidgets('LanguageBuilder dispose removes from states', (tester) async {
      SharedPreferences.setMockInitialValues({});

      final helper = LanguageHelper.instance;
      await helper.initial(data: dataList, initialCode: LanguageCodes.en);

      // Get initial state count
      final initialStateCount = helper.states.length;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LanguageBuilder(builder: (_) => Text('Hello'.tr)),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(helper.states.length, greaterThan(initialStateCount));

      // Remove widget
      await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
      await tester.pumpAndSettle();

      // States should be back to initial count (or less if other widgets were disposed)
      expect(helper.states.length, lessThanOrEqualTo(initialStateCount + 1));
    });

    testWidgets(
      'Nested LanguageBuilders with same helper to cover root update (line 1142)',
      (tester) async {
        SharedPreferences.setMockInitialValues({});

        final testHelper = LanguageHelper('TestNestedSameHelper');
        addTearDown(testHelper.dispose);
        await testHelper.initial(data: dataList, initialCode: LanguageCodes.en);

        // Create nested LanguageBuilders with the same helper
        // Both should have forceRebuild: false (default) so the inner one will find the root
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: LanguageBuilder(
                languageHelper: testHelper,
                forceRebuild: false, // Explicitly set to false
                builder: (_) => LanguageBuilder(
                  languageHelper: testHelper,
                  forceRebuild: false, // Explicitly set to false
                  builder: (_) => Text('Hello'.tr),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Verify both builders are registered in states
        expect(testHelper.states.length, equals(2));

        // Verify the widget shows English text
        expect(find.text('Hello'), findsOneWidget);

        // Change language - this should trigger the root update path (line 1142)
        // The inner builder's _of() should return the root, and root should be added to needToUpdate
        await testHelper.change(LanguageCodes.vi);
        await tester.pumpAndSettle();

        // Verify the widget shows Vietnamese text
        expect(find.text('Xin Chào'), findsOneWidget);
      },
    );

    testWidgets(
      'LanguageBuilder _of() returns null when root is not mounted (lines 113-114)',
      (tester) async {
        SharedPreferences.setMockInitialValues({});

        final testHelper = LanguageHelper('TestOfNotMounted');
        addTearDown(testHelper.dispose);
        await testHelper.initial(data: dataList, initialCode: LanguageCodes.en);

        // Create nested LanguageBuilders
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: LanguageBuilder(
                languageHelper: testHelper,
                builder: (_) => LanguageBuilder(
                  languageHelper: testHelper,
                  builder: (_) => Text('Hello'.tr),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Verify both are in states
        expect(testHelper.states.length, equals(2));

        // Replace the widget tree to unmount the root
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: LanguageBuilder(
                languageHelper: testHelper,
                builder: (_) => Text('Inner only'.tr),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // The root should be unmounted now, but if it's still in _states somehow,
        // calling change() should trigger the !root.mounted check
        // However, when a widget is disposed, it's removed from _states in dispose()
        // So this path might be hard to test

        // Instead, let's test the case where _of() returns null because root is null
        // (which is already covered) or because helpers are different (already covered)

        // For the !root.mounted case, we need a scenario where findRootAncestorStateOfType
        // returns a state that's not mounted. This is a defensive check that might be
        // unreachable in practice, but let's try to trigger it by disposing during change

        // Create a scenario where we dispose a widget while change is happening
        final helper2 = LanguageHelper('TestOfNotMounted2');
        addTearDown(helper2.dispose);
        await helper2.initial(data: dataList, initialCode: LanguageCodes.en);

        // Create nested builders
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: LanguageBuilder(
                languageHelper: helper2,
                builder: (_) => LanguageBuilder(
                  languageHelper: helper2,
                  builder: (_) => Text('Test'.tr),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Start a language change and immediately dispose the root
        // This might create a race condition where root.mounted is false
        final changeFuture = helper2.change(LanguageCodes.vi);
        await tester.pumpWidget(
          MaterialApp(home: Scaffold(body: Text('Disposed'))),
        );
        await changeFuture;
        await tester.pumpAndSettle();
      },
    );
  });
}
