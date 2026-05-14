import 'package:flutter_test/flutter_test.dart';
import 'package:language_helper/src/utils/debouncer.dart';

void main() {
  testWidgets('Debouncer runs action after delay', (WidgetTester tester) async {
    final debouncer = Debouncer();
    var called = 0;

    debouncer.run(() => called++);

    await tester.pump(const Duration(milliseconds: 50));
    expect(called, 0);

    await tester.pump(const Duration(milliseconds: 50));
    expect(called, 1);
  });

  testWidgets('Debouncer cancels previous calls and only last runs', (
    WidgetTester tester,
  ) async {
    final debouncer = Debouncer();
    var called = 0;

    debouncer.run(() => called++);
    await tester.pump(const Duration(milliseconds: 50));

    // Run again before the first timeout fires; this should cancel the first.
    debouncer.run(() => called += 10);

    await tester.pump(const Duration(milliseconds: 50));
    expect(called, 0);

    await tester.pump(const Duration(milliseconds: 100));
    expect(called, 10);
  });

  testWidgets('Debouncer default milliseconds is 100', (
    WidgetTester tester,
  ) async {
    final debouncer = Debouncer();
    var called = 0;

    debouncer.run(() => called++);

    await tester.pump(const Duration(milliseconds: 99));
    expect(called, 0);

    await tester.pump(const Duration(milliseconds: 1));
    expect(called, 1);
  });
}
