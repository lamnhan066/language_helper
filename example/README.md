# Language Helper Example

This is a comprehensive example demonstrating all features of the `language_helper` Flutter package.

## Features Demonstrated

### 🏠 **Home Page**
- Overview of all language_helper features
- Language statistics and current locale information
- Quick language switching
- Translation examples with different types

### 🗺️ **Dart Map Example**
- Using Dart maps as translation data source
- Simple and conditional translations
- Code examples for implementation

### 📁 **JSON Asset Example**
- Loading translations from JSON files in assets
- Separate LanguageHelper instance
- Asset-based translation management

### 🌐 **Network Data Example**
- Simulating network-based translations
- Loading states and error handling
- Mock network data implementation

### 🔄 **Multiple Sources Example**
- Combining multiple data sources
- Data source priority management
- Dynamic data addition and removal
- Real-time translation updates

### ⚡ **Advanced Features**
- Complex conditional translations
- Language change listeners
- Dynamic parameter injection
- Advanced LanguageConditions usage

## Getting Started

### Prerequisites
- Flutter SDK (>=3.29.0)
- Dart SDK (^3.7.0)

### Installation

1. Clone the repository:
```bash
git clone https://github.com/lamnhan066/language_helper.git
cd language_helper/example
```

2. Install dependencies:
```bash
flutter pub get
```

3. Run the example:
```bash
flutter run
```

## Project Structure

```
example/
├── lib/
│   ├── main.dart                    # Main app with navigation
│   ├── data/
│   │   └── language_data.dart       # Dart map language data
│   └── pages/
│       ├── dart_map_page.dart       # Dart map example
│       ├── json_asset_page.dart     # JSON asset example
│       ├── network_data_page.dart   # Network data example
│       ├── multiple_sources_page.dart # Multiple sources example
│       └── advanced_features_page.dart # Advanced features
├── assets/
│   └── languages/
│       ├── codes.json               # Language codes
│       └── data/
│           ├── en.json              # English translations
│           ├── vi.json              # Vietnamese translations
│           ├── es.json              # Spanish translations
│           └── fr.json               # French translations
├── test/
│   └── widget_test.dart             # Widget tests
└── pubspec.yaml                     # Dependencies
```

## Key Concepts Demonstrated

### 1. **Data Sources**
- **Dart Maps**: Direct translation data in code
- **JSON Assets**: Translation files in assets folder
- **Network Data**: Remote translation loading
- **Multiple Sources**: Combining different data sources

### 2. **Translation Types**
- **Simple**: Basic string translation
- **Parameter**: Translation with dynamic parameters
- **Conditional**: Translation based on parameter values

### 3. **Advanced Features**
- **LanguageConditions**: Complex conditional logic
- **Stream Listeners**: Reacting to language changes
- **Dynamic Data**: Adding/removing translations at runtime
- **Multiple Instances**: Separate LanguageHelper instances

## Code Examples

### Basic Setup
```dart
// Initialize LanguageHelper
await LanguageHelper.instance.initial(
  data: [LanguageDataProvider.lazyData(languageData)],
);

// Use in MaterialApp
MaterialApp(
  localizationsDelegates: LanguageHelper.instance.delegates,
  supportedLocales: LanguageHelper.instance.locales,
  locale: LanguageHelper.instance.locale,
  home: MyHomePage(),
)
```

### Simple Translation
```dart
Text('Hello World'.tr)
```

### Parameter Translation
```dart
Text('Hello @{name}'.trP({'name': 'John'}))
```

### Conditional Translation
```dart
Text('You have @{count} item'.trP({'count': itemCount}))
```

### Complex Conditions
```dart
'You have @{count} item': LanguageConditions(
  param: 'count',
  conditions: {
    '0': 'You have no items',
    '1': 'You have one item',
    '_': 'You have @{count} items',
  },
),
```

### Language Change Listener
```dart
languageHelper.stream.listen((newCode) {
  print('Language changed to: $newCode');
});
```

### Multiple Data Sources
```dart
await languageHelper.initial(
  data: [
    LanguageDataProvider.lazyData(primaryData),
    LanguageDataProvider.asset('assets/languages'),
    LanguageDataProvider.network('https://api.example.com/translations'),
  ],
);
```

## Testing

Run the tests to see how language_helper works:

```bash
flutter test
```

The tests cover:
- App initialization
- Language switching
- Navigation between pages
- Translation functionality
- LanguageHelper integration

## Contributing

This example is part of the language_helper package. To contribute:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## License

This example is licensed under the MIT License, same as the main language_helper package.
