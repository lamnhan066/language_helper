import 'package:flutter/material.dart';
import 'package:language_helper/language_helper.dart';

class PageAsset extends StatefulWidget {
  const PageAsset({super.key});

  @override
  State<PageAsset> createState() => _PageAssetState();
}

class _PageAssetState extends State<PageAsset> {
  final languageHelper = LanguageHelper('CustomLanguageHelper');
  bool isLoaded = false;

  @override
  void initState() {
    initial();
    super.initState();
  }

  void initial() async {
    await languageHelper
        .initial(data: [LanguageDataProvider.asset('assets/resources')]);

    setState(() {
      isLoaded = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return !isLoaded
        ? const Center(child: CircularProgressIndicator())
        : LanguageBuilder(
            languageHelper: languageHelper,
            builder: (context) {
              return Scaffold(
                appBar: AppBar(
                  title: Text('Asset'.trC(languageHelper)),
                ),
                body: Column(children: [
                  Text('This is the line 1'.trC(languageHelper)),
                  Text('This is the line 2'.trC(languageHelper)),
                  ElevatedButton(
                    onPressed: () {
                      if (languageHelper.code == LanguageCodes.vi) {
                        languageHelper.change(LanguageCodes.en);
                      } else {
                        languageHelper.change(LanguageCodes.vi);
                      }
                    },
                    child: Text('Change language'.trC(languageHelper)),
                  ),
                ]),
              );
            });
  }
}
