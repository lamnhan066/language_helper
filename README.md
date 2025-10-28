# Language Helper

[![codecov](https://codecov.io/gh/lamnhan066/language_helper/graph/badge.svg?token=AIGGNCGOVR)](https://codecov.io/gh/lamnhan066/language_helper)

A Flutter package for easy multi-language app localization with automatic text extraction and translation support.

## Features

- 🚀 **Easy Setup**: Add `.tr` and `.trP` to any string for instant translation
- 🔍 **Auto Extraction**: Automatically extract all translatable text from your Dart files
- 🎯 **Smart Translation**: Control translations with conditions and parameters
- 🌐 **Multiple Sources**: Support for Dart maps, JSON files, assets, and network data
- 📱 **Device Locale**: Automatically uses device locale on first launch
- 🔧 **GPT-4 Integration**: Custom translator for easy language conversion

## Quick Start

### 1. Add to your project

```bash
flutter pub add language_helper
```

### 2. Initialize (while developing)

```dart
final languageHelper = LanguageHelper.instance;

main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await languageHelper.initial(data: []);
  runApp(const MyApp());
}
```

### 3. Add translations to your strings

```dart
// Simple translation
Text('Hello World'.tr)

// With parameters
Text('Hello @{name}'.trP({'name': 'John'}))

// With conditions
Text('You have @{count} item'.trP({'count': itemCount}))
```

### 4. Wrap your app

```dart
class App extends StatelessWidget {
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

## Generate Translations

The generator automatically scans your project for text using language_helper extensions (`tr`, `trP`, `trT`, `trF`) and `translate` method, then creates organized translation files with your existing translations preserved.

> **Note**: The generator is smart about managing translations:
>
> - ✅ **Keeps existing translations** - Your current translated texts are preserved
> - 🆕 **Marks new texts with TODO** - Only untranslated texts get TODO markers
> - 🗑️ **Removes unused texts** - Automatically cleans up translations no longer used in your code

### Add Generator Dependency

First, add the generator to your `pubspec.yaml`:

```yaml
dev_dependencies:
  language_helper_generator: ^0.7.0
```

Then run:

```bash
flutter pub get
```

### Basic Generation

Extract all translatable text and generate language files:

```bash
dart run language_helper:generate --languages=en,vi,fr --ignore-todo=en
```

This creates:

```txt
lib/languages/
├── codes.dart
└── data/
    ├── en.dart // without TODO markers for missing translations
    ├── vi.dart // with TODO markers for missing translations
    └── fr.dart // with TODO markers for missing translations
```

### JSON Generation

For assets or network-based translations:

```bash
dart run language_helper:generate --languages=en,vi,fr --json
```

Creates:

```txt
assets/languages/
├── codes.json
└── data/
    ├── en.json
    ├── vi.json
    └── fr.json
```

JSON files do not support TODO markers. To identify untranslated or new strings, look for entries where the key and value are identical.

### Generator Options

| Option | Description | Example |
|--------|-------------|---------|
| `--languages` | Language codes to generate | `--languages=en,vi,es` |
| `--ignore-todo` | Skip TODO markers for specific languages | `--ignore-todo=en` |
| `--path` | Custom output directory | `--path=./lib/languages` |
| `--json` | Generate JSON files instead of Dart | `--json` |

### Common Examples

**Skip TODOs in English (your base language):**

```bash
dart run language_helper:generate --languages=en,vi --ignore-todo=en
```

**Custom output path:**

```bash
dart run language_helper:generate --path=./lib/languages --languages=en,vi
```

**Generate for multiple languages:**

```bash
dart run language_helper:generate --languages=en,vi,es,fr --ignore-todo=en
```

## Using Generated Data

### Dart Map

```dart
final languageDataProvider = LanguageDataProvider.lazyData(languageData);

main() async {
  await languageHelper.initial(data: [languageDataProvider]);
  runApp(const MyApp());
}
```

### JSON Assets

```dart
final languageDataProvider = LanguageDataProvider.asset('assets/languages');

main() async {
  await languageHelper.initial(data: [languageDataProvider]);
  runApp(const MyApp());
}
```

### Network Data

```dart
final languageDataProvider = LanguageDataProvider.network('https://api.example.com/translations');

main() async {
  await languageHelper.initial(data: [languageDataProvider]);
  runApp(const MyApp());
}
```

## Manual Translation Setup

### Dart Map Example

```dart
final en = {
  'Hello World': 'Hello World',
  'Hello @{name}': 'Hello @{name}',
  'You have @{count} item': LanguageConditions(
    param: 'count',
    conditions: {
      '1': 'You have one item',
      '_': 'You have @{count} items', // Default
    }
  ),
};

final vi = {
  'Hello World': 'Xin chào thế giới',
  'Hello @{name}': 'Xin chào @{name}',
  'You have @{count} item': 'Bạn có @{count} mục',
};

LazyLanguageData languageData = {
  LanguageCodes.en: () => en,
  LanguageCodes.vi: () => vi,
};
```

### JSON Example

`assets/languages/codes.json`:

```json
["en", "vi"]
```

`assets/languages/data/en.json`:

```json
{
  "Hello World": "Hello World",
  "Hello @{name}": "Hello @{name}",
  "You have @{count} item": {
    "param": "count",
    "conditions": {
      "1": "You have one item",
      "_": "You have @{count} items"
    }
  }
}
```

Don't forget to add to `pubspec.yaml`:

```yaml
flutter:
  assets:
    - assets/languages/codes.json
    - assets/languages/data/
```

## Language Control

### Change Language

```dart
languageHelper.change(LanguageCodes.vi);
```

### Add New Language Data

```dart
languageHelper.addData(LanguageDataProvider.lazyData(newLanguageData));
```

### Listen to Changes

```dart
final sub = languageHelper.stream.listen((code) => print('Language changed to: $code'));
// Remember to cancel: sub.cancel()
```

### Get Supported Languages

```dart
final codes = languageHelper.codes; // All supported languages
final overrides = languageHelper.codesOverrides; // Override languages
```

## Advanced Usage

### Generator Features

- **Fast**: Uses Dart Analyzer, no build_runner dependency
- **Smart**: Preserves existing translations
- **Organized**: Groups translations by file path
- **Helpful**: Adds TODO markers for missing translations
- **Clean**: Removes unused translation keys automatically

### Custom Paths

```bash
# Custom output path
dart run language_helper:generate --path=./lib/languages --languages=en,vi

# Generate JSON to assets folder
dart run language_helper:generate --path=./assets/languages --languages=en,vi --json
```

### Multiple Data Sources

```dart
main() async {
  await languageHelper.initial(
    data: [
      // Assume that our `code.json` in `https://api.example.com/translations/code.json`
      // So our data will be in `https://api.example.com/translations/data/en.json`
      LanguageDataProvider.network('https://api.example.com/translations'),

      // Assume that our `code.json` in `assets/languages/code.json`
      // So our data will be in `assets/languages/en.json`
      LanguageDataProvider.asset('assets/languages'),
      
      LanguageDataProvider.lazyData(localLanguageData),
    ],
  );
  runApp(const MyApp());
}
```

> **Data Priority**: When multiple sources contain the same translation:
>
> - **First source wins** - Data sources are processed in order (top to bottom) for the entire source
> - **Specific overrides** - To override individual translations, use `dataOverrides` instead of adding to `data`
> - **AddData behavior** - New data can overwrite existing translations (controlled by `overwrite` parameter)

### Widget Rebuilding

```dart
LanguageBuilder(
  builder: (context) => Text('Hello'.tr),
)

Tr((_) => Text('Hello'.tr))
```

### Force Rebuild and Tree Refresh

#### `forceRebuild` Parameter

By default, only the root `LanguageBuilder` widget rebuilds when the language changes for better performance. Use `forceRebuild: true` to force a specific widget to always rebuild:

```dart
LanguageBuilder(
  forceRebuild: true, // This widget will always rebuild on language change
  builder: (context) => Text('Hello'.tr),
)
```

- `true` → Always rebuild this widget when language changes
- `false` → Only rebuild the root widget (default behavior)
- `null` → Fallback to `LanguageHelper.forceRebuild` default

#### `refreshTree` Parameter

Use `refreshTree: true` to completely refresh the widget tree using `KeyedSubtree`. This changes the key of the current tree so the entire tree is removed and recreated:

```dart
LanguageBuilder(
  refreshTree: true, // Uses KeyedSubtree to refresh entire tree
  builder: (context) => MyComplexWidget(),
)
```

> **⚠️ Performance Warning**: `refreshTree` causes the entire widget tree to be destroyed and recreated, which can be expensive for complex widgets. This may lead to:
>
> - Loss of widget state and animations
> - Poor performance with large widget trees
> - Unnecessary rebuilds of child widgets
>
> **💡 Note**: If you use `const` widgets nested inside a `LanguageBuilder`, they may not rebuild automatically when the root rebuilds. To ensure these widgets update on language change (without using `refreshTree`), wrap them in their own `LanguageBuilder` with `forceRebuild: true`.

Use `refreshTree` only when you specifically need to reset widget state or when dealing with widgets that don't properly handle language changes.

## GPT-4 Translator

Use the [Language Helper Translator](https://chat.openai.com/g/g-qoPMopEAb-language-helper-translator) for easy translation:

```txt
This is the translation of my Flutter app. Translate it into Spanish:

final en = {
  'Hello @{name}': 'Hello @{name}',
  'Welcome to the app': 'Welcome to the app',
};
```

<details>
<summary>Show GPT instruction</summary>

### Step-by-Step Instructions for Translation

1. Identify the Dart `Map<String, dynamic>` structure and focus only on translating the values, not the keys or structure.
2. Analyze the entire input first to understand its context for the best translation results.
3. Check for plural forms and, if present, restructure using `LanguageConditions`.
4. Translate plural forms: 0 → '0 products', 1 → '1 product', other → '@{count} products'.
5. Translate only the values, leaving keys and structure unchanged.
6. Preserve all comments (`//` and `///`), leaving them untranslated.
7. Do not translate nested comments.
8. Ensure the map structure is maintained after translation, with correct handling of plural forms and comments.

### Example for Plural Grammar Handling

If input is:

```dart
'@{count} sản phẩm': '@{count} sản phẩm'
```

It should generate to the `en` language as:

```dart
'@{count} sản phẩm': LanguageConditions(
  param: 'count',
  conditions: {
    '0': '0 products',
    '1': '1 product',
    '_': '@{count} products',
  },
)
```

### Important Reminders

- Translate only values, never keys.
- Leave comments unchanged.
- Handle plural forms with `LanguageConditions` as needed.

</details>

## iOS Configuration

Add supported localizations to `Info.plist`:

```xml
<key>CFBundleLocalizations</key>
<array>
   <string>en</string>
   <string>vi</string>
</array>
```

## Tips

- Use `@{param}` for parameters (recommended)
- The package automatically uses device locale on first launch
- Only the outermost `LanguageBuilder` rebuilds for better performance
- Use `isInitialized` to check if `initial()` has been called
- Assets are preferred over network data (no caching yet)

## Contributing

Found a bug or want to contribute? Please file an issue or submit a pull request!

## License

This project is licensed under the MIT License.
