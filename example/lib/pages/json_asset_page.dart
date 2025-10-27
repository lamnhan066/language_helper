import 'package:flutter/material.dart';
import 'package:language_helper/language_helper.dart';

class JsonAssetPage extends StatefulWidget {
  const JsonAssetPage({super.key});

  @override
  State<JsonAssetPage> createState() => _JsonAssetPageState();
}

class _JsonAssetPageState extends State<JsonAssetPage> {
  final LanguageHelper _languageHelper = LanguageHelper('JsonAssetHelper');
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    _initializeLanguageHelper();
  }

  Future<void> _initializeLanguageHelper() async {
    await _languageHelper.initial(
      data: [LanguageDataProvider.asset('assets/languages')],
      isDebug: true,
    );
    setState(() {
      _isLoaded = true;
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text('JSON Asset Example'.tr),
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
                                  'JSON Asset Data Source'.trC(_languageHelper),
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'This page demonstrates using JSON files from assets as the data source for translations. The translations are loaded from JSON files in the assets folder.',
                                  style: Theme.of(context).textTheme.bodyMedium,
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
                                  'Simple Translation'.trC(_languageHelper),
                                  'Hello @{name}'.trC(
                                    _languageHelper,
                                    params: {'name': 'Asset User'},
                                  ),
                                ),

                                _buildTranslationExample(
                                  'Conditional Translation'.trC(
                                    _languageHelper,
                                  ),
                                  'You have @{count} item'.trC(
                                    _languageHelper,
                                    params: {'count': 0},
                                  ),
                                ),

                                _buildTranslationExample(
                                  '',
                                  'You have @{count} item'.trC(
                                    _languageHelper,
                                    params: {'count': 1},
                                  ),
                                ),

                                _buildTranslationExample(
                                  '',
                                  'You have @{count} item'.trC(
                                    _languageHelper,
                                    params: {'count': 5},
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
                  // Initialize with JSON assets
                  final languageHelper = LanguageHelper('JsonAssetHelper');
                  await languageHelper.initial(
                    data: [LanguageDataProvider.asset('assets/languages')],
                  );
                  
                  // Use in widgets
                  LanguageBuilder(
                    languageHelper: languageHelper,
                    builder: (context) => Text('Hello'.trC(languageHelper)),
                  )''',
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
            color: Colors.green[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.green[200]!),
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
