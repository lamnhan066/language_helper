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
await LanguageHelper.instance.initial([
  LanguageDataProvider.lazyData(languageData),
]);

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
await languageHelper.initial([
  LanguageDataProvider.lazyData(primaryData),
  LanguageDataProvider.asset('assets/languages'),
  LanguageDataProvider.network('https://api.example.com/translations'),
]);
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

## 🎨 UI/UX Improvements (Latest)

The example app has been significantly enhanced with a modern, professional design following Material Design 3 principles:

### Design System
- **Modern Color Palette**: Primary blue (#2563EB) with purple accents for visual hierarchy
- **Gradient Headers**: Eye-catching gradient backgrounds on hero sections (blue, green, purple, cyan, pink variants)
- **Consistent Typography**: Better font weights and sizes for improved readability
- **Spacing & Padding**: Optimized spacing for visual balance (20px padding in cards, 16px section gaps)
- **Rounded Corners**: 12px radius for cards, 8px for icons, 10px for code blocks

### Visual Components

#### Cards & Containers
- Elevated cards with subtle shadows (elevation: 2)
- Colored icon badges with transparent backgrounds for section headers
- Code examples in dark theme (#1F2937) with light text for better contrast
- Colored example boxes with brand-specific tints (blue, green, orange, purple, pink variants)

#### Navigation & Actions
- Clean white AppBar with no elevation
- Colored bottom navigation with selected item highlighting
- Button styling with rounded corners and consistent spacing
- Language selection with check-circle icons for active states

#### States & Feedback
- Enhanced loading states with larger progress indicators
- Improved error states with colored containers and action buttons
- Success banners with icons and appropriate color coding
- Floating SnackBars with custom styling and border radius

### Page-Specific Improvements

#### Home Page
- **Gradient Hero Card**: Welcome message with blue-to-purple gradient
- **Statistics Card**: Well-organized language information with icons
- **Translation Examples**: Color-coded example containers
- **Language Switcher**: Icon-based buttons with visual feedback

#### Dart Map Page
- Blue gradient header with map icon
- Features list with checkmark indicators
- Translation examples in light blue tinted boxes
- Dark code block with syntax-friendly styling

#### JSON Asset Page
- Green gradient header with folder icon
- Improved loading state with descriptive text
- Translation examples in light green containers
- Better code formatting with proper line height

#### Network Data Page
- Cyan gradient header with cloud icon
- Enhanced loading and error states
- Success banner with check-circle icon
- Orange-tinted translation examples
- Refresh button in app bar for data reload

#### Multiple Sources Page
- Purple gradient header with source icon
- Priority indicator with numbered badges
- Data source hierarchy visualization
- Purple-tinted translation examples
- Interactive add/remove buttons with icons
- Floating SnackBars for user feedback

#### Advanced Features Page
- Pink gradient hero with auto_awesome icon
- Color-coded sections for different features
- Organized conditional translations with group headers
- Parameter injection examples with amber accents
- Language change listener with cyan styling
- Statistics display with green indicators
- Dark code blocks for advanced examples

### Best Practices Implemented
✅ Material Design 3 compliance
✅ Consistent color theming across all pages
✅ Improved visual hierarchy with icons and colors
✅ Better error and loading state UX
✅ Responsive padding and spacing
✅ Accessible color contrasts
✅ Professional code block styling
✅ Smooth transitions and visual feedback
