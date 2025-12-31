import 'package:flutter/material.dart';
import 'package:language_helper/language_helper.dart';

import '../languages/codes.dart';

class MultipleSourcesPage extends StatefulWidget {
  const MultipleSourcesPage({super.key});

  @override
  State<MultipleSourcesPage> createState() => _MultipleSourcesPageState();
}

class _MultipleSourcesPageState extends State<MultipleSourcesPage> {
  final additionalData = {
    LanguageCodes.en: {
      'This text was added dynamically': 'This text was added dynamically',
      'This text will be removed': 'This text will be removed',
      'Multiple sources working': 'Multiple sources working perfectly!',
    },
    LanguageCodes.es: {
      'This text was added dynamically':
          'Este texto fue agregado dinámicamente',
      'This text will be removed': 'Este texto será eliminado',
      'Multiple sources working':
          '¡Múltiples fuentes funcionando perfectamente!',
    },
    LanguageCodes.fr: {
      'This text was added dynamically': 'Ce texte a été ajouté dynamiquement',
      'This text will be removed': 'Ce texte sera supprimé',
      'Multiple sources working':
          'Plusieurs sources fonctionnent parfaitement !',
    },
    LanguageCodes.vi: {
      'This text was added dynamically': 'Văn bản này được thêm động',
      'This text will be removed': 'Văn bản này sẽ bị xóa',
      'Multiple sources working': 'Nhiều nguồn hoạt động hoàn hảo!',
    },
  };
  final LanguageHelper _languageHelper = LanguageHelper(
    'MultipleSourcesHelper',
  );
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    _initializeLanguageHelper();
  }

  Future<void> _initializeLanguageHelper() async {
    await _languageHelper.initial([
      LanguageDataProvider.lazyData(languageData),
      LanguageDataProvider.asset('assets/languages'),
    ], config: const LanguageConfig());

    setState(() {
      _isLoaded = true;
    });
  }

  @override
  Widget build(BuildContext context) => LanguageScope(
    languageHelper: _languageHelper,
    child: Scaffold(
      appBar: AppBar(
        title: Text('Multiple Sources Example'.tr),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
      ),
      body: !_isLoaded
          ? const Center(child: CircularProgressIndicator())
          : LanguageBuilder(
              languageHelper: _languageHelper,
              builder: (context) => SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Card
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFFA78BFA), Color(0xFF8B5CF6)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.source,
                                color: Colors.white,
                                size: 28,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Multiple Data Sources'.tr,
                                  style: Theme.of(context).textTheme.titleLarge
                                      ?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Combine multiple translation sources with '
                                    'automatic priority handling.'
                                .tr,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Data Source Priority
                    Card(
                      color: Colors.purple[50],
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.purple[600]!.withValues(
                                      alpha: 0.2,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.priority_high,
                                    color: Colors.purple[600],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Data Source Priority'.tr,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _buildPriorityItem('1', 'Dart Maps (Primary)'),
                            _buildPriorityItem(
                              '2',
                              'Additional Data (Secondary)',
                            ),
                            _buildPriorityItem('3', 'JSON Assets (Tertiary)'),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Translation Examples
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.indigo.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.translate,
                                    color: Colors.indigo,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Translation Examples'.tr,
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _buildTranslationExample(
                              'From Primary Source'.tr,
                              'Hello @{name}'.trP({
                                'name': 'Multi-Source User',
                              }),
                            ),
                            _buildTranslationExample(
                              'From Secondary Source'.tr,
                              'Multiple sources working'.tr,
                            ),
                            _buildTranslationExample(
                              'Dynamic Addition'.tr,
                              'This text was added dynamically'.tr,
                            ),
                            _buildTranslationExample(
                              'Conditional Translation'.tr,
                              'You have @{count} item'.trP({'count': 2}),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Dynamic Data Management
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.teal.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.settings,
                                    color: Colors.teal,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Dynamic Data Management'.tr,
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: _addDynamicData,
                                    icon: const Icon(Icons.add),
                                    label: Text('Add'.tr),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green[600],
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Language Controls
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.language,
                                    color: Colors.blue,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Select Language'.tr,
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _languageHelper.codes
                                  .map(
                                    (code) => ElevatedButton(
                                      onPressed: () =>
                                          _languageHelper.change(code),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            _languageHelper.code == code
                                            ? const Color(0xFF8B5CF6)
                                            : Colors.grey[200],
                                        foregroundColor:
                                            _languageHelper.code == code
                                            ? Colors.white
                                            : Colors.black87,
                                        elevation: 0,
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
                    const SizedBox(height: 20),

                    // Code Example
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.code,
                                    color: Colors.orange,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Code Example'.tr,
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1F2937),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.grey[700]!),
                              ),
                              child: Text(
                                '''
  // Initialize with multiple sources
  await languageHelper.initial(
  LanguageConfig(
    data: [
      LanguageDataProvider.lazyData(
        primaryData),    // 1st priority
      LanguageDataProvider.lazyData(
        secondaryData),  // 2nd priority
      LanguageDataProvider.asset(
        'assets/languages'), // 3rd priority
    ],
  ),
  );
  
  // Add data dynamically
  languageHelper.addData(
  LanguageDataProvider.data(newData),
  overwrite: true,
  );''',
                                style: TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 11,
                                  color: Colors.grey[300],
                                  height: 1.6,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    ),
  );

  Widget _buildPriorityItem(String number, String text) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: Colors.purple[600],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          text,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ],
    ),
  );

  Widget _buildTranslationExample(String title, String example) => Padding(
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
            color: Colors.purple.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.purple.withValues(alpha: 0.2)),
          ),
          child: Text(
            example,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
          ),
        ),
      ],
    ),
  );

  void _addDynamicData() {
    _languageHelper.addProvider(LanguageDataProvider.data(additionalData));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Dynamic data added successfully!'.tr),
        backgroundColor: Colors.green[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

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
