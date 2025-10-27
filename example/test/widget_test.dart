import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:language_helper/language_helper.dart';
import 'package:language_helper_example/main.dart';

void main() {
  group('Language Helper Example Tests', () {
    testWidgets('App should start and show home page', (tester) async {
      // Build our app and trigger a frame.
      await tester.pumpWidget(const LanguageHelperDemoApp());

      // Verify that the app title is displayed
      expect(find.text('Language Helper Demo'), findsOneWidget);
    });

    testWidgets('Language switching should work', (tester) async {
      await tester.pumpWidget(const LanguageHelperDemoApp());

      // Wait for the app to initialize
      await tester.pumpAndSettle();

      // Find the language menu button
      final languageButton = find.byIcon(Icons.language);
      expect(languageButton, findsOneWidget);

      // Tap the language button
      await tester.tap(languageButton);
      await tester.pumpAndSettle();

      // Check if language options are available
      expect(find.text('English'), findsOneWidget);
      expect(find.text('Vietnamese'), findsOneWidget);
    });

    testWidgets('Bottom navigation should work', (tester) async {
      await tester.pumpWidget(const LanguageHelperDemoApp());
      await tester.pumpAndSettle();

      // Test Dart Map Example tab
      await tester.tap(find.text('Dart Map Example'));
      await tester.pumpAndSettle();
      expect(find.text('Dart Map Data Source'), findsOneWidget);

      // Test JSON Asset Example tab
      await tester.tap(find.text('JSON Asset Example'));
      await tester.pumpAndSettle();
      expect(find.text('JSON Asset Data Source'), findsOneWidget);

      // Test Network Data Example tab
      await tester.tap(find.text('Network Data Example'));
      await tester.pumpAndSettle();
      expect(find.text('Network Data Source'), findsOneWidget);

      // Test Multiple Sources Example tab
      await tester.tap(find.text('Multiple Sources Example'));
      await tester.pumpAndSettle();
      expect(find.text('Multiple Data Sources'), findsOneWidget);

      // Test Advanced Features tab
      await tester.tap(find.text('Advanced Features'));
      await tester.pumpAndSettle();
      expect(find.text('Advanced Language Features'), findsOneWidget);
    });

    testWidgets('Translation examples should display correctly', (
      tester,
    ) async {
      await tester.pumpWidget(const LanguageHelperDemoApp());
      await tester.pumpAndSettle();

      // Check if translation examples are displayed
      expect(find.text('Simple Translation'), findsOneWidget);
      expect(find.text('Parameter Translation'), findsOneWidget);
      expect(find.text('Conditional Translation'), findsOneWidget);
    });

    testWidgets('Language statistics should be displayed', (tester) async {
      await tester.pumpWidget(const LanguageHelperDemoApp());
      await tester.pumpAndSettle();

      // Check if language statistics are displayed
      expect(find.text('Language Statistics'), findsOneWidget);
      expect(find.text('Current language'), findsOneWidget);
      expect(find.text('Supported Languages'), findsOneWidget);
    });
  });

  group('Language Helper Integration Tests', () {
    testWidgets('LanguageHelper should initialize correctly', (tester) async {
      // Test that LanguageHelper can be initialized
      final languageHelper = LanguageHelper('TestHelper');

      expect(languageHelper.isInitialized, false);

      // Initialize with test data
      await languageHelper.initial(
        data: [
          LanguageDataProvider.lazyData({
            LanguageCodes.en: () => {'Hello': 'Hello'},
            LanguageCodes.vi: () => {'Hello': 'Xin chào'},
          }),
        ],
      );

      expect(languageHelper.isInitialized, true);
      expect(languageHelper.codes, contains(LanguageCodes.en));
      expect(languageHelper.codes, contains(LanguageCodes.vi));
    });

    testWidgets('Translation should work with parameters', (tester) async {
      final languageHelper = LanguageHelper('TestHelper');

      await languageHelper.initial(
        data: [
          LanguageDataProvider.lazyData({
            LanguageCodes.en:
                () => {
                  'Hello @{name}': 'Hello @{name}',
                  'You have @{count} item': const LanguageConditions(
                    param: 'count',
                    conditions: {
                      '0': 'You have no items',
                      '1': 'You have one item',
                      '_': 'You have @{count} items',
                    },
                  ),
                },
          }),
        ],
      );

      // Test simple parameter translation
      expect(
        'Hello @{name}'.trC(languageHelper, params: {'name': 'World'}),
        'Hello World',
      );

      // Test conditional translation
      expect(
        'You have @{count} item'.trC(languageHelper, params: {'count': 0}),
        'You have no items',
      );
      expect(
        'You have @{count} item'.trC(languageHelper, params: {'count': 1}),
        'You have one item',
      );
      expect(
        'You have @{count} item'.trC(languageHelper, params: {'count': 5}),
        'You have 5 items',
      );
    });

    testWidgets('Language change should trigger rebuilds', (tester) async {
      final languageHelper = LanguageHelper('TestHelper');

      await languageHelper.initial(
        data: [
          LanguageDataProvider.lazyData({
            LanguageCodes.en: () => {'Hello': 'Hello'},
            LanguageCodes.vi: () => {'Hello': 'Xin chào'},
          }),
        ],
      );

      // Test language change
      expect(languageHelper.code, LanguageCodes.en);
      expect('Hello'.trC(languageHelper), 'Hello');

      await languageHelper.change(LanguageCodes.vi);
      expect(languageHelper.code, LanguageCodes.vi);
      expect('Hello'.trC(languageHelper), 'Xin chào');
    });
  });
}
