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

  test('Test with empty data', () async {
    await languageHelper.initial(data: []);
    expect(languageHelper.code, equals(LanguageCodes.en));
  });

  group('Test with SharedPreferences', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({
        languageHelper.codeKey: LanguageCodes.vi.code,
      });
      await languageHelper.initial(
        data: dataList,
        analysisKeys: languageHelper.data.entries.first.value.keys.toSet(),
        useInitialCodeWhenUnavailable: false,
        isDebug: true,
        onChanged: (value) {
          expect(value, isA<LanguageCodes>());
        },
      );
    });
    test('Get language from prefs', () {
      expect(languageHelper.code, equals(LanguageCodes.vi));
    });
  });

  group('Test without SharedPreferences', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await languageHelper.initial(
        data: dataList,
        useInitialCodeWhenUnavailable: false,
        isDebug: true,
        isAutoSave: false,
        onChanged: (value) {
          expect(value, isA<LanguageCodes>());
        },
      );
    });
    test('Get language from prefs and is available in LanguageData', () {
      expect(languageHelper.code, equals(LanguageCodes.en));
    });
  });

  group('Test without SharedPreferences', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
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
    });
    test('Get language from prefs and is unavailable in LanguageData', () {
      expect(languageHelper.code, equals(LanguageCodes.en));
    });
  });

  group('Test for analyzing missed key', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await languageHelper.initial(
        data: dataList,
        analysisKeys: analysisMissedKeys,
        initialCode: LanguageCodes.cu,
        useInitialCodeWhenUnavailable: false,
        isAutoSave: false,
        isDebug: true,
        onChanged: (value) {
          expect(value, isA<LanguageCodes>());
        },
      );
    });

    test('', () {
      expect(languageHelper.analyze(), contains('The below keys were missing'));
    });
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
          languageHelper.code, equals(languageHelper.data.entries.first.key));
    });
  });

  group('Test for [codes]', () {
    tearDown(() {
      LanguageCode.setTestCode();
    });

    test('[data] has more LanguageCodes than [dataOverrides]', () async {
      final LanguageData dataOverrides = {
        LanguageCodes.vi: {},
        LanguageCodes.en: {},
        LanguageCodes.cu: {},
      };
      final LanguageData data = {
        LanguageCodes.vi: {},
        LanguageCodes.en: {},
      };

      await languageHelper.initial(
        data: [LanguageDataProvider.data(data)],
        dataOverrides: [LanguageDataProvider.data(dataOverrides)],
        useInitialCodeWhenUnavailable: false,
        isAutoSave: false,
        isDebug: true,
        onChanged: (value) {
          expect(value, isA<LanguageCodes>());
        },
      );
      expect(languageHelper.codes, equals(dataOverrides.keys));
    });

    test('[dataOverrides] has more LanguageCodes than [data]', () async {
      final LanguageData data = {
        LanguageCodes.vi: {},
        LanguageCodes.en: {},
        LanguageCodes.cu: {},
      };
      final LanguageData dataOverrides = {
        LanguageCodes.vi: {},
        LanguageCodes.en: {},
      };

      await languageHelper.initial(
        data: [LanguageDataProvider.data(data)],
        dataOverrides: [LanguageDataProvider.data(dataOverrides)],
        useInitialCodeWhenUnavailable: false,
        isAutoSave: false,
        isDebug: true,
        onChanged: (value) {
          expect(value, isA<LanguageCodes>());
        },
      );

      expect(languageHelper.codes, equals(data.keys));
    });
  });

  group('Test for analyzing deprecated key', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await languageHelper.initial(
        data: dataList,
        analysisKeys: analysisRemovedKeys.toSet(),
        initialCode: LanguageCodes.cu,
        useInitialCodeWhenUnavailable: false,
        isAutoSave: false,
        isDebug: true,
        onChanged: (value) {
          expect(value, isA<LanguageCodes>());
        },
      );
    });

    test('', () {
      expect(
          languageHelper.analyze(), contains('The below keys were deprecated'));
    });
  });

  group('Test for using initial code when the `toCode` is unavailable', () {
    test('true', () async {
      SharedPreferences.setMockInitialValues({});
      await languageHelper.initial(
        data: dataList,
        initialCode: LanguageCodes.en,
        useInitialCodeWhenUnavailable: true,
        onChanged: (code) {},
      );
      languageHelper.change(LanguageCodes.vi);
      expect(languageHelper.code, equals(LanguageCodes.vi));

      languageHelper.change(LanguageCodes.cu);
      expect(languageHelper.code, equals(LanguageCodes.en));
    });

    test('false', () async {
      SharedPreferences.setMockInitialValues({});
      await languageHelper.initial(
        data: dataList,
        initialCode: LanguageCodes.en,
        useInitialCodeWhenUnavailable: false,
      );
      languageHelper.change(LanguageCodes.vi);
      expect(languageHelper.code, equals(LanguageCodes.vi));

      languageHelper.change(LanguageCodes.cu);
      expect(languageHelper.code, equals(LanguageCodes.vi));
    });

    test('true but initial code is null', () async {
      SharedPreferences.setMockInitialValues({});
      await languageHelper.initial(
        data: dataList,
        useInitialCodeWhenUnavailable: false,
      );
      languageHelper.change(LanguageCodes.vi);
      expect(languageHelper.code, equals(LanguageCodes.vi));

      languageHelper.change(LanguageCodes.cu);
      expect(languageHelper.code, equals(LanguageCodes.vi));
    });
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
  });

  group('Test base translation', () {
    setUp(() {
      languageHelper.setUseInitialCodeWhenUnavailable(false);
      languageHelper.change(LanguageCodes.en);
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

      expect('You have @number dollars'.trP({'number': '100'}),
          equals('You have 100 dollars'));
    });

    test('Test with vi language', () {
      languageHelper.change(LanguageCodes.vi);

      expect('Hello'.tr, equals('Xin Chào'));

      expect('You have @number dollars'.trP({'number': '100'}),
          equals('Bạn có 100 đô-la'));
    });

    test('Test with the code that does not in the data', () {
      expect('Hello There'.trT(LanguageCodes.aa), equals('Hello There'));
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
      expect('There are @number people in your family'.trP({'number': 100}),
          equals('There are 100 people in your family'));
      expect('There are @number people in your family'.trP({'non_number': 100}),
          equals('There are @number people in your family'));

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

    test('Test trT', () {
      languageHelper.change(LanguageCodes.en);

      expect('Hello'.trT(LanguageCodes.vi), equals('Xin Chào'));
    });
  });

  group('Test LanguageConditions', () {
    late LanguageConditions conditions;
    setUp(() {
      conditions = LanguageConditions(param: 'number', conditions: {
        '0': '0 dollar',
        '1': '1 dollar',
        'default': '@number dollars',
      });
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
  });

  group('dataOverrides', () {
    test('not using dataOverrides', () async {
      await languageHelper.initial(data: dataList);
      languageHelper.change(LanguageCodes.en);

      final errorTranslated =
          'You have @{number} dollar in your wallet'.trP({'number': 2});
      expect(errorTranslated, 'You have 2 dollar in your wallet');
    });
    test('using dataOverrides', () async {
      await languageHelper.initial(
          data: dataList, dataOverrides: dataOverrides);
      languageHelper.change(LanguageCodes.en);

      final translated =
          'You have @{number} dollar in your wallet'.trP({'number': 2});
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
  });

  group('Test `syncWithDevice`', () {
    test('false', () async {
      SharedPreferences.setMockInitialValues({
        languageHelper.deviceCodeKey: LanguageCodes.vi.code,
      });
      LanguageCode.setTestCode(LanguageCodes.en);
      await languageHelper.initial(
        data: dataList,
        initialCode: LanguageCodes.vi,
        syncWithDevice: false,
      );

      expect(languageHelper.code, equals(LanguageCodes.vi));
    });

    test('true and haven\'t local database', () async {
      SharedPreferences.setMockInitialValues({});
      LanguageCode.setTestCode(LanguageCodes.en);
      await languageHelper.initial(
        data: dataList,
        initialCode: LanguageCodes.vi,
        syncWithDevice: true,
      );

      expect(languageHelper.code, equals(LanguageCodes.vi));
    });

    test(
        'true, the `languageCode_countryCode` not available in local database but the `languageCode` only is available and isOptionalCountryCode is true',
        () async {
      SharedPreferences.setMockInitialValues({});
      LanguageCode.setTestCode(LanguageCodes.zh_TW);
      await languageHelper.initial(
        data: dataAdds,
        syncWithDevice: true,
      );

      expect(languageHelper.code, equals(LanguageCodes.zh));
    });

    test(
        'true, the `languageCode_countryCode` not available in local database but the `languageCode` only is available and isOptionalCountryCode is false',
        () async {
      SharedPreferences.setMockInitialValues({});
      LanguageCode.setTestCode(LanguageCodes.zh_TW);
      await languageHelper.initial(
        data: dataAdds,
        syncWithDevice: true,
        isOptionalCountryCode: false,
      );

      expect(languageHelper.code, equals(LanguageCodes.en));
    });

    test('true and have local database but with no changed code', () async {
      SharedPreferences.setMockInitialValues({
        languageHelper.deviceCodeKey: LanguageCodes.vi.code,
      });
      LanguageCode.setTestCode(LanguageCodes.vi);
      await languageHelper.initial(
        data: dataList,
        initialCode: LanguageCodes.vi,
        syncWithDevice: true,
      );

      expect(languageHelper.code, equals(LanguageCodes.vi));
    });

    test('true and have local database but with changed code', () async {
      SharedPreferences.setMockInitialValues({
        languageHelper.deviceCodeKey: LanguageCodes.vi.code,
      });
      LanguageCode.setTestCode(LanguageCodes.en);
      await languageHelper.initial(
        data: dataList,
        initialCode: LanguageCodes.vi,
        syncWithDevice: true,
      );

      expect(languageHelper.code, equals(LanguageCodes.en));
    });
  });

  group('Test widget', () {
    testWidgets('LanguageBuilder', (tester) async {
      // Use en as default language
      SharedPreferences.setMockInitialValues({});
      await languageHelper.initial(
          data: dataList, initialCode: LanguageCodes.en);

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

    testWidgets('Tr', (tester) async {
      // Use en as default language
      SharedPreferences.setMockInitialValues({});
      await languageHelper.initial(
          data: dataList, initialCode: LanguageCodes.en);

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

    test('export json', () {
      final dir = Directory('./test/export_json');
      data.exportJson(dir.path);
      final codesFile = File('./test/export_json/language_helper/codes.json');
      final codesJson = codesFile.readAsStringSync();
      expect(jsonDecode(codesJson), isA<List>());
      expect(jsonDecode(codesJson), isNotEmpty);
      dir.deleteSync(recursive: true);
    });
  });

  /// This test have to be the last test because it will change the value of the database.
  group('Unit test for methods', () {
    test('Add data with overwrite is false', () async {
      await languageHelper.addData(dataAdd, overwrite: false);
      languageHelper.reload();

      final addedData = languageHelper.data[LanguageCodes.en]!;
      expect(addedData, contains('Hello add'));
      expect(addedData['Hello'], equals('Hello'));
      expect(addedData['Hello'], isNot(equals('HelloOverwrite')));
    });

    test('Add data with overwrite is true', () async {
      await languageHelper.initial(
        data: dataList,
        dataOverrides: dataOverrides,
        initialCode: LanguageCodes.en,
      );
      await languageHelper.addDataOverrides(dataAdd, overwrite: true);
      languageHelper.reload();

      final addedData = languageHelper.dataOverrides[LanguageCodes.en]!;
      expect(addedData, contains('Hello add'));
      expect(addedData['Hello'], isNot(equals('Hello')));
      expect(addedData['Hello'], equals('HelloOverwrite'));
    });
  });

  group('Language Data Provider from - ', () {
    setUp(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMessageHandler(
        'flutter/assets',
        (message) async {
          if (message == null) return null;

          final String assetKey = utf8.decode(message.buffer.asUint8List());
          return mockAssets.containsKey(assetKey)
              ? ByteData.view(
                  Uint8List.fromList(mockAssets[assetKey]!.codeUnits).buffer)
              : null;
        },
      );
    });

    test('asset - ok', () async {
      final data = LanguageDataProvider.asset('assets');
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
        'https://pub.lamnhan.dev',
        client: MockClient(),
      );

      final codes = await data.getSupportedCodes();
      expect(codes, equals({LanguageCodes.en, LanguageCodes.vi}));
      final languages = await data.getData(LanguageCodes.en);
      final first = languages.entries.first;
      expect(first.key, equals(LanguageCodes.en));
      expect(first.value, equals(isNotEmpty));
    });

    test('network - error', () async {
      final data = LanguageDataProvider.network(
        'abc',
        client: MockClient(),
      );

      expect(await data.getData(LanguageCodes.en), isEmpty);
    });
  });

  group('Verify variables', () {
    test('locales == codes', () {
      final locales = languageHelper.codes.map((e) => e.locale);
      expect(locales, equals(languageHelper.locales));
    });
  });

  group('Test utils', () {
    test('remove ending slash', () {
      expect(Utils.removeLastSlash('abc///'), equals('abc'));
    });
    test('get url', () async {
      const errorUrl = 'abc';
      await Utils.getUrl(Uri.parse(errorUrl));
      expect(
        await Utils.getUrl(Uri.parse(errorUrl), client: MockClient()),
        isEmpty,
      );
    });
  });
}
