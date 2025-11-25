# Language Helper

[![codecov](https://codecov.io/gh/lamnhan066/language_helper/graph/badge.svg?token=AIGGNCGOVR)](https://codecov.io/gh/lamnhan066/language_helper)

A Flutter package for easy multi-language app localization with automatic text extraction and translation support.

## Features

- **Easy Setup**: Add `.tr` and `.trP` to any string for instant translation
- **Auto Extraction**: Automatically extract all translatable text from your Dart files
- **Smart Translation**: Control translations with conditions and parameters
- **Multiple Sources**: Support for Dart maps, JSON files, assets, and network data
- **Device Locale**: Automatically uses device locale on first launch
- **AI Integration**: Custom translator for easy language conversion
- **LanguageScope**: Provide scoped `LanguageHelper` instances to specific widget trees
- **LanguageImprover**: Visual translation editor for on-device translation improvement

## Quick Start

### 1. Add to your project

```bash
flutter pub add language_helper
```

### 2. Initialize

```dart
final languageHelper = LanguageHelper.instance;

main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize with empty data (temporary English fallback for development)
  await languageHelper.initial(data: []);
  
  // Or initialize with your translation data
  // await languageHelper.initial(
  //   data: [
  //     LanguageDataProvider.data(myLanguageData),
  //   ],
  // );
  
  runApp(const MyApp());
}
```

**Initialization Options:**

- `data`: List of `LanguageDataProvider` instances (required)
- `initialCode`: Preferred initial language code
- `isAutoSave`: Automatically save and restore language preference (default: `true`)
- `syncWithDevice`: Sync with device language changes (default: `true`)
- `forceRebuild`: Rebuild all widgets on language change (default: `true`, set to `false` for better performance)
- `isDebug`: Enable debug logging (default: `false`)

### 3. Add translations to your strings

```dart
// Simple translation
Text('Hello World'.tr)

// With parameters
Text('Hello @{name}'.trP({'name': 'John'}))

// With conditions
Text('You have @{count} item'.trP({'count': itemCount}))
```

**Note:** Extension methods (`tr`, `trP`, `trT`, `trF`) work automatically within `LanguageBuilder` widgets. They use an internal stack mechanism to access the correct `LanguageHelper` instance (from `LanguageScope`, explicit parameter, or `LanguageHelper.instance`). When used outside of `LanguageBuilder`, they fall back to `LanguageHelper.instance`.

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
> - **Keeps existing translations** - Your current translated texts are preserved
> - **Marks new texts with TODO** - Only untranslated texts get TODO markers
> - **Removes unused texts** - Automatically cleans up translations no longer used in your code

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
// Using lazy data (functions called when language is accessed)
final languageDataProvider = LanguageDataProvider.lazyData(languageData);

// Using direct data (synchronous, fastest)
final directProvider = LanguageDataProvider.data(languageData);

// With override enabled
final overrideProvider = LanguageDataProvider.data(
  overrideData,
  override: true, // Overwrites existing translations
);

main() async {
  await languageHelper.initial(data: [languageDataProvider]);
  runApp(const MyApp());
}
```

**Performance Considerations:**

- `LanguageDataProvider.data`: Fastest (synchronous, no I/O) - Use for static or pre-loaded translations
- `LanguageDataProvider.lazyData`: Fast (synchronous function calls) - Use when you want to defer loading until a language is first accessed
- `LanguageDataProvider.asset`: Medium (async I/O, but bundled with app) - Use for bundled JSON translations
- `LanguageDataProvider.network`: Slowest (async network requests) - Use for remote translations, consider caching for production

### JSON Assets

```dart
// Basic usage
final languageDataProvider = LanguageDataProvider.asset('assets/languages');

// With override disabled (preserve existing translations)
final preserveProvider = LanguageDataProvider.asset(
  'assets/languages',
  override: false, // Only adds new keys, preserves existing ones
);

main() async {
  await languageHelper.initial(data: [languageDataProvider]);
  runApp(const MyApp());
}
```

**Important:**

- Make sure to add the assets to your `pubspec.yaml`:

```yaml
flutter:
  assets:
    - assets/languages/
    - assets/languages/data/
```

- **Directory structure**: The `parentPath` should contain `codes.json` and a `data/` subdirectory:

```txt
assets/languages/
├── codes.json          (List of language codes: ["en", "vi", ...])
└── data/
    ├── en.json         (English translations)
    ├── vi.json         (Vietnamese translations)
    └── ...
```

- **Error handling**: If an asset file is missing, the provider returns empty data for that language without throwing exceptions

### Network Data

```dart
// Basic usage
final languageDataProvider = LanguageDataProvider.network('https://api.example.com/translations');

// With authentication headers
final authenticatedProvider = LanguageDataProvider.network(
  'https://api.example.com/translations',
  headers: {
    'Authorization': 'Bearer token',
    'X-API-Key': 'your-api-key',
  },
);

// With custom HTTP client (for timeouts, retries, etc.)
final client = http.Client();
client.timeout = const Duration(seconds: 10);
final customClientProvider = LanguageDataProvider.network(
  'https://api.example.com/translations',
  client: client,
  override: true, // Overwrites existing translations
);

main() async {
  await languageHelper.initial(data: [languageDataProvider]);
  runApp(const MyApp());
}
```

**Important Notes:**

- **URL structure**: The `parentUrl` should contain `codes.json` and a `data/` subdirectory:
  - `https://api.example.com/translations/codes.json`
  - `https://api.example.com/translations/data/en.json`
  - `https://api.example.com/translations/data/vi.json`

- **On-demand loading**: Network providers load data on-demand when a language is first accessed. Each language file is fetched separately, so switching languages may cause network delays.

- **Error handling**: If a network request fails (network error, timeout, non-200 status), the provider returns empty data for that language without throwing exceptions. This allows your app to continue functioning even if some translations fail to load.

- **Performance**: Consider implementing caching strategies for production apps to improve performance and reduce network usage.

- **Security**: When using authentication headers, be careful not to expose sensitive credentials in client-side code. Consider using secure storage or environment variables.

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
// Change to Vietnamese
await languageHelper.change(LanguageCodes.vi);

// All LanguageBuilder widgets will automatically update
```

**Behavior:**

- If the requested language is not available:
  - By default: The change is ignored and the current language remains unchanged
  - If `useInitialCodeWhenUnavailable: true`: Falls back to the initial code if available

**Performance:**

- For `data` and `lazyData` providers: Fast (synchronous)
- For `asset` providers: Medium (async I/O, but cached after first load)
- For `network` providers: Slow (async network request, depends on connection)

**Auto-save:** If `isAutoSave: true` (default), the new language is automatically saved to SharedPreferences and will be restored on the next app launch.

### Add or Remove Language Data Providers

```dart
// Add a new provider (will activate immediately by default)
final newProvider = LanguageDataProvider.data(newTranslations);
await languageHelper.addProvider(newProvider);

// Add provider without immediate activation
await languageHelper.addProvider(
  LanguageDataProvider.lazyData(newLanguageData),
  activate: false,
);
// ... do other operations ...
await languageHelper.reload(); // Activate now

// Remove a provider
await languageHelper.removeProvider(oldProvider);

// Remove without immediate activation
await languageHelper.removeProvider(
  oldProvider,
  activate: false,
);
await languageHelper.reload(); // Update widgets now
```

**Note:**

- The `override` property of the provider controls whether new translations overwrite existing ones. Use `LanguageDataProvider.data(translations, override: true)` to overwrite existing translations.
- Providers are added to the end of the providers list. Later providers with `override: true` will overwrite earlier ones.
- When `activate: false`, data is added/removed but widgets won't update until `reload()` or `change()` is called.
- Be careful not to call `addProvider` or `removeProvider` with `activate: true` during widget build, as it may cause `setState` errors.

### Listen to Changes

```dart
// Simple listener
final sub = languageHelper.stream.listen((code) => print('Language changed to: $code'));
// Remember to cancel: sub.cancel()

// In a StatefulWidget
StreamSubscription<LanguageCodes>? _subscription;

@override
void initState() {
  super.initState();
  _subscription = languageHelper.stream.listen((code) {
    setState(() {
      // Update state based on language change
    });
  });
}

@override
void dispose() {
  _subscription?.cancel(); // Important: cancel to avoid memory leaks
  super.dispose();
}
```

**Note:** The stream emits the new language code after all `LanguageBuilder` widgets have been notified to rebuild. Remember to cancel subscriptions to avoid memory leaks.

### Get Supported Languages

```dart
// Get all supported language codes from all providers
final codes = languageHelper.codes; // Set<LanguageCodes>

// Get all supported locales (for MaterialApp/CupertinoApp)
final locales = languageHelper.locales; // Set<Locale>

// Get current language
final currentCode = languageHelper.code; // LanguageCodes
final currentLocale = languageHelper.locale; // Locale

// Check if a language is available
if (languageHelper.codes.contains(LanguageCodes.vi)) {
  await languageHelper.change(LanguageCodes.vi);
}

// Access all loaded translation data
final allData = languageHelper.data; // LanguageData
final englishTranslations = allData[LanguageCodes.en];
```

**Important:**

- You must call `await initial()` before accessing these properties
- `codes` returns all language codes from all registered providers
- `data` only contains languages that have been loaded so far (for lazy/network providers, languages are loaded on-demand)

### Integrating with Flutter Localizations

To use `LanguageHelper` and `LanguageDelegate` in your Flutter app, set up the `localizationsDelegates` and `supportedLocales` in your `MaterialApp`. You can manage multiple helpers for different parts of your app (e.g., in a package).

```dart
// The main app's LanguageHelper (singleton)
final mainHelper = LanguageHelper.instance;

// For a specific package/widget tree, use a dedicated helper if needed
final packageHelper = LanguageHelper('PackageWidget');

return MaterialApp(
  localizationsDelegates: [
    // Flutter's built-in localizations
    ...mainHelper.delegates,

    // Language delegate for the package/widget tree
    LanguageDelegate(packageHelper),

    // Optionally, you can add more delegates here
  ],
  supportedLocales: mainHelper.locales,
  locale: mainHelper.locale,
  // ...
);
```

Now, both your main app and `PackageWidget` will automatically update languages together when you change the locale via `LanguageHelper`. For more advanced use cases and examples, see the example app.

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
> - **Provider order matters** - Data sources are processed in the order they're added (first to last)
> - **Override property** - Providers with `override: true` (default) will overwrite existing translations with the same keys from earlier providers
> - **Preserve existing** - When `override: false`, only new translation keys are added; existing keys from earlier providers are preserved
> - **Adding providers** - New providers added via `addProvider` are appended to the end of the list. Later providers with `override: true` will overwrite earlier ones
> - **Performance** - Use `data` or `lazyData` providers for best performance. Network providers load on-demand and may cause delays when switching languages

### Widget Rebuilding

```dart
LanguageBuilder(
  builder: (context) => Text('Hello'.tr),
)

Tr((_) => Text('Hello'.tr))
```

### Force Rebuild and Tree Refresh

#### `forceRebuild` Parameter

By default, all `LanguageBuilder` widgets rebuild when the language changes. You can control this behavior globally via `LanguageHelper.initial(forceRebuild: false)` or per-widget using the `forceRebuild` parameter:

```dart
LanguageBuilder(
  forceRebuild: false, // Only rebuild the root widget for better performance
  builder: (context) => Text('Hello'.tr),
)
```

- `true` → Always rebuild this widget when language changes (default)
- `false` → Only rebuild the root widget (better performance)
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
> **💡 Note**: If you use `const` widgets nested inside a `LanguageBuilder` and have `forceRebuild: false`, they may not rebuild automatically when the root rebuilds. To ensure these widgets update on language change (without using `refreshTree`), either keep the default `forceRebuild: true` or wrap them in their own `LanguageBuilder` with `forceRebuild: true`.

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
2. **Extension methods** (`tr`, `trP`, `trT`, `trF`) - Use the scoped helper when called within a `LanguageBuilder`. When called outside a `LanguageBuilder`, they fall back to `LanguageHelper.instance` (which is always available)
3. **Priority order**: Explicit `languageHelper` parameter > `LanguageScope` > `LanguageHelper.instance`

#### Extension Methods and the Stack System

Extension methods (`tr`, `trP`, `trT`, `trF`) work seamlessly with scoped helpers through an internal stack mechanism:

**How the Stack Works:**

- When `LanguageBuilder` builds, it pushes its helper onto a stack before calling the builder function
- Extension methods access the helper at the top of the stack via `LanguageHelper._current`
- After the build completes, the helper is popped from the stack
- This allows extension methods to work with scoped helpers even though they don't have `BuildContext`

**Extension Methods Behavior:**

- **Inside `LanguageBuilder`**: Use the helper from the stack (which comes from `LanguageScope`, explicit parameter, or `LanguageHelper.instance`)
- **Outside `LanguageBuilder`**: Fall back to `LanguageHelper.instance` (always available)
- **Nested `LanguageBuilder` widgets**: Each builder pushes its helper during build, allowing nested builders to use different helpers correctly

This ensures that extension methods never fail and always have a helper to work with, making them safe to use anywhere in your code.

**Example with Nested Builders:**

```dart
LanguageScope(
  languageHelper: parentHelper,
  child: LanguageBuilder(
    builder: (context) => Column(
      children: [
        Text('Parent'.tr), // Uses parentHelper from stack
        LanguageBuilder(
          languageHelper: childHelper, // Explicit helper
          builder: (context) => Text('Child'.tr), // Uses childHelper from stack
        ),
      ],
    ),
  ),
)
```

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
// Always returns a valid helper since LanguageHelper.instance is always available
final helper = LanguageHelper.of(context);
final translated = helper.translate('Hello');
```

**Note:** `LanguageHelper.of(context)` does not register a dependency on `LanguageScope`, so widgets using it won't automatically rebuild when the scope changes. If you need automatic rebuilds, wrap your widget in a `LanguageBuilder` instead. When no `LanguageScope` is found, a warning is logged once per context (when debug logging is enabled) to help developers understand that the default `LanguageHelper.instance` is being used.

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

[`LanguageImprover`](https://pub.dev/packages/language_improver) is a widget that provides a user-friendly interface for viewing, comparing, and editing translations. It's perfect for translators, QA teams, or anyone who needs to improve translations directly in the app.

#### Features

- 📝 **Side-by-side comparison**: View reference and target translations together
- 🔍 **Search functionality**: Quickly find translations by key or content
- ✏️ **Inline editing**: Edit translations directly in the interface
- 📌 **Auto-scroll**: Automatically scroll to specific translation keys
- 💾 **Update callback**: Receive updated translations via callback
- 🎯 **Flash animation**: Visual highlight for keys being focused

#### Basic Usage

```cmd
dart pub add language_improver
```

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
      
      // Add translations as overrides (using addProvider)
      await LanguageHelper.instance.addProvider(provider);
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

- **Parameter format**: Use `@{param}` for parameters (recommended over `@param`)
- **Device locale**: The package automatically uses device locale on first launch (if `syncWithDevice: true`)
- **Performance**:
  - All `LanguageBuilder` widgets rebuild by default when language changes. Set `forceRebuild: false` in `LanguageHelper.initial()` or per-widget for better performance
  - Use `LanguageDataProvider.data` for fastest performance (synchronous, no I/O)
  - Network providers load on-demand and may cause delays when switching languages
- **Initialization**:
  - Use `isInitialized` to check if `initial()` has been called
  - Use `ensureInitialized` to wait for initialization to complete
  - Always await `initial()` before accessing `code`, `data`, or `codes`
- **Data sources**:
  - Assets are preferred over network data for faster loading
  - Network providers load on-demand when a language is first accessed
  - Consider implementing caching strategies for network providers in production
- **Provider override**:
  - Use `override: true` (default) when creating providers to overwrite existing translations
  - Use `override: false` to only add new keys and preserve existing translations
- **Adding/removing providers**:
  - Use `addProvider` with `activate: false` to batch multiple additions, then call `reload()` once
  - Be careful not to call `addProvider`/`removeProvider` with `activate: true` during widget build
- **Memory**:
  - Only languages that have been accessed are loaded into memory (for lazy/network providers)
  - Use lazy loading for large translation sets or when users typically use only a few languages
- **Multiple providers**:
  - Providers are processed in order (first to last)
  - Later providers with `override: true` will overwrite earlier providers' translations
  - Combine different provider types (data, asset, network) for flexible translation management

## Contributing

Found a bug or want to contribute? Please file an issue or submit a pull request!

## License

This project is licensed under the MIT License.
