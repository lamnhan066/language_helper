import 'package:flutter/material.dart';
import 'package:language_helper/language_helper.dart';

import '../languages/codes.dart';

class MultipleSourcesPage extends StatefulWidget {
  const MultipleSourcesPage({super.key});

  @override
  State<MultipleSourcesPage> createState() => _MultipleSourcesPageState();
}

class _MultipleSourcesPageState extends State<MultipleSourcesPage> {
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
    // Create additional data to demonstrate multiple sources
    final additionalData = {
      LanguageCodes.en:
          () => {
            'This text was added dynamically':
                'This text was added dynamically',
            'This text will be removed': 'This text will be removed',
            'Multiple sources working': 'Multiple sources working perfectly!',
          },
      LanguageCodes.vi:
          () => {
            'This text was added dynamically': 'Văn bản này được thêm động',
            'This text will be removed': 'Văn bản này sẽ bị xóa',
            'Multiple sources working': 'Nhiều nguồn hoạt động hoàn hảo!',
          },
    };

    await _languageHelper.initial(
      data: [
        // Primary data source (Dart maps)
        LanguageDataProvider.lazyData(languageData),
        // Secondary data source (additional data)
        LanguageDataProvider.lazyData(additionalData),
        // Tertiary data source (JSON assets)
        LanguageDataProvider.asset('assets/languages'),
      ],
    );

    setState(() {
      _isLoaded = true;
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text('Multiple Sources Example'.tr),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => Navigator.of(context).pop(),
      ),
    ),
    body:
        !_isLoaded
            ? const Center(child: CircularProgressIndicator())
            : LanguageBuilder(
              languageHelper: _languageHelper,
              builder:
                  (context) => SingleChildScrollView(
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
                                  'Multiple Data Sources'.trC(_languageHelper),
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'This page demonstrates using multiple data sources for translations. Data sources are processed in order, with the first source taking priority.',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        Card(
                          color: Colors.blue[50],
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.info_outline,
                                      color: Colors.blue[600],
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Data Source Priority'.trC(
                                        _languageHelper,
                                      ),
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue[800],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '1. Dart Maps (Primary)\n2. Additional Data (Secondary)\n3. JSON Assets (Tertiary)',
                                  style: TextStyle(color: Colors.blue[700]),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Translation Examples'.trC(_languageHelper),
                                  style:
                                      Theme.of(context).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 12),

                                _buildTranslationExample(
                                  'From Primary Source'.trC(_languageHelper),
                                  'Hello @{name}'.trC(
                                    _languageHelper,
                                    params: {'name': 'Multi-Source User'},
                                  ),
                                ),

                                _buildTranslationExample(
                                  'From Secondary Source'.trC(_languageHelper),
                                  'Multiple sources working'.trC(
                                    _languageHelper,
                                  ),
                                ),

                                _buildTranslationExample(
                                  'Dynamic Addition'.trC(_languageHelper),
                                  'This text was added dynamically'.trC(
                                    _languageHelper,
                                  ),
                                ),

                                _buildTranslationExample(
                                  'Conditional Translation'.trC(
                                    _languageHelper,
                                  ),
                                  'You have @{count} item'.trC(
                                    _languageHelper,
                                    params: {'count': 2},
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Dynamic Data Management'.trC(
                                    _languageHelper,
                                  ),
                                  style:
                                      Theme.of(context).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: ElevatedButton(
                                        onPressed: _addDynamicData,
                                        child: Text(
                                          'Add New Translation'.trC(
                                            _languageHelper,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: ElevatedButton(
                                        onPressed: _removeDynamicData,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.red,
                                          foregroundColor: Colors.white,
                                        ),
                                        child: Text(
                                          'Remove Translation'.trC(
                                            _languageHelper,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Language Controls'.trC(_languageHelper),
                                  style:
                                      Theme.of(context).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 12),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children:
                                      _languageHelper.codes
                                          .map(
                                            (code) => ElevatedButton(
                                              onPressed:
                                                  () => _languageHelper.change(
                                                    code,
                                                  ),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor:
                                                    _languageHelper.code == code
                                                        ? Theme.of(
                                                          context,
                                                        ).primaryColor
                                                        : null,
                                              ),
                                              child: Text(
                                                _getLanguageName(code),
                                              ),
                                            ),
                                          )
                                          .toList(),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Code Example'.trC(_languageHelper),
                                  style:
                                      Theme.of(context).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 12),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.grey[300]!,
                                    ),
                                  ),
                                  child: const Text(
                                    '''
// Initialize with multiple data sources
await languageHelper.initial(
  data: [
    LanguageDataProvider.lazyData(primaryData),    // First priority
    LanguageDataProvider.lazyData(secondaryData),  // Second priority
    LanguageDataProvider.asset('assets/languages'), // Third priority
  ],
);

// Add data dynamically
languageHelper.addData(
  LanguageDataProvider.data(newData),
  overwrite: true, // Allow overwriting existing translations
);''',
                                    style: TextStyle(
                                      fontFamily: 'monospace',
                                      fontSize: 12,
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
  );

  void _addDynamicData() {
    final newData = {
      LanguageCodes.en: {
        'Dynamic text ${DateTime.now().millisecondsSinceEpoch}':
            'Dynamic text added at ${DateTime.now().toString().substring(11, 19)}',
      },
      LanguageCodes.vi: {
        'Dynamic text ${DateTime.now().millisecondsSinceEpoch}':
            'Văn bản động được thêm lúc ${DateTime.now().toString().substring(11, 19)}',
      },
    };

    _languageHelper.addData(LanguageDataProvider.data(newData));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Dynamic data added successfully!'.trC(_languageHelper)),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _removeDynamicData() {
    // Remove the last added dynamic data
    final keysToRemove =
        _languageHelper.codes
            .map(
              (code) =>
                  _languageHelper.data[code]?.keys
                      .where((key) => key.startsWith('Dynamic text'))
                      .toList() ??
                  [],
            )
            .expand((keys) => keys)
            .toList();

    if (keysToRemove.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Dynamic data removed: ${keysToRemove.length} items'.trC(
              _languageHelper,
            ),
          ),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  Widget _buildTranslationExample(String title, String example) => Padding(
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
            color: Colors.purple[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.purple[200]!),
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
        return 'English'.trC(_languageHelper);
      case LanguageCodes.vi:
        return 'Vietnamese'.trC(_languageHelper);
      case LanguageCodes.es:
        return 'Spanish'.trC(_languageHelper);
      case LanguageCodes.fr:
        return 'French'.trC(_languageHelper);
      default:
        return code.name;
    }
  }
}
