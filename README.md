# Language Helper
[![codecov](https://codecov.io/gh/lamnhan066/language_helper/graph/badge.svg?token=AIGGNCGOVR)](https://codecov.io/gh/lamnhan066/language_helper)

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

        // Return this when the is no condition satisfied
        '_': 'You have @{number} dollars',
      },
    ),

    // This translation is wrong with the plural number so we need to override.
    'You have @{number} dollar in your wallet':
        'You have @{number} dollar in your wallet',
  },
  LanguageCodes.vi: {
    'Hello @{text}, @number': 'Xin Chào @{text}, @number',
    'Change language': 'Thay đổi ngôn ngữ',
    'You have @{number} dollar': 'Bạn có @{number} đô-la',

    // This translation is right so we don't need to override.
    'You have @{number} dollar in your wallet':
        'Bạn có @{number} đô-la trong ví của bạn',
  }
};
```

With the `LanguageConditions`, you can completely control which text is returned according to the condition of the parameters. You can use `'default'` or `'_'` to set the default value for the condition.

**Initialize the data:**

``` dart
final languageHelper = LanguageHelper.instance;

main() async {
  // LanguageHelper should be initialized before calling `runApp`.
  await languageHelper.initial(
      // This is [LanguageData] and it must be not empty.
      data: data,

      // [Optional] Default is set to the device locale (if available) or the first language of [data]
      initialCode: LanguageCodes.en,

      // [Optional] Change the app language when the device language is changed.
      syncWithDevice: true,
  );

  runApp(const MyApp());
}
```

You can implement flutter localizations to your app like this

``` dart
class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return LanguageBuilder(
      builder: (context) {
        return MaterialApp(
          localizationsDelegates: languageHelper.delegate,
          supportedLocales: languageHelper.locales,
          locale: languageHelper.locale,
          home: const HomePage(),
        );
      }
    );
  }
}
```

**Change the language:**

``` dart
languageHelper.change(LanguageCodes.vi);
```

**Add language data to the current data:**

``` dart
languageHelper.addData(newLanguageData);
languageHelper.addDataOverrides(newLanguageDataOverrides);
```

That methods have `activate` parameter which automaticaly rebuild all needed `LanguageBuilder`, so notice that you may get the `setState` issue because of the rebuilding of the `LanguageBuilder` when it's still building. If the error occurs, you may need to set it to `false` and activate the new data yourself by using `reload` method.

**Get list of implemented `LanguageCodes`s:**

``` dart
// List of [LanguageCodes] from the [data]
final codes = languageHelper.codes;

// List of [LanguageCodes] from the [dataOverrides]
final codesOverrides = languageHelper.codesOverrides;

// List of [LanguageCodes] from both of the [data] and [dataOverrides] without duplicated
final codesBoth = languageHelper.codesBoth;
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

If you want to change the generating path, using this:

``` cmd
dart run language_helper:generate --path=./example/lib
```

This command will also run `dart format` for the generated files, so you can easily manage the translations using the version control.

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

- No matter how many `LanguageBuilder` that you use, the plugin only rebuilds the outest (the root) widget of `LanguageBuilder`, so it improves a lot of performances. And all `LanguageBuilder` widgets will be rebuilt at the same time. This setting can be changed with `forceRebuild` parameter in both `initial` for global setting and `LanguageBuilder` for local setting.

- The `LanguageCodes` contains all the languages with additional information like name in English (englishName) and name in native language (nativeName).

## Contributions

As the project is currently in its early stages, it may contain bugs or other issues. Should you experience any problems, we kindly ask that you file an issue to let us know. Additionally, we welcome contributions in the form of pull requests (PRs) to help enhance the project.