# Language Helper

Make it easier for you to implement multiple languages into your app with minimal effort.

## Usage

**Create the data:**

``` dart
LanguageData data = {
  LanguageCodes.en: {
    'Hello @{text}, @number': 'Hello @{text}, @number',
    'Change language': 'Change language',
  },
  LanguageCodes.vi: {
    'Hello': 'Xin Chào',
    'Change language': 'Thay đổi ngôn ngữ',
  }
};
```

**Initialize the data:**

``` dart
final languageHelper = LanguageHelper.instance;

main() async {
  // LanguageHelper should be initialized before calling `runApp`.
  await languageHelper.initial(
      /// This is [LanguageData] and it must be not empty.
      data: data,

      /// Optional. This is the list of all available keys that your project are using.
      /// You can maintain it by yourself or using [language_helper_generator](https://pub.dev/packages/language_helper_generator) to maintain it.
      analysisKeys: analysisLanguageData.keys, 

      /// Optional. Default is set to the device locale (if available) or the first language of [data]
      initialCode: LanguageCodes.en,

      /// Optional. Default is set to false (doesn't change the language if unavailable)
      useInitialCodeWhenUnavailable: false, 

      /// Rebuild all the widgets instead of only root widgets. It will decrease the app performances.
      forceRebuild: true, 

      /// Auto save and reload the changed language
      isAutoSave: true, 

      /// Call this function if the language is changed
      onChanged: (code) => print(code), 

      // Print debug log. Default is set to false
      isDebug: true, 
  );

  runApp(const MyApp());
}
```

**Get text:**

``` dart
final text = languageHelper.translate('Hello @{text}, @number', params {'text' : 'World', 'number', '10'});
// Hello World, 10
```

**Translate to specific language:**

``` dart
final text = languageHelper.translate('Hello', toCode: LanguageCodes.en);
```

**Use extension:**

``` dart
final text = 'Hello'.tr;
```

or

``` dart
final text = 'Hello @{text}, @number'.trP({'text' : 'World', 'number', '10'});
// Hello World, World
```

or

``` dart
final text = 'Hello @{text}, @number'.trT(LanguageCodes.en);
```

or use full version:

``` dart
final text = 'Hello @{text}, @number'.trF(params: {'text' : 'World', 'number', '10'}, toCode: LanguageCodes.en);
```

**Note:** The `${param}` work in any case, the `@param` only work if the text ends with a white space, the end of a line, or the end of a new line.

Beside the `onChanged` method, you can listen for language change events by using `stream`:

``` dart
final sub = languageHelper.stream.listen((code) => print(code));
```

**Note:** Remember to `sub.cancel()` when it's not in use to avoid memory leaks.

**Use builder to rebuild the widgets automatically on change:**

- For all widget in your app:

``` dart
@override
Widget build(BuildContext context) {
  return LanguageBuilder(builder: (context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text('Hello'.tr),
        ),
        body: Center(
          child: Column(
            children: [
              Text('Hello'.tr),
              ElevatedButton(
                onPressed: () {
                  languageHelper.change(LanguageCodes.vi);
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
```

- For specific widget:

``` dart
LanguageBuilder(
    builder: (context) {
        return Text('Hello'.tr);
    },
),
```

- There is a short version of `LanguageBuilder` is `Lhb` (means `LanguageHelperBuilder`):

``` dart
Lhb((_) => Text('Hello'.tr)),
```

**You can analyze the missing texts for all language with this function:**

``` dart
languageHelper.analyze();
```

This function will be automatically called in `initial` when the `isDebug` is `true`.

Here is the result from the Example:

``` cmd
flutter: [Language Helper]
flutter: [Language Helper] ==================================================
flutter: [Language Helper]
flutter: [Language Helper] Analyze all languages to find the missing texts...
flutter: [Language Helper] Results:
flutter: [Language Helper]   LanguageCodes.en:
flutter: [Language Helper]     This text is missing in `en`
flutter: [Language Helper]
flutter: [Language Helper]   LanguageCodes.vi:
flutter: [Language Helper]     This text is missing in `vi`
flutter: [Language Helper]
flutter: [Language Helper] ==================================================
flutter: [Language Helper]
```

## Additional Information

- Using [language_helper_generator](https://pub.dev/packages/language_helper_generator) (Still in the early stages) will make it easier to maintain the translations in your project.

- The app will try to use the `Devicelocale` to set the `initialCode` if it is not set, if the `Devicelocale` is unavailable, it will use the first language in `data` insteads.

- No matter how many `LanguageBuilder` that you use, the plugin only rebuilds the outest (the root) widget of `LanguageBuilder`, so it improves a lot performance. And all `LanguageBuilder` widgets will be rebuilt at the same time. This setting can be changed with `forceRebuild` parameter in both `initial` for global setting and `LanguageBuilder` for local setting.

- The `LanguageCodes` contains all the languages with additional information like name in English (name) and name in native language (nativeName).

## Contributions

As the project is currently in its early stages, it may contain bugs or other issues. Should you experience any problems, we kindly ask that you file an issue to let us know. Additionally, we welcome contributions in the form of pull requests (PRs) to help enhance the project.

## Note

- The `${param}` work in any case, the `@param` only work if the text ends with a white space, the end of a line, or the end of a new line.
