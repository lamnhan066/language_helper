import 'package:flutter/material.dart';
import 'package:language_helper/language_helper.dart';

class LanguageHelperWidget extends StatelessWidget {
  const LanguageHelperWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            LanguageBuilder(builder: (_) => Text('Hello'.tr)),
            Text('Hello'.tr),
            LanguageBuilder(
              builder: (_) => Text(
                'You have @number dollars'.trP({'number': 100}),
              ),
            ),
            LanguageBuilder(
              builder: (_) => Text(
                'You have @{number}, dollars'.trP({'number': 10}),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LhbWidget extends StatelessWidget {
  const LhbWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Lhb((_) => Text('Hello'.tr)),
            Text('Hello'.tr),
            LanguageBuilder(
              builder: (_) => Text(
                'You have @number dollars'.trF(params: {'number': 100}),
              ),
            ),
            LanguageBuilder(
              builder: (_) => Text(
                'You have @{number}, dollars'.trF(params: {'number': 10}),
              ),
            ),
          ],
        ),
      ),
    );
  }
}