import 'package:flutter/material.dart';
import 'package:language_helper/language_helper.dart';

class LanguageHelperWidget extends StatelessWidget {
  const LanguageHelperWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      localizationsDelegates: LanguageHelper.instance.delegates,
      supportedLocales: LanguageHelper.instance.locales,
      locale: LanguageHelper.instance.locale,
      home: Scaffold(
        body: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            LanguageBuilder(builder: (_) => Text('Hello'.tr)),
            Text('Hello'.tr),
            LanguageBuilder(
              builder: (_) =>
                  Text('You have @number dollars'.trP({'number': 100})),
            ),
            LanguageBuilder(
              forceRebuild: true,
              builder: (_) =>
                  Text('You have @{number}, dollars'.trP({'number': 10})),
            ),
          ],
        ),
      ),
    );
  }
}

class TrWidget extends StatelessWidget {
  const TrWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Tr((_) => Text('Hello'.tr)),
            Text('Hello'.tr),
            Tr(
              (_) =>
                  Text('You have @number dollars'.trF(params: {'number': 100})),
            ),
            Tr(
              (_) => Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Tr(
                    (_) => Text(
                      'You have @{number}, dollars'.trF(params: {'number': 10}),
                    ),
                  ),
                  Tr(
                    (_) => Text(
                      'You have @{number}, dollars'.trF(params: {'number': 10}),
                    ),
                  ),
                ],
              ),
            ),
            Tr(
              (_) => Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Tr(
                    (_) =>
                        Text('You have @{number}'.trF(params: {'number': 10})),
                  ),
                  Tr(
                    (_) =>
                        Text('You have @{number}'.trF(params: {'number': 10})),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CustomLanguageHelperWidget extends StatelessWidget {
  const CustomLanguageHelperWidget({super.key, required this.helper});

  final LanguageHelper helper;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      localizationsDelegates: LanguageHelper.instance.delegates,
      supportedLocales: LanguageHelper.instance.locales,
      locale: LanguageHelper.instance.locale,
      home: Scaffold(
        body: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            LanguageBuilder(
              languageHelper: helper,
              builder: (_) => Text('Hello'.trC(helper)),
            ),
            Text('Hello'.trC(helper)),
            LanguageBuilder(
              languageHelper: helper,
              builder: (_) => Text(
                'You have @number dollars'.trC(helper, params: {'number': 100}),
              ),
            ),
            LanguageBuilder(
              languageHelper: helper,
              forceRebuild: true,
              builder: (_) => Text(
                'You have @{number}, dollars'.trC(
                  helper,
                  params: {'number': 10},
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
