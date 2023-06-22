# Language Helper

Make it easier for you to implement multiple languages into your app with minimal effort.

## Features

- Easy to control the language translations in your application. Automatically use the current device locale in the first open if possible.

- You can completely control the translated text with `LanguageConditions`.

- Supports analyzing which text is missing in specific language.

- Supports analyzing which text is in your app but not in your language data and vice versa.

- Supports extracting the needed text for translation from all the `.dart` files in your project with a single command `dart run language_helper:generate` (still in the early stages). Original package is [language_helper_generator](https://pub.dev/packages/language_helper_generator).

## Usage

**Create the data:**

``` dart
LanguageData data = {
  LanguageCodes.en: {
    'Hello @{text}, @number': 'Hello @{text}, @number',
    'Change language': 'Change language',
    'You have @{number} dollar': LanguageConditions(
      // Specify the param to use the conditions
      param: 'number',
      conditions: {
        '0': 'You have zero dollar',
        '1': 'You have @{number} dollar',
        '2': 'You have @{number} dollars',

        // Return this when the is no condition satisfied
        'default': 'You have @{number} dollars',
      },
    ),
  },
  LanguageCodes.vi: {
    'Hello @{text}, @number': 'Xin Chào @{text}, @number',
    'Change language': 'Thay đổi ngôn ngữ',
    'You have @{number} dollar': 'Bạn có @{number} đô-la',
  }
};
```

With the `LanguageConditions`, you can completely control which text is returned according to the condition of the parameters.

**Initialize the data:**

``` dart
final languageHelper = LanguageHelper.instance;

main() async {
  // LanguageHelper should be initialized before calling `runApp`.
  await languageHelper.initial(
      // This is [LanguageData] and it must be not empty.
      data: data,

      // [Optional] This is the list of all available keys that your project are using.
      //
      // You can maintain it by yourself or using command `dart run language_helper:generate` 
      // to maintain it.
      analysisKeys: analysisLanguageData.keys, 

      // [Optional] Default is set to the device locale (if available) or the first language of [data]
      initialCode: LanguageCodes.en,

      // [Optional] Default is set to false (doesn't change the language if unavailable)
      useInitialCodeWhenUnavailable: false, 

      // [Optional] Rebuild all the widgets instead of only root widgets. It will decrease the app performances.
      forceRebuild: true, 

      // [Optional] Auto save and reload the changed language
      isAutoSave: true, 

      // [Optional] Call this function if the language is changed
      onChanged: (code) => print(code), 

      // [Optional] Print debug log. Default is set to false
      isDebug: true, 
  );

  runApp(const MyApp());
}
```

**Get text:**

``` dart
final translated = languageHelper.translate(
    'Hello @{text}, @number', 
    toCode: LanguageCodes.en, // [Optional] Translate to specific language code
    params {'text' : 'World', 'number': '10'}, // [Optional] Translate with parameters
);
// Hello World, 10
```

**Use extension:**

``` dart
final translated = 'Hello'.tr;
final translatedParam = 'Hello @{text}, @number'.trP({'text': 'World', 'number': '10'});
final translatedTo = 'Hello @{text}, @number'.trT(LanguageCodes.en);
final translatedFull = 'Hello @{text}, @number'.trF(toCode: LanguageCodes.en, params: {'text': 'World', 'number': '10'});
```

**Note:** The `${param}` works in all cases, the `@param` only work if the text ends with a white space, the end of a line, or the end of a new line.

Beside the `onChanged` method, you can listen to the language changed events by using `stream`:

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

- There is a short version of `LanguageBuilder` is `Tr`:

``` dart
Tr((_) => Text('Hello'.tr)),
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

**Optional:**

You can also create a base `LanguageData` by using command:

``` cmd
dart run language_helper:generate
```

This runner will get all the texts that using language_helper extensions (`.tr`, `.trP`, `.trT`, `.trF`) and `.translate` method then creating a base structure for `LanguageData`. You can see the generated data in the [example](https://github.com/vnniz/language_helper_generator/tree/main/example/lib/resources/language_helper).

The data will be generated with this format:

``` txt
|-- .lib
|   |--- resources
|   |    |--- language_helper
|   |    |    |--- _language_data_abstract.g.dart
|   |    |    |--- language_data.dart
```

- [_language_data_abstract.g.dart](https://github.com/vnniz/language_helper_generator/tree/main/example/lib/resources/language_helper/_language_data_abstract.g.dart): Contains your base language from your all `.dart` files. This file will be re-generated when you run the command.

- [language_data.dart](https://github.com/vnniz/language_helper_generator/tree/main/example/lib/resources/language_helper/language_data.dart): Modifiable language data because it's only generated 1 time.

## LanguageData Serialization

Convert `LanguageData` to JSON:

``` dart
final json = data.toJson();
```

Convert JSON to `LanguageData`:

``` dart
final data = LanguageDataSerializer.fromJson(json);
```

## Additional Information

- The app will try to use the `Devicelocale` to set the `initialCode` if it is not set, if the `Devicelocale` is unavailable, it will use the first language in `data` insteads.

- No matter how many `LanguageBuilder` that you use, the plugin only rebuilds the outest (the root) widget of `LanguageBuilder`, so it improves a lot performance. And all `LanguageBuilder` widgets will be rebuilt at the same time. This setting can be changed with `forceRebuild` parameter in both `initial` for global setting and `LanguageBuilder` for local setting.

- The `LanguageCodes` contains all the languages with additional information like name in English (name) and name in native language (nativeName).

## Contributions

As the project is currently in its early stages, it may contain bugs or other issues. Should you experience any problems, we kindly ask that you file an issue to let us know. Additionally, we welcome contributions in the form of pull requests (PRs) to help enhance the project.

## Note

- The `${param}` works in all cases, the `@param` only work if the text ends with a white space, the end of a line, or the end of a new line.
