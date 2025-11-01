import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:language_helper/language_helper.dart';
import 'package:language_helper/src/utils/print_debug.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'language_data.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    isTestingDebugLog = true;
  });

  group('Test LanguageScope -', () {
    testWidgets('LanguageScope.of returns scoped helper', (tester) async {
      SharedPreferences.setMockInitialValues({});

      final scopedHelper = LanguageHelper('ScopedHelper');
      await scopedHelper.initial(data: dataList, initialCode: LanguageCodes.vi);

      LanguageHelper? retrievedHelper;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LanguageScope(
              languageHelper: scopedHelper,
              child: LanguageBuilder(
                builder: (context) {
                  retrievedHelper = LanguageScope.of(context);
                  return Text('Hello'.tr);
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(retrievedHelper, equals(scopedHelper));
      expect(find.text('Xin Chào'), findsOneWidget);
      expect(find.text('Hello'), findsNothing);

      scopedHelper.dispose();
    });

    testWidgets('LanguageScope.of falls back to instance when no scope', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});

      final languageHelper = LanguageHelper.instance;
      await languageHelper.initial(
        data: dataList,
        initialCode: LanguageCodes.en,
      );

      LanguageHelper? retrievedHelper;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                retrievedHelper = LanguageScope.of(context);
                return Text('Hello'.tr);
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(retrievedHelper, equals(LanguageHelper.instance));
      expect(find.text('Hello'), findsOneWidget);
    });

    testWidgets('LanguageScope.maybeOf returns scoped helper', (tester) async {
      SharedPreferences.setMockInitialValues({});

      final scopedHelper = LanguageHelper('ScopedHelper');
      await scopedHelper.initial(data: dataList, initialCode: LanguageCodes.vi);

      LanguageHelper? retrievedHelper;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LanguageScope(
              languageHelper: scopedHelper,
              child: LanguageBuilder(
                builder: (context) {
                  retrievedHelper = LanguageScope.maybeOf(context);
                  return Text('Hello'.tr);
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(retrievedHelper, equals(scopedHelper));
      expect(find.text('Xin Chào'), findsOneWidget);

      scopedHelper.dispose();
    });

    testWidgets('LanguageScope.maybeOf returns null when no scope', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});

      final languageHelper = LanguageHelper.instance;
      await languageHelper.initial(
        data: dataList,
        initialCode: LanguageCodes.en,
      );

      LanguageHelper? retrievedHelper;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                retrievedHelper = LanguageScope.maybeOf(context);
                return Text('Hello'.tr);
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(retrievedHelper, isNull);
      expect(find.text('Hello'), findsOneWidget);
    });

    testWidgets('Nested LanguageScope - child overrides parent', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});

      final parentHelper = LanguageHelper('ParentHelper');
      final childHelper = LanguageHelper('ChildHelper');
      await parentHelper.initial(data: dataList, initialCode: LanguageCodes.en);
      await childHelper.initial(data: dataList, initialCode: LanguageCodes.vi);

      LanguageHelper? parentRetrieved;
      LanguageHelper? childRetrieved;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LanguageScope(
              languageHelper: parentHelper,
              child: LanguageBuilder(
                builder: (parentContext) {
                  parentRetrieved = LanguageScope.of(parentContext);
                  return LanguageScope(
                    languageHelper: childHelper,
                    child: LanguageBuilder(
                      builder: (childContext) {
                        childRetrieved = LanguageScope.of(childContext);
                        return Text('Hello'.tr);
                      },
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(parentRetrieved, equals(parentHelper));
      expect(childRetrieved, equals(childHelper));
      expect(find.text('Xin Chào'), findsOneWidget); // Child scope is used

      parentHelper.dispose();
      childHelper.dispose();
    });

    testWidgets('LanguageBuilder inherits from LanguageScope', (tester) async {
      SharedPreferences.setMockInitialValues({});

      final scopedHelper = LanguageHelper('ScopedHelper');
      await scopedHelper.initial(data: dataList, initialCode: LanguageCodes.vi);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LanguageScope(
              languageHelper: scopedHelper,
              child: LanguageBuilder(builder: (_) => Text('Hello'.tr)),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Should use scoped helper (Vietnamese)
      expect(find.text('Xin Chào'), findsOneWidget);
      expect(find.text('Hello'), findsNothing);

      // Change language in scoped helper
      await scopedHelper.change(LanguageCodes.en);
      await tester.pumpAndSettle();

      expect(find.text('Hello'), findsOneWidget);
      expect(find.text('Xin Chào'), findsNothing);

      scopedHelper.dispose();
    });

    testWidgets(
      'LanguageBuilder priority: explicit > LanguageScope > instance',
      (tester) async {
        SharedPreferences.setMockInitialValues({});

        final explicitHelper = LanguageHelper('ExplicitHelper');
        final scopedHelper = LanguageHelper('ScopedHelper');
        await explicitHelper.initial(
          data: dataList,
          initialCode: LanguageCodes.en,
        );
        await scopedHelper.initial(
          data: dataList,
          initialCode: LanguageCodes.vi,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: LanguageScope(
                languageHelper: scopedHelper,
                child: LanguageBuilder(
                  // Explicit helper should take priority over scope
                  languageHelper: explicitHelper,
                  builder: (_) => Text('Hello'.tr),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Should use explicit helper (English)
        expect(find.text('Hello'), findsOneWidget);
        expect(find.text('Xin Chào'), findsNothing);

        explicitHelper.dispose();
        scopedHelper.dispose();
      },
    );

    testWidgets('Tr widget inherits from LanguageScope', (tester) async {
      SharedPreferences.setMockInitialValues({});

      final scopedHelper = LanguageHelper('ScopedHelper');
      await scopedHelper.initial(data: dataList, initialCode: LanguageCodes.vi);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LanguageScope(
              languageHelper: scopedHelper,
              child: Tr((_) => Text('Hello'.tr)),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Should use scoped helper (Vietnamese)
      expect(find.text('Xin Chào'), findsOneWidget);
      expect(find.text('Hello'), findsNothing);

      scopedHelper.dispose();
    });

    testWidgets(
      'Extension methods tr, trP use scoped helper in LanguageBuilder',
      (tester) async {
        SharedPreferences.setMockInitialValues({});

        final scopedHelper = LanguageHelper('ScopedHelper');
        await scopedHelper.initial(
          data: dataList,
          initialCode: LanguageCodes.vi,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: LanguageScope(
                languageHelper: scopedHelper,
                child: LanguageBuilder(
                  builder: (_) => Column(
                    children: [
                      Text('Hello'.tr),
                      Text('You have @number dollars'.trP({'number': 100})),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Should use scoped helper (Vietnamese)
        expect(find.text('Xin Chào'), findsOneWidget);
        expect(find.text('Bạn có 100 đô-la'), findsOneWidget);
        expect(find.text('Hello'), findsNothing);
        expect(find.text('You have 100 dollars'), findsNothing);

        scopedHelper.dispose();
      },
    );

    testWidgets('Extension methods trT uses scoped helper in LanguageBuilder', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});

      final scopedHelper = LanguageHelper('ScopedHelper');
      await scopedHelper.initial(data: dataList, initialCode: LanguageCodes.en);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LanguageScope(
              languageHelper: scopedHelper,
              child: LanguageBuilder(
                builder: (_) => Column(
                  children: [
                    Text('Hello'.tr),
                    // trT should still use scoped helper, but translate to specified code
                    Text('Hello'.trT(LanguageCodes.vi)),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // First uses current language (English), second translates to Vietnamese
      expect(find.text('Hello'), findsOneWidget);
      expect(find.text('Xin Chào'), findsOneWidget);

      scopedHelper.dispose();
    });

    testWidgets('Extension methods trF uses scoped helper in LanguageBuilder', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});

      final scopedHelper = LanguageHelper('ScopedHelper');
      await scopedHelper.initial(data: dataList, initialCode: LanguageCodes.vi);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LanguageScope(
              languageHelper: scopedHelper,
              child: LanguageBuilder(
                builder: (_) => Text(
                  'You have @number dollars'.trF(
                    params: {'number': 200},
                    toCode: LanguageCodes.en,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Should translate to English (toCode parameter)
      expect(find.text('You have 200 dollars'), findsOneWidget);
      expect(find.text('Bạn có 200 đô-la'), findsNothing);

      scopedHelper.dispose();
    });

    testWidgets('Nested LanguageBuilder with LanguageScope', (tester) async {
      SharedPreferences.setMockInitialValues({});

      final outerHelper = LanguageHelper('OuterHelper');
      final innerHelper = LanguageHelper('InnerHelper');
      await outerHelper.initial(data: dataList, initialCode: LanguageCodes.en);
      await innerHelper.initial(data: dataList, initialCode: LanguageCodes.vi);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LanguageScope(
              languageHelper: outerHelper,
              child: LanguageBuilder(
                builder: (_) => Column(
                  children: [
                    Text('Hello'.tr), // Uses outer scope
                    LanguageScope(
                      languageHelper: innerHelper,
                      child: LanguageBuilder(
                        builder: (_) => Text('Hello'.tr), // Uses inner scope
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Should show both languages
      expect(find.text('Hello'), findsOneWidget); // Outer scope
      expect(find.text('Xin Chào'), findsOneWidget); // Inner scope

      outerHelper.dispose();
      innerHelper.dispose();
    });

    testWidgets('LanguageScope updates when helper changes', (tester) async {
      SharedPreferences.setMockInitialValues({});

      final helper1 = LanguageHelper('Helper1');
      final helper2 = LanguageHelper('Helper2');
      await helper1.initial(data: dataList, initialCode: LanguageCodes.en);
      await helper2.initial(data: dataList, initialCode: LanguageCodes.vi);

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

      expect(find.text('Hello'), findsOneWidget);
      expect(find.text('Xin Chào'), findsNothing);

      // Update to different helper - use a key to force recreation
      await tester.pumpWidget(
        MaterialApp(
          key: const ValueKey('updated'),
          home: Scaffold(
            body: LanguageScope(
              languageHelper: helper2,
              child: LanguageBuilder(builder: (_) => Text('Hello'.tr)),
            ),
          ),
        ),
      );
      // Pump multiple times to ensure lifecycle methods run
      await tester.pump();
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('Xin Chào'), findsOneWidget);
      expect(find.text('Hello'), findsNothing);

      helper1.dispose();
      helper2.dispose();
    });
  });
}
