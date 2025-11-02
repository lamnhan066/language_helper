import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:language_helper/language_helper.dart';
import 'package:language_improver/language_improver.dart';

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
      LanguageCodes.en: () => {
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
      LanguageCodes.vi: () => {
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
      if (_previousLanguage != null &&
          _previousLanguage != newCode &&
          mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Language changed from @{from} to @{to}'.trP({
                'from': _previousLanguage!.name,
                'to': newCode.name,
              }),
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
  Widget build(BuildContext context) {
    return LanguageScope(
      languageHelper: _languageHelper,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Advanced Features'.tr),
          elevation: 0,
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
        ),
        body: !_isLoaded
            ? const Center(child: CircularProgressIndicator())
            : _body(),
      ),
    );
  }

  LanguageBuilder _body() {
    return LanguageBuilder(
      builder: (context) {
        return SingleChildScrollView(
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
                    colors: [Color(0xFFEC4899), Color(0xFFDB2777)],
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
                          Icons.auto_awesome,
                          color: Colors.white,
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Advanced Language Features'.tr,
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
                      'Master complex conditions, dynamic parameters, '
                              'and language change listeners.'
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
                              color: Colors.pink.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.rule, color: Colors.pink),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Complex Conditional Translations'.tr,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      _buildConditionSection('Notifications'.tr, [
                        _buildTranslationExample(
                          '',
                          'You have @{count} notification'.trP({'count': 0}),
                        ),
                        _buildTranslationExample(
                          '',
                          'You have @{count} notification'.trP({'count': 1}),
                        ),
                        _buildTranslationExample(
                          '',
                          'You have @{count} notification'.trP({'count': 5}),
                        ),
                      ]),

                      const SizedBox(height: 12),

                      _buildConditionSection('Time Format'.tr, [
                        _buildTranslationExample(
                          '',
                          'Time format'.trP({'hours': 0}),
                        ),
                        _buildTranslationExample(
                          '',
                          'Time format'.trP({'hours': 1}),
                        ),
                        _buildTranslationExample(
                          '',
                          'Time format'.trP({'hours': 12}),
                        ),
                        _buildTranslationExample(
                          '',
                          'Time format'.trP({'hours': 15}),
                        ),
                      ]),

                      const SizedBox(height: 12),

                      _buildConditionSection('Plural Items'.tr, [
                        _buildTranslationExample(
                          '',
                          'Plural items'.trP({'count': 0}),
                        ),
                        _buildTranslationExample(
                          '',
                          'Plural items'.trP({'count': 1}),
                        ),
                        _buildTranslationExample(
                          '',
                          'Plural items'.trP({'count': 3}),
                        ),
                        _buildTranslationExample(
                          '',
                          'Plural items'.trP({'count': 5}),
                        ),
                      ]),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

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
                              color: Colors.amber.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.input, color: Colors.amber),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Dynamic Parameter Injection'.tr,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildTranslationExample(
                        'Welcome Message'.tr,
                        'Welcome @{name}'.trP({'name': 'Advanced User'}),
                      ),
                      _buildTranslationExample(
                        'Timestamp'.tr,
                        'Current timestamp'.trP({
                          'timestamp': DateTime.now().toString().substring(
                            11,
                            19,
                          ),
                        }),
                      ),
                      _buildTranslationExample(
                        'Device Info'.tr,
                        'Device info'.trP({
                          'device': 'iPhone 15',
                          'platform': 'iOS',
                        }),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

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
                              color: Colors.cyan.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.volume_down,
                              color: Colors.cyan,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Language Change Listener'.tr,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Change language to see listener notifications.'.tr,
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(color: Colors.grey),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _languageHelper.codes
                            .map(
                              (code) => ElevatedButton(
                                onPressed: () => _languageHelper.change(code),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _languageHelper.code == code
                                      ? const Color(0xFFDB2777)
                                      : Colors.grey[200],
                                  foregroundColor: _languageHelper.code == code
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
                              Icons.bar_chart,
                              color: Colors.green,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Language Statistics'.tr,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildInfoRow(
                        'Current Language'.tr,
                        _languageHelper.code.name,
                      ),
                      _buildInfoRow(
                        'Supported Languages'.tr,
                        _languageHelper.codes.map((e) => e.name).join(', '),
                      ),
                      _buildInfoRow(
                        'Is Initialized'.tr,
                        _languageHelper.isInitialized.toString(),
                      ),
                      _buildInfoRow(
                        'Data Sources'.tr,
                        _languageHelper.data.length.toString(),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

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
                              Icons.translate,
                              color: Colors.blue,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Language Improver'.tr,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Improve translations by comparing with a default '
                                'language and editing them directly in a '
                                'user-friendly interface.'
                            .tr,
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(color: Colors.grey),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => LanguageImprover(
                                languageHelper: LanguageHelper.instance,
                                onTranslationsUpdated: (updatedTranslations) {
                                  // Apply the updated translations to
                                  // LanguageHelper
                                  for (final entry
                                      in updatedTranslations.entries) {
                                    final code = entry.key;
                                    final translations = entry.value;

                                    // Create a LanguageDataProvider from the
                                    // updated translations
                                    final provider = LanguageDataProvider.data({
                                      code: translations,
                                    });

                                    // Add the translations as overrides, which
                                    // will trigger rebuilds
                                    LanguageHelper.instance
                                        .addDataOverrides(provider)
                                        .then((_) {
                                          // Show success message after
                                          // translations are applied
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  'Translations updated! '
                                                          'Check the callback '
                                                          'data to '
                                                          'see the changes.'
                                                      .tr,
                                                ),
                                                backgroundColor: Colors.green,
                                                duration: const Duration(
                                                  seconds: 3,
                                                ),
                                              ),
                                            );
                                          }
                                        });
                                  }

                                  // Print the updated translations for
                                  // demonstration
                                  if (kDebugMode) {
                                    print(
                                      'Updated translations: '
                                      '$updatedTranslations',
                                    );
                                  }
                                },
                                onCancel: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Translation editing cancelled.'.tr,
                                      ),
                                      duration: const Duration(seconds: 2),
                                    ),
                                  );
                                },
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.edit),
                        label: Text('Open Language Improver'.tr),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

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
                            child: const Icon(Icons.code, color: Colors.purple),
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
                          r'''
                // Complex conditions
                'Plural items': LanguageConditions(
                  param: 'count',
                  conditions: {
                    '0': 'No items',
                    '1': 'One item',
                    '2': 'Two items',
                    '_': '@{count} items',
                  },
                ),
                
                // Listen to language changes
                languageHelper.stream.listen((newCode) {
                  print('Language: $newCode');
                });
                
                // Dynamic parameters
                'Welcome @{name}'.trP({'name': 'John'})
                
                // Language Improver
                LanguageImprover(
                  languageHelper: LanguageHelper.instance,
                  onTranslationsUpdated: (translations) {
                    // Handle updated translations
                  },
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
        );
      },
    );
  }

  Widget _buildConditionSection(String title, List<Widget> children) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 13,
          color: Colors.grey,
        ),
      ),
      const SizedBox(height: 8),
      ...children,
    ],
  );

  Widget _buildTranslationExample(String title, String example) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title.isNotEmpty) ...[
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
          ),
          const SizedBox(height: 4),
        ],
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.pink.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.pink.withValues(alpha: 0.15)),
          ),
          child: Text(
            example,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
          ),
        ),
      ],
    ),
  );

  Widget _buildInfoRow(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 140,
          child: Text(
            '$label:',
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
          ),
        ),
        Expanded(child: Text(value, style: const TextStyle(fontSize: 13))),
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
