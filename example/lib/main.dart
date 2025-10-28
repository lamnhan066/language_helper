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
          title: 'Language Helper Demo'.tr,
          theme: _buildTheme(),
          localizationsDelegates: LanguageHelper.instance.delegates,
          supportedLocales: LanguageHelper.instance.locales,
          locale: LanguageHelper.instance.locale,
          home: const HomePage(),
        ),
  );

  ThemeData _buildTheme() {
    const primaryColor = Color(0xFF2563EB);

    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: primaryColor),
      appBarTheme: const AppBarTheme(elevation: 0, centerTitle: false),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        clipBehavior: Clip.antiAlias,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 2,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        filled: true,
        fillColor: Colors.grey[50],
      ),
    );
  }
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
  Widget build(BuildContext context) => LanguageBuilder(
    forceRebuild: true,
    builder:
        (context) => Scaffold(
          appBar: AppBar(
            title: Text('Language Helper Demo'.tr),
            elevation: 0,
            backgroundColor: Colors.white,
            foregroundColor: Colors.black87,
            actions: [
              PopupMenuButton<LanguageCodes>(
                icon: const Icon(Icons.language, color: Color(0xFF2563EB)),
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
                                    const SizedBox(width: 8),
                                    if (LanguageHelper.instance.code == code)
                                      const Icon(
                                        Icons.check_circle,
                                        color: Color(0xFF2563EB),
                                        size: 18,
                                      ),
                                  ],
                                ),
                              ),
                            )
                            .toList(),
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: IndexedStack(index: _selectedIndex, children: _pages),
          bottomNavigationBar: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            currentIndex: _selectedIndex,
            onTap: (index) => setState(() => _selectedIndex = index),
            elevation: 8,
            backgroundColor: Colors.white,
            selectedItemColor: const Color(0xFF2563EB),
            unselectedItemColor: Colors.grey,
            items: [
              BottomNavigationBarItem(
                icon: const Icon(Icons.home),
                label: 'Home'.tr,
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.map),
                label: 'Dart Map'.tr,
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.folder),
                label: 'JSON'.tr,
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.cloud),
                label: 'Network'.tr,
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.layers),
                label: 'Multi'.tr,
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.settings),
                label: 'Advanced'.tr,
              ),
            ],
          ),
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
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Hero Card
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF2563EB), Color(0xFF7C3AED)],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2563EB).withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome to Language Helper'.tr,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'A comprehensive localization solution for Flutter'.tr,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Language Statistics Card
        _buildSectionCard(
          context,
          title: 'Language Statistics'.tr,
          icon: Icons.analytics_outlined,
          children: [
            _buildStatRow(
              'Current Language'.tr,
              LanguageHelper.instance.code.name,
            ),
            const SizedBox(height: 12),
            _buildStatRow(
              'Supported Languages'.tr,
              LanguageHelper.instance.codes.map((e) => e.name).join(', '),
            ),
            const SizedBox(height: 12),
            _buildStatRow(
              'Current Locale'.tr,
              LanguageHelper.instance.locale.toString(),
            ),
            const SizedBox(height: 12),
            _buildStatRow(
              'Device Locale'.tr,
              Localizations.localeOf(context).toString(),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Translation Examples Card
        _buildSectionCard(
          context,
          title: 'Translation Examples'.tr,
          icon: Icons.language,
          children: [
            _buildExampleSection(
              'Simple Translation'.tr,
              'Hello @{name}'.trP({'name': 'World'}),
            ),
            _buildExampleSection(
              'Parameter Translation'.tr,
              'Hello @{name}'.trP({'name': 'Flutter'}),
            ),
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
        const SizedBox(height: 16),

        // Quick Actions
        _buildSectionCard(
          context,
          title: 'Switch Language'.tr,
          icon: Icons.translate,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children:
                  LanguageHelper.instance.codes
                      .map(
                        (code) => ElevatedButton.icon(
                          onPressed: () => LanguageHelper.instance.change(code),
                          icon: Icon(
                            LanguageHelper.instance.code == code
                                ? Icons.check_circle
                                : Icons.circle_outlined,
                            size: 18,
                          ),
                          label: Text(_getLanguageName(code)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                LanguageHelper.instance.code == code
                                    ? const Color(0xFF2563EB)
                                    : Colors.grey[200],
                            foregroundColor:
                                LanguageHelper.instance.code == code
                                    ? Colors.white
                                    : Colors.black87,
                            elevation: 0,
                          ),
                        ),
                      )
                      .toList(),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _buildSectionCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) => Card(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF2563EB), size: 24),
              const SizedBox(width: 12),
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    ),
  );

  Widget _buildStatRow(String label, String value) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SizedBox(
        width: 140,
        child: Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.grey,
          ),
        ),
      ),
      Expanded(
        child: Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
        ),
      ),
    ],
  );

  Widget _buildExampleSection(String title, String example) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title.isNotEmpty) ...[
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
          const SizedBox(height: 6),
        ],
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF2563EB).withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: const Color(0xFF2563EB).withValues(alpha: 0.2),
            ),
          ),
          child: Text(
            example,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
          ),
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
