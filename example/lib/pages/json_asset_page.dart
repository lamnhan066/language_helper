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
  Widget build(BuildContext context) => LanguageScope(
    languageHelper: _languageHelper,
    child: Scaffold(
      appBar: AppBar(
        title: Text('JSON Asset Example'.tr),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
      ),
      body: !_isLoaded
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text('Loading translations...'.tr),
                ],
              ),
            )
          : LanguageBuilder(
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
                          colors: [Color(0xFF10B981), Color(0xFF059669)],
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
                                Icons.folder,
                                color: Colors.white,
                                size: 28,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'JSON Asset Data Source'.tr,
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
                            'Load translations from JSON files stored in '
                                    'your app assets.'
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
                                    color: Colors.green.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.translate,
                                    color: Colors.green,
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
                              'Simple Translation'.tr,
                              'Hello @{name}'.tr,
                            ),
                            _buildTranslationExample(
                              'Conditional Translation'.tr,
                              'You have @{count} item'.tr,
                            ),
                            _buildTranslationExample(
                              '',
                              'You have @{count} item'.trP({'count': 1}),
                            ),
                            _buildTranslationExample(
                              '',
                              'You have @{count} item'.trP({'count': 5}),
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
                                    color: Colors.purple.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.language,
                                    color: Colors.purple,
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
                                            ? const Color(0xFF10B981)
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
  // Initialize with JSON assets
  final languageHelper = 
  LanguageHelper('JsonAssetHelper');
  await languageHelper.initial(
  data: [LanguageDataProvider
    .asset('assets/languages')],
  );
  
  // Use in widgets
  LanguageBuilder(
  languageHelper: languageHelper,
  builder: (context) => Text(
    'Hello'.trC(languageHelper)
  ),
  )''',
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
            color: Colors.green.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.green.withValues(alpha: 0.2)),
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
