import 'package:flutter/material.dart';
import 'package:language_helper/language_helper.dart';

class NetworkDataPage extends StatefulWidget {
  const NetworkDataPage({super.key});

  @override
  State<NetworkDataPage> createState() => _NetworkDataPageState();
}

class _NetworkDataPageState extends State<NetworkDataPage> {
  final LanguageHelper _languageHelper = LanguageHelper('NetworkHelper');
  bool _isLoaded = false;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeLanguageHelper();
  }

  Future<void> _initializeLanguageHelper() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Simulate network data loading
      await Future.delayed(const Duration(seconds: 2));

      // Create mock network data
      final mockNetworkData = {
        LanguageCodes.en: () => {
          'Loading translations from network...':
              'Loading translations from network...',
          'Network translations loaded successfully':
              'Network translations loaded successfully',
          'Failed to load network translations':
              'Failed to load network translations',
          'Retry': 'Retry',
          'Hello @{name}': 'Hello @{name} from network',
          'You have @{count} item': const LanguageConditions(
            param: 'count',
            conditions: {
              '0': 'You have no items (network)',
              '1': 'You have one item (network)',
              '_': 'You have @{count} items (network)',
            },
          ),
        },
        LanguageCodes.vi: () => {
          'Loading translations from network...':
              'Đang tải bản dịch từ mạng...',
          'Network translations loaded successfully':
              'Tải bản dịch từ mạng thành công',
          'Failed to load network translations':
              'Không thể tải bản dịch từ mạng',
          'Retry': 'Thử lại',
          'Hello @{name}': 'Xin chào @{name} từ mạng',
          'You have @{count} item': const LanguageConditions(
            param: 'count',
            conditions: {
              '0': 'Bạn không có mục nào (mạng)',
              '1': 'Bạn có một mục (mạng)',
              '_': 'Bạn có @{count} mục (mạng)',
            },
          ),
        },
      };

      await _languageHelper.initial(
        data: [LanguageDataProvider.lazyData(mockNetworkData)],
      );

      setState(() {
        _isLoaded = true;
        _isLoading = false;
      });
    } on Exception catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text('Network Data Example'.tr),
      elevation: 0,
      backgroundColor: Colors.white,
      foregroundColor: Colors.black87,
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: _initializeLanguageHelper,
        ),
      ],
    ),
    body: _isLoading
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(
                  width: 60,
                  height: 60,
                  child: CircularProgressIndicator(strokeWidth: 3),
                ),
                const SizedBox(height: 24),
                Text(
                  'Loading translations from network...'.tr,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'This may take a few seconds'.tr,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.grey),
                ),
              ],
            ),
          )
        : _errorMessage != null
        ? Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red[600],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Failed to load network translations'.tr,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _errorMessage!,
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _initializeLanguageHelper,
                    icon: const Icon(Icons.refresh),
                    label: Text('Retry'.tr),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[600],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
        : !_isLoaded
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
                        colors: [Color(0xFF0EA5E9), Color(0xFF0284C7)],
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
                              Icons.cloud_download,
                              color: Colors.white,
                              size: 28,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Network Data Source'.trC(_languageHelper),
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
                          'Load translations from remote servers or APIs.'.trC(
                            _languageHelper,
                          ),
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Success Banner
                  Card(
                    color: Colors.green[50],
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.green[600]!.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.check_circle,
                              color: Colors.green[600],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Network translations loaded successfully'.trC(
                                _languageHelper,
                              ),
                              style: TextStyle(
                                color: Colors.green[800],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
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
                                  color: Colors.orange.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.translate,
                                  color: Colors.orange,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Translation Examples'.trC(_languageHelper),
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildTranslationExample(
                            'Simple Translation'.trC(_languageHelper),
                            'Hello @{name}'.trC(
                              _languageHelper,
                              params: {'name': 'Network User'},
                            ),
                          ),
                          _buildTranslationExample(
                            'Conditional Translation'.trC(_languageHelper),
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
                              params: {'count': 3},
                            ),
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
                                  color: Colors.teal.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.language,
                                  color: Colors.teal,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Select Language'.trC(_languageHelper),
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
                                          ? const Color(0xFF0284C7)
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
                                  color: Colors.indigo.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.code,
                                  color: Colors.indigo,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Code Example'.trC(_languageHelper),
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
// Initialize with network data
final languageHelper = 
  LanguageHelper('NetworkHelper');
await languageHelper.initial(
  data: [LanguageDataProvider
    .network('https://api.example.com/')],
);

// Or use lazy data for mock responses
final mockData = {
  LanguageCodes.en: () => 
    await fetchTranslations('en'),
  LanguageCodes.vi: () => 
    await fetchTranslations('vi'),
};''',
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
            color: Colors.orange.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.orange.withValues(alpha: 0.2)),
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
