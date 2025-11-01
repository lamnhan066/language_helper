# Language Helper

[![codecov](https://codecov.io/gh/lamnhan066/language_helper/graph/badge.svg?token=AIGGNCGOVR)](https://codecov.io/gh/lamnhan066/language_helper)

A Flutter package for easy multi-language app localization with automatic text extraction and translation support.

## Features

- 🚀 **Easy Setup**: Add `.tr` and `.trP` to any string for instant translation
- 🔍 **Auto Extraction**: Automatically extract all translatable text from your Dart files
- 🎯 **Smart Translation**: Control translations with conditions and parameters
- 🌐 **Multiple Sources**: Support for Dart maps, JSON files, assets, and network data
- 📱 **Device Locale**: Automatically uses device locale on first launch
- 🔧 **AI Integration**: Custom translator for easy language conversion
- 🎨 **LanguageScope**: Provide scoped `LanguageHelper` instances to specific widget trees
- ✏️ **LanguageImprover**: Visual translation editor for on-device translation improvement

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

### LanguageScope - Scoped LanguageHelper

`LanguageScope` allows you to provide a custom `LanguageHelper` instance to a specific part of your widget tree. When you wrap a widget tree with `LanguageScope`, all `tr`, `trP`, `LanguageBuilder`, and `Tr` widgets within that scope will automatically use the scoped helper instead of `LanguageHelper.instance`.

#### Basic Usage

```dart
final customHelper = LanguageHelper('CustomHelper');
await customHelper.initial(
  data: customLanguageData,
  initialCode: LanguageCodes.es,
);

LanguageScope(
  languageHelper: customHelper,
  child: MyWidget(),
)
```

#### How It Works

When `LanguageScope` is present in the widget tree:

1. **LanguageBuilder and Tr** - Automatically inherit the scoped helper (unless an explicit `languageHelper` is provided)
2. **Extension methods** (`tr`, `trP`, `trT`, `trF`) - Use the scoped helper when called within a `LanguageBuilder`
3. **Priority order**: Explicit `languageHelper` parameter > `LanguageScope` > `LanguageHelper.instance`

#### Example: Scoped Translation

```dart
final adminHelper = LanguageHelper('AdminHelper');
final userHelper = LanguageHelper('UserHelper');

await adminHelper.initial(data: adminTranslations, initialCode: LanguageCodes.en);
await userHelper.initial(data: userTranslations, initialCode: LanguageCodes.vi);

// Admin section uses admin translations
LanguageScope(
  languageHelper: adminHelper,
  child: LanguageBuilder(
    builder: (context) => Column(
      children: [
        Text('Admin Panel'.tr), // Uses adminHelper
        Text('Manage Users'.trP({'count': 5})), // Uses adminHelper
      ],
    ),
  ),
)

// User section uses user translations
LanguageScope(
  languageHelper: userHelper,
  child: LanguageBuilder(
    builder: (context) => Column(
      children: [
        Text('Dashboard'.tr), // Uses userHelper
        Text('Welcome @{name}'.trP({'name': 'John'})), // Uses userHelper
      ],
    ),
  ),
)
```

#### Accessing Scoped Helper

You can access the scoped helper directly from context:

```dart
// Gets the scoped helper or falls back to LanguageHelper.instance
final helper = LanguageScope.of(context);
final translated = helper.translate('Hello');

// Gets the scoped helper or returns null
final helper = LanguageScope.maybeOf(context);
if (helper != null) {
  final translated = helper.translate('Hello');
}
```

#### Priority with Explicit Helper

If you provide an explicit `languageHelper` parameter, it takes priority over the scope:

```dart
LanguageScope(
  languageHelper: scopedHelper, // This will be ignored
  child: LanguageBuilder(
    languageHelper: explicitHelper, // This takes priority
    builder: (_) => Text('Hello'.tr), // Uses explicitHelper
  ),
)
```

#### Nested Scopes

Child scopes override parent scopes for their subtree:

```dart
LanguageScope(
  languageHelper: parentHelper, // Parent scope
  child: LanguageBuilder(
    builder: (_) => Column(
      children: [
        Text('Hello'.tr), // Uses parentHelper
        LanguageScope(
          languageHelper: childHelper, // Child scope overrides parent
          child: LanguageBuilder(
            builder: (_) => Text('Hello'.tr), // Uses childHelper
          ),
        ),
      ],
    ),
  ),
)
```

#### Tr Widget with Scope

The `Tr` widget also inherits from `LanguageScope`:

```dart
LanguageScope(
  languageHelper: scopedHelper,
  child: Tr((_) => Text('Hello'.tr)), // Uses scopedHelper
)
```

#### Use Cases

- **Multi-tenant apps**: Different translation sets for different user types
- **Feature modules**: Separate translations for different app modules
- **A/B testing**: Different translations for different user groups
- **Admin panels**: Specialized translations for admin interfaces
- **Overrides**: Temporarily override translations in specific sections

### LanguageImprover - Visual Translation Editor

`LanguageImprover` is a widget that provides a user-friendly interface for viewing, comparing, and editing translations. It's perfect for translators, QA teams, or anyone who needs to improve translations directly in the app.

#### Features

- 📝 **Side-by-side comparison**: View reference and target translations together
- 🔍 **Search functionality**: Quickly find translations by key or content
- ✏️ **Inline editing**: Edit translations directly in the interface
- 📌 **Auto-scroll**: Automatically scroll to specific translation keys
- 💾 **Update callback**: Receive updated translations via callback
- 🎯 **Flash animation**: Visual highlight for keys being focused

#### Basic Usage

```dart
LanguageImprover(
  languageHelper: LanguageHelper.instance,
  onTranslationsUpdated: (updatedTranslations) {
    // Handle the improved translations
    // updatedTranslations: Map<LanguageCodes, Map<String, dynamic>>
    for (final entry in updatedTranslations.entries) {
      final code = entry.key;
      final translations = entry.value;
      
      // Create a LanguageDataProvider from updated translations
      final provider = LanguageDataProvider.data({
        code: translations,
      });
      
      // Add translations as overrides
      LanguageHelper.instance.addDataOverrides(provider);
    }
  },
)
```

#### Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| `languageHelper` | `LanguageHelper?` | The LanguageHelper instance to use. Defaults to `LanguageHelper.instance` |
| `onTranslationsUpdated` | `FutureOr<void> Function(Map<LanguageCodes, Map<String, dynamic>>)?` | Callback called when translations are saved. Receives a map of language codes to updated translations |
| `onCancel` | `VoidCallback?` | Callback called when the user cancels editing |
| `initialDefaultLanguage` | `LanguageCodes?` | Initial reference language. Defaults to first available language |
| `initialTargetLanguage` | `LanguageCodes?` | Initial target language to improve. Defaults to current language |
| `scrollToKey` | `String?` | Key to automatically scroll to and focus on |
| `autoSearchOnScroll` | `bool` | Whether to automatically search for `scrollToKey`. Defaults to `true` |
| `showKey` | `bool` | Whether to show the translation key. Defaults to `true` |

#### Example: Navigate and Open

```dart
ElevatedButton(
  onPressed: () {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => LanguageImprover(
          languageHelper: LanguageHelper.instance,
          initialDefaultLanguage: LanguageCodes.en,
          initialTargetLanguage: LanguageCodes.vi,
          scrollToKey: 'Hello World', // Automatically scroll to this key
          onTranslationsUpdated: (updatedTranslations) {
            // Apply updated translations
            for (final entry in updatedTranslations.entries) {
              final provider = LanguageDataProvider.data({
                entry.key: entry.value,
              });
              LanguageHelper.instance.addDataOverrides(provider);
            }
            
            // Show success message
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Translations updated!'.tr),
                backgroundColor: Colors.green,
              ),
            );
          },
          onCancel: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Translation editing cancelled.'.tr),
              ),
            );
          },
        ),
      ),
    );
  },
  child: Text('Improve Translations'.tr),
)
```

#### Example: Scroll to Specific Key

```dart
LanguageImprover(
  languageHelper: LanguageHelper.instance,
  scrollToKey: 'Welcome Message', // Scrolls to this key on load
  autoSearchOnScroll: true, // Automatically filters to this key
  onTranslationsUpdated: (translations) {
    // Handle updates
  },
)
```

#### Example: Hide Translation Keys

```dart
LanguageImprover(
  languageHelper: LanguageHelper.instance,
  showKey: false, // Hide translation keys, only show translations
  onTranslationsUpdated: (translations) {
    // Handle updates
  },
)
```

#### Use Cases

- **Translation QA**: Review and improve translations before release
- **On-device editing**: Allow translators to edit translations directly on device
- **Debugging**: Quickly find and fix translation issues
- **Localization workflows**: Integrate translation improvement into your workflow
- **User feedback**: Let users suggest translation improvements

## AI Translator

Use the [Language Helper Translator](https://chat.openai.com/g/g-qoPMopEAb-language-helper-translator) in Chat-GPT for easy translation:

```txt
This is the translation of my Flutter app. Translate it into Spanish:

final en = {
  'Hello @{name}': 'Hello @{name}',
  'Welcome to the app': 'Welcome to the app',
};
```

<details>
<summary>Or using AI instruction</summary>

  ````md
  # Step-by-Step Instructions for Translation using language_helper package

  1. Identify the Dart `Map<String, dynamic>` structure and focus only on translating the values — do not modify the keys or overall structure.
  2. Review the entire input first to understand its context and ensure the most accurate translation. If the target language is not `en`, and the keys are not in English, and an `en.dart` file exists in the same folder, use it as a reference to maintain contextual consistency.
  3. Translate only the values that have a `TODO` comment directly above them. Leave all other values unchanged.
  4. Check for plural forms and, if found, convert them using `LanguageConditions`.
  5. When translating plural forms, follow this pattern: 0 → '0 products', 1 → '1 product', other → '@{count} products'.
  6. Translate only the values; keep all keys and structure unchanged.
  7. Preserve all comments (`//` and `///`) exactly as they are — do not translate them.
  8. Do not translate nested comments.
  9. Ensure the map structure remains intact after translation, including proper handling of plural forms and comments.
  10. Remove any TODO notes associated with the translated texts.
  11. Try to keep the translation length similar to the original text (not required, but preferred for consistency).
  12. Do not ask the user for any confirmation or permission — perform the translation directly with best effort to achieve the most accurate and natural results.
  13. After completing the translation, provide the user with a short summary or note explaining any important details about the translation (e.g., ambiguous meanings, context-based choices, or plural handling).

  ### Example for Plural Grammar Handling

  If the input is:

  ```dart
  '@{count} sản phẩm': '@{count} sản phẩm'
  ```

  It should be generated in the `en` language as:

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

  * Only translate values with a `TODO` comment above them.
  * Never modify keys or comments.
  * Do not ask for user permission — always proceed with best effort.
  * Use `LanguageConditions` for plural handling when applicable.
  * Remove TODO notes for translated entries.
  * Keep translation length roughly similar to the original text for readability and layout consistency.
  * Provide a brief translation note after completion if needed.
  ````

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
