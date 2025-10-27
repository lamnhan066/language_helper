import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:language_helper/language_helper.dart';

import 'languages/codes.dart';
import 'pages/advanced_features_page.dart';
import 'pages/dart_map_page.dart';
import 'pages/json_asset_page.dart';
import 'pages/multiple_sources_page.dart';
import 'pages/network_data_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize LanguageHelper with Dart map data
  await LanguageHelper.instance.initial(
    data: [LanguageDataProvider.lazyData(languageData)],
    initialCode: LanguageCodes.en,
    isDebug: !kReleaseMode,
  );

  runApp(const LanguageHelperDemoApp());
}

class LanguageHelperDemoApp extends StatelessWidget {
  const LanguageHelperDemoApp({super.key});

  @override
  Widget build(BuildContext context) => LanguageBuilder(
    builder:
        (context) => MaterialApp(
          key: UniqueKey(), // Rebuild the app when the language is changed
          title: 'Language Helper Demo'.tr,
          theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
          localizationsDelegates: LanguageHelper.instance.delegates,
          supportedLocales: LanguageHelper.instance.locales,
          locale: LanguageHelper.instance.locale,
          home: const HomePage(),
        ),
  );
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const HomeContent(),
    const DartMapPage(),
    const JsonAssetPage(),
    const NetworkDataPage(),
    const MultipleSourcesPage(),
    const AdvancedFeaturesPage(),
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text('Language Helper Demo'.tr),
      actions: [
        PopupMenuButton<LanguageCodes>(
          icon: const Icon(Icons.language),
          onSelected: LanguageHelper.instance.change,
          itemBuilder:
              (context) =>
                  LanguageHelper.instance.codes
                      .map(
                        (code) => PopupMenuItem<LanguageCodes>(
                          value: code,
                          child: Row(
                            children: [
                              Text(_getLanguageName(code)),
                              if (LanguageHelper.instance.code == code)
                                const Icon(Icons.check, color: Colors.blue),
                            ],
                          ),
                        ),
                      )
                      .toList(),
        ),
      ],
    ),
    body: IndexedStack(index: _selectedIndex, children: _pages),
    bottomNavigationBar: BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: _selectedIndex,
      onTap: (index) => setState(() => _selectedIndex = index),
      items: [
        BottomNavigationBarItem(icon: const Icon(Icons.home), label: 'Home'.tr),
        BottomNavigationBarItem(
          icon: const Icon(Icons.map),
          label: 'Dart Map Example'.tr,
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.folder),
          label: 'JSON Asset Example'.tr,
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.cloud),
          label: 'Network Data Example'.tr,
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.layers),
          label: 'Multiple Sources Example'.tr,
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.settings),
          label: 'Advanced Features'.tr,
        ),
      ],
    ),
  );

  String _getLanguageName(LanguageCodes code) {
    switch (code) {
      case LanguageCodes.en:
        return 'English'.tr;
      case LanguageCodes.vi:
        return 'Vietnamese'.tr;
      case LanguageCodes.es:
        return 'Spanish'.tr;
      case LanguageCodes.fr:
        return 'French'.tr;
      default:
        return code.name;
    }
  }
}

class HomeContent extends StatelessWidget {
  const HomeContent({super.key});

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome to Language Helper'.tr,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  'This is a comprehensive example'.tr,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Language Information Card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Language Statistics'.tr,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                _buildInfoRow(
                  'Current language'.tr,
                  LanguageHelper.instance.code.name,
                ),
                _buildInfoRow(
                  'Supported Languages'.tr,
                  LanguageHelper.instance.codes.map((e) => e.name).join(', '),
                ),
                _buildInfoRow(
                  'Current Locale'.tr,
                  LanguageHelper.instance.locale.toString(),
                ),
                _buildInfoRow(
                  'Device Locale'.tr,
                  Localizations.localeOf(context).toString(),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Translation Examples Card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Translation Examples'.tr,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),

                // Simple Translation
                _buildExampleSection(
                  'Simple Translation'.tr,
                  'Hello @{name}'.trP({'name': 'World'}),
                ),

                // Parameter Translation
                _buildExampleSection(
                  'Parameter Translation'.tr,
                  'Hello @{name}'.trP({'name': 'Flutter'}),
                ),

                // Conditional Translation
                _buildExampleSection(
                  'Conditional Translation'.tr,
                  'You have @{count} item'.trP({'count': 0}),
                ),
                _buildExampleSection(
                  '',
                  'You have @{count} item'.trP({'count': 1}),
                ),
                _buildExampleSection(
                  '',
                  'You have @{count} item'.trP({'count': 5}),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Quick Actions
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Quick Actions'.tr,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children:
                      LanguageHelper.instance.codes
                          .map(
                            (code) => ElevatedButton(
                              onPressed:
                                  () => LanguageHelper.instance.change(code),
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    LanguageHelper.instance.code == code
                                        ? Theme.of(context).primaryColor
                                        : null,
                              ),
                              child: Text(_getLanguageName(code)),
                            ),
                          )
                          .toList(),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );

  Widget _buildInfoRow(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            '$label:',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
        Expanded(child: Text(value)),
      ],
    ),
  );

  Widget _buildExampleSection(String title, String example) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title.isNotEmpty) ...[
          Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
        ],
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Text(example, style: const TextStyle(fontFamily: 'monospace')),
        ),
        const SizedBox(height: 8),
      ],
    ),
  );

  String _getLanguageName(LanguageCodes code) {
    switch (code) {
      case LanguageCodes.en:
        return 'English'.tr;
      case LanguageCodes.vi:
        return 'Vietnamese'.tr;
      case LanguageCodes.es:
        return 'Spanish'.tr;
      case LanguageCodes.fr:
        return 'French'.tr;
      default:
        return code.name;
    }
  }
}
