# Language Helper

[![codecov](https://codecov.io/gh/lamnhan066/language_helper/graph/badge.svg?token=AIGGNCGOVR)](https://codecov.io/gh/lamnhan066/language_helper)

Multi-language app tool with an efficient generator and a custom GPT-4 translator for easy localization.

I'm not a big fan of the '.arb' format or using short variables to store text in app development. It can be a bit tricky to control the length of the text when working with these methods. That's why I came up with a handy package that makes it easier to use real text during development and even simplify localization based on text. I hope you find it useful!

## Features

- Easy to control the language translations in your application. Automatically uses the current device locale upon first open, if possible.

- You can completely control the translated text with `LanguageConditions`.

- Supports analyzing which text is missing in a specific language or is in your app but not in your language data, and vice versa.

- Supports extracting the needed text for translation from all `.dart` files in your project with a single command (Not using `build_runner` nor custom parser so it very fast and reliable).

- A `Language Helper Translator` on Chat GPT-4 that make it easier to translate the language data to a destination language.

## Contents

- [Set Up](#set-up): Only this step is required while developing
  - [Add The language_helper To The Project](#add-the-language_helper-to-the-project)
  - [Add An Empty LanguageHelper While Developing](#add-an-empty-languagehelper-while-developing)
  - [Add `.tr` Or `.trP` To All Needed `String`s](#add-tr-or-trp-to-all-needed-strings)
- [Generator Flow Usage](#generator-flow-usage)
  - [Dart Map](#dart-map)
  - [JSON](#json)
- [Manual Flow Usage](#manual-flow-usage)
  - [Create The Translations](#create-the-translations)
  - [Add To The Project](#add-to-the-project)
- [Using `LanguageBuilder` To Update The `String`s](#using-languagebuilder-to-update-the-strings)
- [Control The Translation](#control-the-translation)
  - [Change The Language](#change-the-language)
  - [Add A New Language Data](#add-a-new-language-data)
  - [Get The List Of Supported Language Code](#get-the-list-of-supported-language-code)
  - [Listen To The Language Changing State](#listen-to-the-language-changing-state)
- [Advanced Language Helper Generator](#advanced-language-helper-generator)
  - [Modify The Input Path](#modify-the-input-path)
  - [Modify The Output Path](#modify-the-output-path)
  - [Convert From `LanguageData` to `JSON`](#convert-from-languagedata-to-json)
- [Language Data Serialization](#language-data-serialization)
- [Language Helper Translator (A Custom Chat GPT-4)](#language-helper-translator-a-custom-chat-gpt-4)
- [Additional Information](#additional-information)
- [Contributions](#contributions)

## Set Up

While developing, we just need to finish the [Set Up](#set-up) steps. All other steps can be done when the app is ready to implement the localizations.

### Add The language_helper To The Project

```shell
flutter pub add language_helper
```

### Add An Empty LanguageHelper While Developing

```dart
final languageHelper = LanguageHelper.instance;

main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await languageHelper.initial(data: []);
  runApp(const MyApp());
}
```

### Add `.tr` Or `.trP` To All Needed `String`s

Normal translation

```dart
Text('Translate this text'.tr)
```

Translate with parameters

```dart
Text('Hello @{name}'.trP({'name': name}))
```

Plural (Read [Manual Flow Usage](#manual-flow-usage) to know how to use it)

```dart
Text('We have @{number} dollar'.trP({'number': number}))
```

## Generator Flow Usage

### Dart Map

**Generate:**

```shell
dart run language_helper:generate
```

The data will be generated in this path by default:

```txt
|-- .lib
|   |--- resources
|   |    |--- language_helper
|   |    |    |--- _language_data_abstract.g.dart   ; This file will be overwritten when generating
|   |    |    |--- language_data.dart
```

**Implement to your project:**

```dart
final languageHelper = LanguageHelper.instance;

final languageDataProvider = LanguageDataProvider.data(languageData);

main() async {
  await languageHelper.initial(
      data: [languageDataProvider],
  );

  runApp(const MyApp());
}
```

### JSON

When using JSON, you can store your translation data in `assets` or on network

```shell
dart run language_helper:generate --json
```

The data will be generated in this path by default:

```txt
|-- assets
|  |- language_helper
|  |  |- codes.json            ; This file will be overwritten when generating
|  |  |  |- languages
|  |  |  |  |- _generated.json ; This file will be overwritten when generating
```

### Implement to your project

**Define the language data:**

```dart
final languageHelper = LanguageHelper.instance;

// Assets
final languageDataProvider = LanguageDataProvider.asset('assets/language_helper');

// Network
final languageDataProvider = LanguageDataProvider.network('https://example.com/language_helper');
```

**Add to the `LanguageHelper` instance:**

```dart
final languageHelper = LanguageHelper.instance;

main() async {
  await languageHelper.initial(
      data: [languageDataProvider],
  );

  runApp(const MyApp());
}
```

**Combine all of them to improve the translation:**

```dart
main() async {
  await languageHelper.initial(
      data: [
        LanguageDataProvider.network('https://example.com/language_helper'),
        LanguageDataProvider.asset('assets/language_helper'),
        LanguageDataProvider.data(languageData),
      ],
  );

  runApp(const MyApp());
}
```

The package will get the translation data in order from top to bottom.

## Manual Flow Usage

### Create The Translations

**Dart Map:**

```dart
final en = {
  'Translate this text': 'Translate this text',
  'Hello @{name}': 'Hello @{name}',
  'We have @{number} dollar': LanguageCondition(
    param: 'number',
    conditions: {
      '0': 'We have zero dollar',
      '1': 'We have one dollar',

      // Default value.
      '_': 'We have @{number} dollars',
    }
  ),
};

const vi = {
  'Translate this text': 'Dịch chữ này',
  'Hello @{name}': 'Xin chào @{name}',
  'We have @{number} dollar': 'Chúng ta có @{number} đô-la', 
};

LanguageData languageData = {
  LanguageCodes.en: en,
  LanguageCodes.vi: vi,
};

final languageDataProvider = LanguageDataProvider.data(languageData);
```

With `LanguageConditions`, you can completely control which text is returned according to the parameters' conditions. You can use `'default'` or `'_'` to set the default value for the condition.

**JSON:**

`assets/language_helper/codes.json`: Contains all language codes

```JSON
["en", "vi"]
```

`assets/language_helper/languages/vi.json`:

```JSON
{
  "Translate this text": "Translate this text",
  "Hello @{name}": "Hello @{name}",
  "We have @{number} dollar": {
    "param": "number",
    "conditions": {
      "0": "We have zero dollar",
      "1": "We have one dollar",

      // Default value.
      "_": "We have @{number} dollars",
    }
  }
}
```

`assets/language_helper/languages/en.json`:

```JSON
{
  "Translate this text": "Dịch chữ này",
  "Hello @{name}": "Xin chào @{name}",
  "We have @{number} dollar": "Chúng ta có @{number} đô-la", 
}
```

```dart
final languageDataProvider = LanguageDataProvider.asset('assets/language_helper');
```

### Add To The Project

```dart
final languageHelper = LanguageHelper.instance;

main() async {
  await languageHelper.initial(
      data: [languageDataProvider],
  );

  runApp(const MyApp());
}
```

## Using `LanguageBuilder` To Update The `String`s

### In the `MaterialApp`

``` dart
class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return LanguageBuilder(
      builder: (context) {
        return MaterialApp(
          localizationsDelegates: languageHelper.delegates,
          supportedLocales: languageHelper.locales,
          locale: languageHelper.locale,
          home: const HomePage(),
        );
      }
    );
  }
}
```

### In your `Widget`s

**Using `LanguageBuilder`:**

``` dart
LanguageBuilder(
    builder: (context) {
        return Scaffold(
          body: Column(
            children: [
              Text('Hello @{name}'.tr),
              Text('We have @{number} dollar'.tr),
            ],
          ),
        );
    },
),
```

**Using `Tr` (A short version of `LanguageBuilder`):**

``` dart
Tr((_) => Text('Hello @{name}'.tr)),
```

## Control The Translation

### Change The Language

``` dart
languageHelper.change(LanguageCodes.vi);
```

### Add A New Language Data

``` dart
languageHelper.addData(LanguageDataProvider.data(newLanguageData));
languageHelper.addDataOverrides(LanguageDataProvider.data(newLanguageDataOverrides));
```

The `addData` and `addDataOverrides` have `activate` parameter which automaticaly rebuild all needed `LanguageBuilder`, so notice that you may get the `setState` issue because of the rebuilding of the `LanguageBuilder` when it's still building. If the error occurs, you may need to set it to `false` and activate the new data yourself by using `reload` method.

### Get The List Of Supported Language Code

``` dart
// List of [LanguageCodes] from both of the [data] and [dataOverrides] without duplicated
final codes = languageHelper.codes;

// List of [LanguageCodes] from the [dataOverrides]
final codesOverrides = languageHelper.codesOverrides;
```

### Listen To The Language Changing State

Beside the `onChanged` callback, you can listen to the language changed events by using `stream`:

``` dart
final sub = languageHelper.stream.listen((code) => print(code));
```

**Note:** Remember to `sub.cancel()` when it's not in use to avoid memory leaks.

### Analyze The Translation

**Currently works properly with `LanguageDataProvider.data` method**

``` dart
languageHelper.analyze();
```

This function will automatically be called in `initial` when `isDebug` is `true`.

## Advanced Language Helper Generator

### Modify The Input Path

Add `--path` option to your command:

```shell
dart run language_helper:generate --path=./lib
```

### Modify The Output Path

Add `--output` option to your command:

```shell
dart run language_helper:generate --output=./lib
```

### Convert From `LanguageData` to `JSON`

- Create a `bin` folder in the same level with your `lib`.
- Create a `export_json.dart` file in your `bin`.
- Add this code to your `export_json.dart`:

```dart
void main() {
  test('', () {
    languageData.exportJson('./assets');
  });
}
```

- Add the missing `import`s.
- Run `flutter test ./bin/export_json.dart`.
- The JSON will be generated in this path:

```txt
assets
|  |- language_helper
|  |  |- codes.json
|  |  |  |- languages
|  |  |  |  |- en.json
|  |  |  |  |- vi.json
|  |  |  |  |- ...
```

## Language Data Serialization

Convert `LanguageData` to JSON:

``` dart
final json = data.toJson();
```

Convert JSON to `LanguageData`:

``` dart
final data = LanguageDataSerializer.fromJson(json);
```

## Language Helper Translator (A Custom Chat GPT-4)

- Assume that here is our language data:

```dart
final en = {
  'Hello @{name}': 'Hello @{name}',
  'We have @{number} dollar': LanguageCondition(
    param: 'number',
    conditions: {
      '0': 'We have zero dollar',
      '1': 'We have one dollar',

      // Default value.
      '_': 'We have @{number} dollars',
    }
  ),
};
```

- Go to [Language Helper Translator](https://chat.openai.com/g/g-qoPMopEAb-language-helper-translator). You should open a New Chat a few times to let the AI read the instructions carefully to improve the translation (just my personal experience).
- Use this template to translate the data. Be sure to replace `[]` with the appropriate infomation:

```dart
This is the translation of the [app/game] that [purpose of the app/game to help the AI understand the context]. Translate it into [destination language]:

final en = {
  'Hello @{name}': 'Hello @{name}',
  'We have @{number} dollar': LanguageCondition(
    param: 'number',
    conditions: {
      '0': 'We have zero dollar',
      '1': 'We have one dollar',

      // Default value.
      '_': 'We have @{number} dollars',
    }
  ),
};
```

- The GPT will keeps all keys and comments in their original text, positions them exactly as they appear in the source, keeps the @{param} and @param in their appropriate places during the translation.

## Additional Information

- The app will try to use the `Devicelocale` to set the `initialCode` if it is not set. If the `Devicelocale` is unavailable, it will use the first language in `data` instead.

- No matter how many `LanguageBuilder` that you use, the plugin only rebuilds the outest (the root) widget of `LanguageBuilder`, so it significantly improves performance. If you want to force rebuild some Widget, you can set the `forceRebuild` parameter in the `LanguageBuilder` to `true`.

- The `LanguageCodes` contains all the common languages with additional information like name in English (englishName) and name in native language (nativeName).

- The `@{param}` works in all cases (We should use this way to avoid issues when translating with `Language Helper Translator`). The `@param` only work if the text ends with a white space, end of line, or end with a new line.

- The `addData` and `addDataOverrides` have `activate` parameter which automaticaly rebuild all needed `LanguageBuilder`, so notice that you may get the `setState` issue because of the rebuilding of the `LanguageBuilder` when it's still building. If the error occurs, you may need to set it to `false` and activate the new data yourself by using `reload` method.

## Contributions

As the project is currently in its early stages, it may contain bugs or other issues. Should you experience any problems, we kindly ask that you file an issue to let us know. Additionally, we welcome contributions in the form of pull requests (PRs) to help enhance the project.
