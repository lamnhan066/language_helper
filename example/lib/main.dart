import 'package:flutter/material.dart';

import 'package:language_helper/language_helper.dart';

LanguageData data = {
  LanguageCodes.en: {
    'Hello': 'Hello',
    'Change language': 'Change language',
  },
  LanguageCodes.vi: {
    'Hello': 'Xin Chào',
    'Change language': 'Thay đổi ngôn ngữ',
  }
};

void main() {
  LanguageHelper.instance.initial(
    data: data,
    defaultCode: LanguageCodes.en,
    isDebug: true,
  );

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return LanguageNotifier(builder: (context) {
      return MaterialApp(
        home: Scaffold(
          appBar: AppBar(
            title: LanguageNotifier(
              builder: (context) {
                return Text('Hello'.tr);
              },
            ),
          ),
          body: Center(
            child: Column(
              children: [
                Text('Hello'.tr),
                ElevatedButton(
                  onPressed: () {
                    LanguageHelper.instance.change(LanguageCodes.vi);
                  },
                  child: Text('Change language'.tr),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}
