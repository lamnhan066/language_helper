import 'package:flutter_test/flutter_test.dart';
import 'package:language_helper/language_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'skips provider.getData when provider does not support the code',
    () async {
      SharedPreferences.setMockInitialValues({});
      final helper = LanguageHelper('TestProviderSkip1');
      addTearDown(helper.dispose);

      var calledEn = 0;
      var calledVi = 0;

      final providerViOnly = LanguageDataProvider.lazyData({
        LanguageCodes.vi: () {
          calledVi++;
          return {'HelloVi': 'Xin Chào'};
        },
      });

      final providerEnOnly = LanguageDataProvider.lazyData({
        LanguageCodes.en: () {
          calledEn++;
          return {'HelloEn': 'Hello'};
        },
      });

      // Put the provider that does NOT support the requested code first
      await helper.initial(
        [providerViOnly, providerEnOnly],
        config: const LanguageConfig(
          initialCode: LanguageCodes.en,
          isDebug: true,
        ),
      );

      // providerEnOnly should have been loaded, providerViOnly should be skipped
      expect(calledEn, greaterThan(0));
      expect(calledVi, equals(0));
    },
  );

  test('calls provider.getData when provider supports the code', () async {
    SharedPreferences.setMockInitialValues({});
    final helper = LanguageHelper('TestProviderSkip2');
    addTearDown(helper.dispose);

    var calledEn = 0;
    var calledVi = 0;

    final providerViOnly = LanguageDataProvider.lazyData({
      LanguageCodes.vi: () {
        calledVi++;
        return {'HelloVi': 'Xin Chào'};
      },
    });

    final providerEnOnly = LanguageDataProvider.lazyData({
      LanguageCodes.en: () {
        calledEn++;
        return {'HelloEn': 'Hello'};
      },
    });

    // Request vi so the vi-only provider should be called and en-only skipped
    await helper.initial(
      [providerEnOnly, providerViOnly],
      config: const LanguageConfig(
        initialCode: LanguageCodes.vi,
        isDebug: true,
      ),
    );

    expect(calledVi, greaterThan(0));
    expect(calledEn, equals(0));
  });
}
