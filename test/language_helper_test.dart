import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:language_code/language_code.dart';
import 'package:language_helper/language_helper.dart';
import 'package:language_helper/src/mixins/update_language.dart';
import 'package:language_helper/src/utils/print_debug.dart';
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
    isTestingDebugLog = true;
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
      final LanguageData dataOverrides = {
        LanguageCodes.vi: {},
        LanguageCodes.en: {},
        LanguageCodes.cu: {},
      };
      final LanguageData data = {LanguageCodes.vi: {}, LanguageCodes.en: {}};

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
        languageHelper.analyze(),
        contains('The below keys were deprecated'),
      );
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

      expect(
        'You have @number dollars'.trP({'number': '100'}),
        equals('You have 100 dollars'),
      );
    });

    test('Test with vi language', () {
      languageHelper.change(LanguageCodes.vi);

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
      () {
        languageHelper.change(LanguageCodes.vi);
        languageHelper.setUseInitialCodeWhenUnavailable(false);
        languageHelper.change(LanguageCodes.cu);

        expect('Hello'.tr, equals('Xin Chào'));

        expect(
          'You have @number dollars'.trP({'number': '100'}),
          equals('Bạn có 100 đô-la'),
        );
      },
    );

    test(
      'Test with undefined language when useInitialCodeWhenUnavailable = true',
      () {
        languageHelper.setUseInitialCodeWhenUnavailable(true);
        languageHelper.change(LanguageCodes.cu);

        expect('Hello'.tr, equals('Hello'));

        expect(
          'You have @number dollars'.trP({'number': '100'}),
          equals('You have 100 dollars'),
        );
      },
    );

    test('Translate with parameters in multiple cases of text', () {
      languageHelper.setUseInitialCodeWhenUnavailable(true);
      languageHelper.change(LanguageCodes.en);

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

    test('Translate with condition', () {
      languageHelper.setUseInitialCodeWhenUnavailable(true);
      languageHelper.change(LanguageCodes.en);

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

      languageHelper.change(LanguageCodes.vi);
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

    test('Test trT', () {
      languageHelper.change(LanguageCodes.en);

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
      await languageHelper.initial(data: dataList);
      languageHelper.change(LanguageCodes.en);

      final errorTranslated = 'You have @{number} dollar in your wallet'.trP({
        'number': 2,
      });
      expect(errorTranslated, 'You have 2 dollar in your wallet');
    });
    test('using dataOverrides', () async {
      await languageHelper.initial(
        data: dataList,
        dataOverrides: dataOverrides,
      );
      languageHelper.change(LanguageCodes.en);

      final translated = 'You have @{number} dollar in your wallet'.trP({
        'number': 2,
      });
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
        await languageHelper.initial(data: dataAdds, syncWithDevice: true);

        expect(languageHelper.code, equals(LanguageCodes.zh));
      },
    );

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
      },
    );

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
        data: dataList,
        initialCode: LanguageCodes.en,
      );

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
        data: dataList,
        initialCode: LanguageCodes.en,
      );

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

      helper.change(LanguageCodes.vi);
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
              builder:
                  (_) => Column(
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
  });
}
