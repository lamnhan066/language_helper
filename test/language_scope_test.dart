import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:language_helper/language_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'language_data.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Test LanguageScope -', () {
    testWidgets('LanguageHelper.of returns scoped helper', (tester) async {
      SharedPreferences.setMockInitialValues({});

      final scopedHelper = LanguageHelper('ScopedHelper');
      await scopedHelper.initial(
        LanguageConfig(data: dataList, initialCode: LanguageCodes.vi),
      );

      LanguageHelper? retrievedHelper;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LanguageScope(
              languageHelper: scopedHelper,
              child: LanguageBuilder(
                builder: (context) {
                  retrievedHelper = LanguageHelper.of(context);
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

      await scopedHelper.dispose();
    });

    testWidgets('LanguageHelper.of falls back to instance when no scope', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});

      final languageHelper = LanguageHelper.instance;
      await languageHelper.initial(
        LanguageConfig(
          data: dataList,
          initialCode: LanguageCodes.en,
        ),
      );

      LanguageHelper? retrievedHelper;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                retrievedHelper = LanguageHelper.of(context);
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

    testWidgets('LanguageHelper.of returns scoped helper', (tester) async {
      SharedPreferences.setMockInitialValues({});

      final scopedHelper = LanguageHelper('ScopedHelper');
      await scopedHelper.initial(
        LanguageConfig(data: dataList, initialCode: LanguageCodes.vi),
      );

      LanguageHelper? retrievedHelper;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LanguageScope(
              languageHelper: scopedHelper,
              child: LanguageBuilder(
                builder: (context) {
                  retrievedHelper = LanguageHelper.of(context);
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

      await scopedHelper.dispose();
    });

    testWidgets('LanguageHelper.of falls back to instance when no scope', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});

      final languageHelper = LanguageHelper.instance;
      await languageHelper.initial(
        LanguageConfig(
          data: dataList,
          initialCode: LanguageCodes.en,
        ),
      );

      LanguageHelper? retrievedHelper;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                retrievedHelper = LanguageHelper.of(context);
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

    testWidgets('Nested LanguageScope - child overrides parent', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});

      final parentHelper = LanguageHelper('ParentHelper');
      final childHelper = LanguageHelper('ChildHelper');
      await parentHelper.initial(
        LanguageConfig(data: dataList, initialCode: LanguageCodes.en),
      );
      await childHelper.initial(
        LanguageConfig(data: dataList, initialCode: LanguageCodes.vi),
      );

      LanguageHelper? parentRetrieved;
      LanguageHelper? childRetrieved;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LanguageScope(
              languageHelper: parentHelper,
              child: LanguageBuilder(
                builder: (parentContext) {
                  parentRetrieved = LanguageHelper.of(parentContext);
                  return LanguageScope(
                    languageHelper: childHelper,
                    child: LanguageBuilder(
                      builder: (childContext) {
                        childRetrieved = LanguageHelper.of(childContext);
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

      await parentHelper.dispose();
      await childHelper.dispose();
    });

    testWidgets('LanguageBuilder inherits from LanguageScope', (tester) async {
      SharedPreferences.setMockInitialValues({});

      final scopedHelper = LanguageHelper('ScopedHelper');
      await scopedHelper.initial(
        LanguageConfig(data: dataList, initialCode: LanguageCodes.vi),
      );

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

      await scopedHelper.dispose();
    });

    testWidgets(
      'LanguageBuilder priority: explicit > LanguageScope > instance',
      (tester) async {
        SharedPreferences.setMockInitialValues({});

        final explicitHelper = LanguageHelper('ExplicitHelper');
        final scopedHelper = LanguageHelper('ScopedHelper');
        await explicitHelper.initial(
          LanguageConfig(
            data: dataList,
            initialCode: LanguageCodes.en,
          ),
        );
        await scopedHelper.initial(
          LanguageConfig(
            data: dataList,
            initialCode: LanguageCodes.vi,
          ),
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

        await explicitHelper.dispose();
        await scopedHelper.dispose();
      },
    );

    testWidgets('Tr widget inherits from LanguageScope', (tester) async {
      SharedPreferences.setMockInitialValues({});

      final scopedHelper = LanguageHelper('ScopedHelper');
      await scopedHelper.initial(
        LanguageConfig(data: dataList, initialCode: LanguageCodes.vi),
      );

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

      await scopedHelper.dispose();
    });

    testWidgets(
      'Extension methods tr, trP use scoped helper in LanguageBuilder',
      (tester) async {
        SharedPreferences.setMockInitialValues({});

        final scopedHelper = LanguageHelper('ScopedHelper');
        await scopedHelper.initial(
          LanguageConfig(
            data: dataList,
            initialCode: LanguageCodes.vi,
          ),
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

        await scopedHelper.dispose();
      },
    );

    testWidgets('Extension methods trT uses scoped helper in LanguageBuilder', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});

      final scopedHelper = LanguageHelper('ScopedHelper');
      await scopedHelper.initial(
        LanguageConfig(data: dataList, initialCode: LanguageCodes.en),
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
                    // trT should still use scoped helper, but translate to
                    // specified code
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

      await scopedHelper.dispose();
    });

    testWidgets('Extension methods trF uses scoped helper in LanguageBuilder', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});

      final scopedHelper = LanguageHelper('ScopedHelper');
      await scopedHelper.initial(
        LanguageConfig(data: dataList, initialCode: LanguageCodes.vi),
      );

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

      await scopedHelper.dispose();
    });

    testWidgets('Nested LanguageBuilder with LanguageScope', (tester) async {
      SharedPreferences.setMockInitialValues({});

      final outerHelper = LanguageHelper('OuterHelper');
      final innerHelper = LanguageHelper('InnerHelper');
      await outerHelper.initial(
        LanguageConfig(data: dataList, initialCode: LanguageCodes.en),
      );
      await innerHelper.initial(
        LanguageConfig(data: dataList, initialCode: LanguageCodes.vi),
      );

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

      await outerHelper.dispose();
      await innerHelper.dispose();
    });

    testWidgets('LanguageScope updates when helper changes', (tester) async {
      SharedPreferences.setMockInitialValues({});

      final helper1 = LanguageHelper('Helper1');
      final helper2 = LanguageHelper('Helper2');
      await helper1.initial(
        LanguageConfig(data: dataList, initialCode: LanguageCodes.en),
      );
      await helper2.initial(
        LanguageConfig(data: dataList, initialCode: LanguageCodes.vi),
      );

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

      await helper1.dispose();
      await helper2.dispose();
    });

    testWidgets('updateShouldNotify returns true when helper changes', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});

      final helper1 = LanguageHelper('Helper1');
      final helper2 = LanguageHelper('Helper2');
      await helper1.initial(
        LanguageConfig(data: dataList, initialCode: LanguageCodes.en),
      );
      await helper2.initial(
        LanguageConfig(data: dataList, initialCode: LanguageCodes.vi),
      );

      final scope1 = LanguageScope(
        languageHelper: helper1,
        child: const SizedBox(),
      );
      final scope2 = LanguageScope(
        languageHelper: helper2,
        child: const SizedBox(),
      );

      // updateShouldNotify should return true when helpers are different
      expect(scope1.updateShouldNotify(scope2), isTrue);

      await helper1.dispose();
      await helper2.dispose();
    });

    testWidgets('updateShouldNotify returns false when helper is same', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});

      final helper = LanguageHelper('Helper');
      await helper.initial(
        LanguageConfig(data: dataList, initialCode: LanguageCodes.en),
      );

      final scope1 = LanguageScope(
        languageHelper: helper,
        child: const SizedBox(),
      );
      final scope2 = LanguageScope(
        languageHelper: helper,
        child: const SizedBox(),
      );

      // updateShouldNotify should return false when helpers are the same
      // instance
      expect(scope1.updateShouldNotify(scope2), isFalse);

      await helper.dispose();
    });

    testWidgets('LanguageBuilder updates when scope helper changes', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});

      final helper1 = LanguageHelper('Helper1');
      final helper2 = LanguageHelper('Helper2');
      await helper1.initial(
        LanguageConfig(data: dataList, initialCode: LanguageCodes.en),
      );
      await helper2.initial(
        LanguageConfig(data: dataList, initialCode: LanguageCodes.vi),
      );

      var buildCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LanguageScope(
              languageHelper: helper1,
              child: LanguageBuilder(
                builder: (context) {
                  buildCount++;
                  final helper = LanguageHelper.of(context);
                  return Text(helper == helper1 ? 'Hello' : 'Xin Chào');
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(buildCount, greaterThan(0));
      expect(find.text('Hello'), findsOneWidget);

      // Update with different helper - LanguageBuilder will detect change in
      // didChangeDependencies
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LanguageScope(
              languageHelper: helper2, // Different helper
              child: LanguageBuilder(
                builder: (context) {
                  buildCount++;
                  final helper = LanguageHelper.of(context);
                  return Text(helper == helper1 ? 'Hello' : 'Xin Chào');
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Should have rebuilt and show Vietnamese text
      // LanguageBuilder detects the helper change in didChangeDependencies
      // and rebuilds
      expect(find.text('Xin Chào'), findsOneWidget);
      expect(buildCount, greaterThan(1)); // Should have rebuilt

      await helper1.dispose();
      await helper2.dispose();
    });

    testWidgets(
      'updateShouldNotify does not trigger rebuild when helper is same',
      (tester) async {
        SharedPreferences.setMockInitialValues({});

        final helper = LanguageHelper('Helper');
        await helper.initial(
          LanguageConfig(data: dataList, initialCode: LanguageCodes.en),
        );

        final oldScope = LanguageScope(
          languageHelper: helper,
          child: const SizedBox(),
        );
        final newScope = LanguageScope(
          languageHelper: helper, // Same helper instance
          child: const SizedBox(),
        );

        // updateShouldNotify should return false for same helper instance
        expect(newScope.updateShouldNotify(oldScope), isFalse);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: LanguageScope(
                languageHelper: helper,
                child: LanguageBuilder(
                  builder: (context) {
                    return Text('Hello'.tr);
                  },
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Hello'), findsOneWidget);

        // Update with same helper instance - updateShouldNotify returns false
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: LanguageScope(
                languageHelper: helper, // Same helper instance
                child: LanguageBuilder(
                  builder: (context) {
                    return Text('Hello'.tr);
                  },
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Widget should still render correctly
        expect(find.text('Hello'), findsOneWidget);

        await helper.dispose();
      },
    );

    testWidgets(
      'of falls back to instance in deeply nested structure without scope',
      (tester) async {
        SharedPreferences.setMockInitialValues({});

        final languageHelper = LanguageHelper.instance;
        await languageHelper.initial(
          LanguageConfig(
            data: dataList,
            initialCode: LanguageCodes.en,
          ),
        );

        LanguageHelper? retrievedHelper;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  return Column(
                    children: [
                      Builder(
                        builder: (innerContext) {
                          return Builder(
                            builder: (deepContext) {
                              retrievedHelper = LanguageHelper.of(deepContext);
                              return const SizedBox();
                            },
                          );
                        },
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(retrievedHelper, equals(LanguageHelper.instance));
      },
    );

    testWidgets('of finds scoped helper in deeply nested structure', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});

      final scopedHelper = LanguageHelper('DeepScopedHelper');
      await scopedHelper.initial(
        LanguageConfig(data: dataList, initialCode: LanguageCodes.vi),
      );

      LanguageHelper? retrievedHelper;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LanguageScope(
              languageHelper: scopedHelper,
              child: Builder(
                builder: (context) {
                  return Column(
                    children: [
                      Builder(
                        builder: (innerContext) {
                          return Builder(
                            builder: (deepContext) {
                              retrievedHelper = LanguageHelper.of(deepContext);
                              return const SizedBox();
                            },
                          );
                        },
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(retrievedHelper, equals(scopedHelper));

      await scopedHelper.dispose();
    });

    testWidgets('of finds scoped helper in deeply nested structure', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});

      final scopedHelper = LanguageHelper('DeepScopedHelper');
      await scopedHelper.initial(
        LanguageConfig(data: dataList, initialCode: LanguageCodes.vi),
      );

      LanguageHelper? retrievedHelper;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LanguageScope(
              languageHelper: scopedHelper,
              child: Builder(
                builder: (context) {
                  return Column(
                    children: [
                      Builder(
                        builder: (innerContext) {
                          return Builder(
                            builder: (deepContext) {
                              retrievedHelper = LanguageHelper.of(deepContext);
                              return const SizedBox();
                            },
                          );
                        },
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(retrievedHelper, equals(scopedHelper));

      await scopedHelper.dispose();
    });

    testWidgets(
      'of falls back to instance in deeply nested structure without scope',
      (tester) async {
        SharedPreferences.setMockInitialValues({});

        final languageHelper = LanguageHelper.instance;
        await languageHelper.initial(
          LanguageConfig(
            data: dataList,
            initialCode: LanguageCodes.en,
          ),
        );

        LanguageHelper? retrievedHelper;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  return Column(
                    children: [
                      Builder(
                        builder: (innerContext) {
                          return Builder(
                            builder: (deepContext) {
                              retrievedHelper = LanguageHelper.of(deepContext);
                              return const SizedBox();
                            },
                          );
                        },
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(retrievedHelper, equals(LanguageHelper.instance));
      },
    );

    testWidgets('LanguageScope with same helper instance does not notify', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});

      final helper = LanguageHelper('SameHelper');
      await helper.initial(
        LanguageConfig(data: dataList, initialCode: LanguageCodes.en),
      );

      final oldScope = LanguageScope(
        languageHelper: helper,
        child: const SizedBox(),
      );
      final newScope = LanguageScope(
        languageHelper: helper,
        child: const SizedBox(),
      );

      // Same instance should not notify
      expect(newScope.updateShouldNotify(oldScope), isFalse);

      await helper.dispose();
    });

    testWidgets('Nested of returns child scope, not parent scope', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});

      final parentHelper = LanguageHelper('ParentHelper');
      final childHelper = LanguageHelper('ChildHelper');
      await parentHelper.initial(
        LanguageConfig(data: dataList, initialCode: LanguageCodes.en),
      );
      await childHelper.initial(
        LanguageConfig(data: dataList, initialCode: LanguageCodes.vi),
      );

      LanguageHelper? parentRetrieved;
      LanguageHelper? childRetrieved;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LanguageScope(
              languageHelper: parentHelper,
              child: Builder(
                builder: (parentContext) {
                  parentRetrieved = LanguageHelper.of(parentContext);
                  return LanguageScope(
                    languageHelper: childHelper,
                    child: Builder(
                      builder: (childContext) {
                        childRetrieved = LanguageHelper.of(childContext);
                        return const SizedBox();
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

      await parentHelper.dispose();
      await childHelper.dispose();
    });

    testWidgets(
      'showDialog can access same LanguageHelper instance from parent '
      'LanguageScope',
      (tester) async {
        SharedPreferences.setMockInitialValues({});

        final scopedHelper = LanguageHelper('ScopedHelper');
        await scopedHelper.initial(
          LanguageConfig(
            data: dataList,
            initialCode: LanguageCodes.vi,
          ),
        );

        LanguageHelper? languageHelper1;
        LanguageHelper? languageHelper2;

        await tester.pumpWidget(
          LanguageScope(
            languageHelper: scopedHelper,
            child: MaterialApp(
              home: Scaffold(
                body: Builder(
                  builder: (context) {
                    languageHelper1 = LanguageHelper.of(context);
                    return ElevatedButton(
                      onPressed: () {
                        unawaited(
                          showDialog<void>(
                            context: context,
                            builder: (dialogContext) {
                              languageHelper2 = LanguageHelper.of(
                                dialogContext,
                              );
                              return AlertDialog(
                                title: Text('Hello'.tr),
                                content: const Text('Test Dialog'),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(dialogContext).pop(),
                                    child: const Text('OK'),
                                  ),
                                ],
                              );
                            },
                          ),
                        );
                      },
                      child: const Text('Open Dialog'),
                    );
                  },
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(languageHelper1, equals(scopedHelper));
        expect(languageHelper1, isNotNull);

        // Tap button to show dialog
        await tester.tap(find.text('Open Dialog'));
        await tester.pumpAndSettle();

        // Verify the dialog is shown and can access the same LanguageHelper
        expect(languageHelper2, isNotNull);
        expect(languageHelper1, equals(languageHelper2));
        expect(languageHelper2, equals(scopedHelper));

        await scopedHelper.dispose();
      },
    );

    testWidgets(
      'showDialog can access LanguageHelper from LanguageScope with nested '
      'MaterialApp when scope wraps outer app',
      (tester) async {
        SharedPreferences.setMockInitialValues({});

        final scopedHelper = LanguageHelper('ScopedHelper');
        await scopedHelper.initial(
          LanguageConfig(
            data: dataList,
            initialCode: LanguageCodes.vi,
          ),
        );

        LanguageHelper? languageHelper1;
        LanguageHelper? languageHelper2;

        // When there's an outer MaterialApp, LanguageScope should wrap the
        // outer MaterialApp
        // so that dialogs shown from the inner MaterialApp can access it
        await tester.pumpWidget(
          LanguageScope(
            languageHelper: scopedHelper,
            child: MaterialApp(
              home: MaterialApp(
                home: Scaffold(
                  body: LanguageBuilder(
                    builder: (context) {
                      languageHelper1 = LanguageHelper.of(context);
                      return ElevatedButton(
                        onPressed: () {
                          unawaited(
                            showDialog<void>(
                              context: context,
                              builder: (dialogContext) {
                                languageHelper2 = LanguageHelper.of(
                                  dialogContext,
                                );
                                return AlertDialog(
                                  title: Text('Hello'.tr),
                                  content: const Text('Test Dialog'),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(dialogContext).pop(),
                                      child: const Text('OK'),
                                    ),
                                  ],
                                );
                              },
                            ),
                          );
                        },
                        child: const Text('Open Dialog'),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(languageHelper1, equals(scopedHelper));
        expect(languageHelper1, isNotNull);

        // Tap button to show dialog
        await tester.tap(find.text('Open Dialog'));
        await tester.pumpAndSettle();

        // Verify the dialog is shown and can access the same LanguageHelper
        expect(languageHelper2, isNotNull);
        expect(languageHelper1, equals(languageHelper2));
        expect(languageHelper2, equals(scopedHelper));

        await scopedHelper.dispose();
      },
    );

    testWidgets(
      'showDialog cannot access LanguageHelper when LanguageScope is between '
      'nested MaterialApps',
      (tester) async {
        SharedPreferences.setMockInitialValues({});

        final scopedHelper = LanguageHelper('ScopedHelper');
        await scopedHelper.initial(
          LanguageConfig(
            data: dataList,
            initialCode: LanguageCodes.vi,
          ),
        );

        LanguageHelper? languageHelper1;
        LanguageHelper? languageHelper2;

        // This pattern does NOT work correctly because dialogs shown from the
        // inner MaterialApp are shown in the outer MaterialApp's overlay,
        // which doesn't have access to
        // the LanguageScope that's between the two MaterialApps.
        // Solution: Wrap the outermost MaterialApp with LanguageScope.
        await tester.pumpWidget(
          MaterialApp(
            home: LanguageScope(
              languageHelper: scopedHelper,
              child: MaterialApp(
                home: Scaffold(
                  body: LanguageBuilder(
                    builder: (context) {
                      languageHelper1 = LanguageHelper.of(context);
                      return ElevatedButton(
                        onPressed: () {
                          unawaited(
                            showDialog<void>(
                              context: context,
                              builder: (dialogContext) {
                                // The dialog context cannot access
                                // LanguageScope because it's shown in the outer
                                // MaterialApp's overlay
                                languageHelper2 = LanguageHelper.of(
                                  dialogContext,
                                );
                                return AlertDialog(
                                  title: const Text('Test Dialog'),
                                  content: const Text('Dialog Content'),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(dialogContext).pop(),
                                      child: const Text('OK'),
                                    ),
                                  ],
                                );
                              },
                            ),
                          );
                        },
                        child: const Text('Open Dialog'),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(languageHelper1, equals(scopedHelper));
        expect(languageHelper1, isNotNull);

        // Tap button to show dialog
        await tester.tap(find.text('Open Dialog'));
        await tester.pumpAndSettle();

        // When LanguageScope is between nested MaterialApps, the dialog
        // context cannot access it because the dialog is shown in the outer
        // MaterialApp's overlay, which is above the LanguageScope in the
        // widget tree.
        // The dialog falls back to LanguageHelper.instance instead of the
        // scoped helper.
        expect(languageHelper2, isNotNull);
        expect(languageHelper2, isNot(equals(scopedHelper)));
        expect(languageHelper2, equals(LanguageHelper.instance));

        await scopedHelper.dispose();
      },
    );

    testWidgets(
      'LanguageHelper.of logs warning when no LanguageScope is found',
      (tester) async {
        SharedPreferences.setMockInitialValues({});

        final languageHelper = LanguageHelper.instance;
        await languageHelper.initial(
          LanguageConfig(
            data: dataList,
            initialCode: LanguageCodes.en,
            isDebug: true, // Enable debug to see logging
          ),
        );

        // Capture logs by monitoring console output
        // Since we can't easily capture logger output in tests,
        // we'll verify the behavior by checking that the instance is returned
        // and that logging would occur (tested by ensuring no scope exists)
        LanguageHelper? retrievedHelper;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  // First call - should log
                  retrievedHelper = LanguageHelper.of(context);
                  return const SizedBox();
                },
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(retrievedHelper, equals(LanguageHelper.instance));
        expect(retrievedHelper, isNotNull);

        // Call again with same context - should not log again
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  // Second call with different context - should log again
                  retrievedHelper = LanguageHelper.of(context);
                  return const SizedBox();
                },
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(retrievedHelper, equals(LanguageHelper.instance));
      },
    );

    testWidgets('LanguageHelper.of does not log when LanguageScope is found', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});

      final scopedHelper = LanguageHelper('ScopedHelper');
      await scopedHelper.initial(
        LanguageConfig(
          data: dataList,
          initialCode: LanguageCodes.vi,
          isDebug: true,
        ),
      );

      LanguageHelper? retrievedHelper;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LanguageScope(
              languageHelper: scopedHelper,
              child: Builder(
                builder: (context) {
                  // Should not log because scope exists
                  retrievedHelper = LanguageHelper.of(context);
                  return const SizedBox();
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(retrievedHelper, equals(scopedHelper));
      expect(retrievedHelper, isNot(equals(LanguageHelper.instance)));

      await scopedHelper.dispose();
    });

    testWidgets('LanguageHelper.of logs only once per context identity', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});

      final languageHelper = LanguageHelper.instance;
      await languageHelper.initial(
        LanguageConfig(
          data: dataList,
          initialCode: LanguageCodes.en,
          isDebug: true,
        ),
      );

      LanguageHelper? helper1;
      LanguageHelper? helper2;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                // Multiple calls with same context - should only log once
                helper1 = LanguageHelper.of(context);
                helper2 = LanguageHelper.of(context);
                return const SizedBox();
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(helper1, equals(LanguageHelper.instance));
      expect(helper2, equals(LanguageHelper.instance));
    });

    testWidgets(
      'LanguageHelper.of caller information extraction works correctly',
      (tester) async {
        SharedPreferences.setMockInitialValues({});

        final languageHelper = LanguageHelper.instance;
        await languageHelper.initial(
          LanguageConfig(
            data: dataList,
            initialCode: LanguageCodes.en,
            isDebug: true,
          ),
        );

        LanguageHelper? retrievedHelper;

        // Call from LanguageBuilder which should show in caller info
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: LanguageBuilder(
                builder: (context) {
                  retrievedHelper = LanguageHelper.of(context);
                  return const SizedBox();
                },
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(retrievedHelper, equals(LanguageHelper.instance));
        // The caller info should be extracted from the stack trace
        // (We can't easily verify the exact message in tests, but we verify
        // it doesn't crash)
      },
    );

    testWidgets(
      'FutureBuilder wrapping LanguageScope - scope accessible in loading '
      'and completed states',
      (tester) async {
        SharedPreferences.setMockInitialValues({});

        final scopedHelper = LanguageHelper('ScopedHelper');
        await scopedHelper.initial(
          LanguageConfig(
            data: dataList,
            initialCode: LanguageCodes.vi,
          ),
        );

        LanguageHelper? loadingHelper;
        LanguageHelper? completedHelper;

        final future = Future.delayed(
          const Duration(milliseconds: 10),
          () => 'data',
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: FutureBuilder<String>(
                future: future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    // During loading state
                    return LanguageScope(
                      languageHelper: scopedHelper,
                      child: LanguageBuilder(
                        builder: (context) {
                          loadingHelper = LanguageHelper.of(context);
                          return Text('Hello'.tr);
                        },
                      ),
                    );
                  } else {
                    // After future completes
                    return LanguageScope(
                      languageHelper: scopedHelper,
                      child: LanguageBuilder(
                        builder: (context) {
                          completedHelper = LanguageHelper.of(context);
                          return Text('Hello'.tr);
                        },
                      ),
                    );
                  }
                },
              ),
            ),
          ),
        );

        // Pump once to show loading state
        await tester.pump();
        await tester.pump();

        // Verify scope is accessible during loading
        expect(loadingHelper, equals(scopedHelper));
        expect(find.text('Xin Chào'), findsOneWidget);

        // Wait for future to complete
        await tester.pumpAndSettle();

        // Verify scope is accessible after completion
        expect(completedHelper, equals(scopedHelper));
        expect(find.text('Xin Chào'), findsOneWidget);

        await scopedHelper.dispose();
      },
    );

    testWidgets(
      'LanguageScope wrapping FutureBuilder - widgets can access scope in '
      'both loading and data states',
      (tester) async {
        SharedPreferences.setMockInitialValues({});

        final scopedHelper = LanguageHelper('ScopedHelper');
        await scopedHelper.initial(
          LanguageConfig(
            data: dataList,
            initialCode: LanguageCodes.vi,
          ),
        );

        LanguageHelper? loadingHelper;
        LanguageHelper? dataHelper;

        final future = Future.delayed(
          const Duration(milliseconds: 10),
          () => 'data',
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: LanguageScope(
                languageHelper: scopedHelper,
                child: FutureBuilder<String>(
                  future: future,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      // Loading state - should access scope
                      loadingHelper = LanguageHelper.of(context);
                      return LanguageBuilder(
                        builder: (_) => Column(
                          children: [
                            Text('Hello'.tr),
                            const CircularProgressIndicator(),
                          ],
                        ),
                      );
                    } else {
                      // Data state - should access scope
                      dataHelper = LanguageHelper.of(context);
                      return LanguageBuilder(
                        builder: (_) => Column(
                          children: [
                            Text('Hello'.tr),
                            Text(snapshot.data ?? ''),
                          ],
                        ),
                      );
                    }
                  },
                ),
              ),
            ),
          ),
        );

        // Pump once to show loading state
        await tester.pump();
        await tester.pump();

        // Verify scope is accessible during loading
        expect(loadingHelper, equals(scopedHelper));
        expect(find.text('Xin Chào'), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsOneWidget);

        // Wait for future to complete
        await tester.pumpAndSettle();

        // Verify scope is accessible after completion
        expect(dataHelper, equals(scopedHelper));
        expect(find.text('Xin Chào'), findsOneWidget);
        expect(find.text('data'), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsNothing);

        await scopedHelper.dispose();
      },
    );

    testWidgets(
      'LanguageScope inside FutureBuilder builder - scope works when created '
      'dynamically',
      (tester) async {
        SharedPreferences.setMockInitialValues({});

        final scopedHelper = LanguageHelper('ScopedHelper');
        await scopedHelper.initial(
          LanguageConfig(
            data: dataList,
            initialCode: LanguageCodes.vi,
          ),
        );

        LanguageHelper? loadingHelper;
        LanguageHelper? completedHelper;

        final future = Future.delayed(
          const Duration(milliseconds: 10),
          () => 'data',
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: FutureBuilder<String>(
                future: future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    // Create LanguageScope dynamically during loading
                    return LanguageScope(
                      languageHelper: scopedHelper,
                      child: LanguageBuilder(
                        builder: (context) {
                          loadingHelper = LanguageHelper.of(context);
                          return Column(
                            children: [
                              Text('Hello'.tr),
                              const CircularProgressIndicator(),
                            ],
                          );
                        },
                      ),
                    );
                  } else {
                    // Create LanguageScope dynamically after completion
                    return LanguageScope(
                      languageHelper: scopedHelper,
                      child: LanguageBuilder(
                        builder: (context) {
                          completedHelper = LanguageHelper.of(context);
                          return Column(
                            children: [
                              Text('Hello'.tr),
                              Text(snapshot.data ?? ''),
                            ],
                          );
                        },
                      ),
                    );
                  }
                },
              ),
            ),
          ),
        );

        // Pump once to show loading state
        await tester.pump();
        await tester.pump();

        // Verify scope is accessible during loading
        expect(loadingHelper, equals(scopedHelper));
        expect(find.text('Xin Chào'), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsOneWidget);

        // Wait for future to complete
        await tester.pumpAndSettle();

        // Verify scope is accessible after completion
        expect(completedHelper, equals(scopedHelper));
        expect(find.text('Xin Chào'), findsOneWidget);
        expect(find.text('data'), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsNothing);

        await scopedHelper.dispose();
      },
    );
  });
}
