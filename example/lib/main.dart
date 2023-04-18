import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:language_helper/language_helper.dart';

import 'resources/language_helper/language_data.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await LanguageHelper.instance.initial(
    data: languageData,
    analysisKeys: analysisLanguageData.keys,
    initialCode: LanguageCodes.en,
    isDebug: !kReleaseMode,
  );

  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      supportedLocales: LanguageHelper.instance.locales,
      home: const MyApp(),
    );
  }
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
    return LanguageBuilder(builder: (_) {
      return Scaffold(
        appBar: AppBar(
          title: Tr((_) => Text('Hello'.tr)),
        ),
        body: Center(
          child: Column(
            children: [
              LanguageBuilder(builder: (context) {
                return LanguageBuilder(builder: (context) {
                  return Text('Hello'.tr);
                });
              }),
              Text('Hello'.tr),
              ElevatedButton(
                onPressed: () {
                  if (LanguageHelper.instance.code == LanguageCodes.vi) {
                    LanguageHelper.instance.change(LanguageCodes.en);
                  } else {
                    LanguageHelper.instance.change(LanguageCodes.vi);
                  }
                },
                child: Text('Change language'.tr),
              ),
              ElevatedButton(
                onPressed: () {
                  LanguageHelper.instance.analyze();
                },
                child: Text('Analyze languages'.tr),
              ),
              Builder(builder: (_) => Text('Hello'.tr)),
              Dialog(
                child: Text('Hello'.tr),
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          child: const Icon(Icons.navigate_next_rounded),
          onPressed: () {
            Navigator.push(
                context, MaterialPageRoute(builder: (_) => const OtherPage()));
          },
        ),
      );
    });
  }
}

class OtherPage extends StatefulWidget {
  const OtherPage({Key? key}) : super(key: key);

  @override
  State<OtherPage> createState() => _OtherPageState();
}

class _OtherPageState extends State<OtherPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: LanguageBuilder(builder: (context) {
          return Text('Other Page'.tr);
        }),
      ),
      body: Column(
        children: [
          Tr(
            (context) {
              return Text('Text will be changed'.tr);
            },
          ),
          Text('Text will be not changed'.tr),
          ElevatedButton(
            onPressed: () {
              if (LanguageHelper.instance.code == LanguageCodes.vi) {
                LanguageHelper.instance.change(LanguageCodes.en);
              } else {
                LanguageHelper.instance.change(LanguageCodes.vi);
              }
            },
            child: Tr((_) => Text('Change language'.tr)),
          ),
        ],
      ),
    );
  }
}
