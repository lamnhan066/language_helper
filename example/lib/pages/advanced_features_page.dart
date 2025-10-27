import 'dart:async';

import 'package:flutter/material.dart';
import 'package:language_helper/language_helper.dart';

class AdvancedFeaturesPage extends StatefulWidget {
  const AdvancedFeaturesPage({super.key});

  @override
  State<AdvancedFeaturesPage> createState() => _AdvancedFeaturesPageState();
}

class _AdvancedFeaturesPageState extends State<AdvancedFeaturesPage> {
  final LanguageHelper _languageHelper = LanguageHelper('AdvancedHelper');
  bool _isLoaded = false;
  LanguageCodes? _previousLanguage;
  StreamSubscription<LanguageCodes>? _languageSubscription;

  @override
  void initState() {
    super.initState();
    _initializeLanguageHelper();
  }

  @override
  void dispose() {
    _languageSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initializeLanguageHelper() async {
    // Create advanced language data with complex conditions
    final advancedData = {
      LanguageCodes.en:
          () => {
            'Welcome @{name}': 'Welcome @{name}',
            'You have @{count} notification': const LanguageConditions(
              param: 'count',
              conditions: {
                '0': 'You have no notifications',
                '1': 'You have one notification',
                '_': 'You have @{count} notifications',
              },
            ),
            'Time format': const LanguageConditions(
              param: 'hours',
              conditions: {
                '0': 'Midnight',
                '1': '1 AM',
                '12': 'Noon',
                '_': "@{hours} o'clock",
              },
            ),
            'Plural items': const LanguageConditions(
              param: 'count',
              conditions: {
                '0': 'No items',
                '1': 'One item',
                '2': 'Two items',
                '3': 'Three items',
                '4': 'Four items',
                '5': 'Five items',
                '_': '@{count} items',
              },
            ),
            'Language changed from @{from} to @{to}':
                'Language changed from @{from} to @{to}',
            'Current timestamp': 'Current timestamp: @{timestamp}',
            'Device info': 'Device: @{device}, Platform: @{platform}',
          },
      LanguageCodes.vi:
          () => {
            'Welcome @{name}': 'Chào mừng @{name}',
            'You have @{count} notification': const LanguageConditions(
              param: 'count',
              conditions: {
                '0': 'Bạn không có thông báo nào',
                '1': 'Bạn có một thông báo',
                '_': 'Bạn có @{count} thông báo',
              },
            ),
            'Time format': const LanguageConditions(
              param: 'hours',
              conditions: {
                '0': 'Nửa đêm',
                '1': '1 giờ sáng',
                '12': 'Trưa',
                '_': '@{hours} giờ',
              },
            ),
            'Plural items': const LanguageConditions(
              param: 'count',
              conditions: {
                '0': 'Không có mục nào',
                '1': 'Một mục',
                '2': 'Hai mục',
                '3': 'Ba mục',
                '4': 'Bốn mục',
                '5': 'Năm mục',
                '_': '@{count} mục',
              },
            ),
            'Language changed from @{from} to @{to}':
                'Ngôn ngữ đã thay đổi từ @{from} sang @{to}',
            'Current timestamp': 'Thời gian hiện tại: @{timestamp}',
            'Device info': 'Thiết bị: @{device}, Nền tảng: @{platform}',
          },
    };

    await _languageHelper.initial(
      data: [LanguageDataProvider.lazyData(advancedData)],
    );

    // Listen to language changes
    _languageSubscription = _languageHelper.stream.listen((newCode) {
      if (_previousLanguage != null && _previousLanguage != newCode) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Language changed from @{from} to @{to}'.trC(
                _languageHelper,
                params: {'from': _previousLanguage!.name, 'to': newCode.name},
              ),
            ),
            backgroundColor: Colors.blue,
            duration: const Duration(seconds: 2),
          ),
        );
      }
      _previousLanguage = newCode;
    });

    setState(() {
      _isLoaded = true;
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text('Advanced Features'.tr),
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
                                  'Advanced Language Features'.trC(
                                    _languageHelper,
                                  ),
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'This page demonstrates advanced features like complex conditions, language change listeners, and dynamic parameter injection.',
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
                                  'Complex Conditional Translations'.trC(
                                    _languageHelper,
                                  ),
                                  style:
                                      Theme.of(context).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 12),

                                _buildTranslationExample(
                                  'Notifications'.trC(_languageHelper),
                                  'You have @{count} notification'.trC(
                                    _languageHelper,
                                    params: {'count': 0},
                                  ),
                                ),
                                _buildTranslationExample(
                                  '',
                                  'You have @{count} notification'.trC(
                                    _languageHelper,
                                    params: {'count': 1},
                                  ),
                                ),
                                _buildTranslationExample(
                                  '',
                                  'You have @{count} notification'.trC(
                                    _languageHelper,
                                    params: {'count': 5},
                                  ),
                                ),

                                const Divider(),

                                _buildTranslationExample(
                                  'Time Format'.trC(_languageHelper),
                                  'Time format'.trC(
                                    _languageHelper,
                                    params: {'hours': 0},
                                  ),
                                ),
                                _buildTranslationExample(
                                  '',
                                  'Time format'.trC(
                                    _languageHelper,
                                    params: {'hours': 1},
                                  ),
                                ),
                                _buildTranslationExample(
                                  '',
                                  'Time format'.trC(
                                    _languageHelper,
                                    params: {'hours': 12},
                                  ),
                                ),
                                _buildTranslationExample(
                                  '',
                                  'Time format'.trC(
                                    _languageHelper,
                                    params: {'hours': 15},
                                  ),
                                ),

                                const Divider(),

                                _buildTranslationExample(
                                  'Plural Items'.trC(_languageHelper),
                                  'Plural items'.trC(
                                    _languageHelper,
                                    params: {'count': 0},
                                  ),
                                ),
                                _buildTranslationExample(
                                  '',
                                  'Plural items'.trC(
                                    _languageHelper,
                                    params: {'count': 1},
                                  ),
                                ),
                                _buildTranslationExample(
                                  '',
                                  'Plural items'.trC(
                                    _languageHelper,
                                    params: {'count': 2},
                                  ),
                                ),
                                _buildTranslationExample(
                                  '',
                                  'Plural items'.trC(
                                    _languageHelper,
                                    params: {'count': 3},
                                  ),
                                ),
                                _buildTranslationExample(
                                  '',
                                  'Plural items'.trC(
                                    _languageHelper,
                                    params: {'count': 4},
                                  ),
                                ),
                                _buildTranslationExample(
                                  '',
                                  'Plural items'.trC(
                                    _languageHelper,
                                    params: {'count': 5},
                                  ),
                                ),
                                _buildTranslationExample(
                                  '',
                                  'Plural items'.trC(
                                    _languageHelper,
                                    params: {'count': 10},
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
                                  'Dynamic Parameter Injection'.trC(
                                    _languageHelper,
                                  ),
                                  style:
                                      Theme.of(context).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 12),

                                _buildTranslationExample(
                                  'Welcome Message'.trC(_languageHelper),
                                  'Welcome @{name}'.trC(
                                    _languageHelper,
                                    params: {'name': 'Advanced User'},
                                  ),
                                ),

                                _buildTranslationExample(
                                  'Timestamp'.trC(_languageHelper),
                                  'Current timestamp'.trC(
                                    _languageHelper,
                                    params: {
                                      'timestamp': DateTime.now()
                                          .toString()
                                          .substring(11, 19),
                                    },
                                  ),
                                ),

                                _buildTranslationExample(
                                  'Device Info'.trC(_languageHelper),
                                  'Device info'.trC(
                                    _languageHelper,
                                    params: {
                                      'device': 'iPhone 15',
                                      'platform': 'iOS',
                                    },
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
                                  'Language Change Listener'.trC(
                                    _languageHelper,
                                  ),
                                  style:
                                      Theme.of(context).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Change the language below to see the listener in action. A snackbar will show the language change notification.',
                                  style: Theme.of(context).textTheme.bodySmall,
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
                                  'Language Statistics'.trC(_languageHelper),
                                  style:
                                      Theme.of(context).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 12),
                                _buildInfoRow(
                                  'Current Language'.trC(_languageHelper),
                                  _languageHelper.code.name,
                                ),
                                _buildInfoRow(
                                  'Supported Languages'.trC(_languageHelper),
                                  _languageHelper.codes
                                      .map((e) => e.name)
                                      .join(', '),
                                ),
                                _buildInfoRow(
                                  'Is Initialized'.trC(_languageHelper),
                                  _languageHelper.isInitialized.toString(),
                                ),
                                _buildInfoRow(
                                  'Data Sources'.trC(_languageHelper),
                                  _languageHelper.data.length.toString(),
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
                                    r'''
  // Complex conditions with multiple cases
  'Plural items': LanguageConditions(
  param: 'count',
  conditions: {
    '0': 'No items',
    '1': 'One item',
    '2': 'Two items',
    '3': 'Three items',
    '4': 'Four items',
    '5': 'Five items',
    '_': '@{count} items', // Default case
  },
  ),
  
  // Listen to language changes
  languageHelper.stream.listen((newCode) {
  print('Language changed to: $newCode');
  });
  
  // Dynamic parameter injection
  'Welcome @{name}'.trP({'name': 'John'})''',
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
            color: Colors.indigo[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.indigo[200]!),
          ),
          child: Text(example, style: const TextStyle(fontFamily: 'monospace')),
        ),
        const SizedBox(height: 8),
      ],
    ),
  );

  Widget _buildInfoRow(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 140,
          child: Text(
            '$label:',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
        Expanded(child: Text(value)),
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
