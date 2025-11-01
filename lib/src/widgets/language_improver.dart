import 'dart:async';

import 'package:flutter/material.dart';
import 'package:language_helper/language_helper.dart';

/// A stateful widget to list all translations and improve them
/// based on a default language reference.
///
/// This widget allows users to:
/// - Select a default/reference language
/// - View all translations side-by-side with the reference
/// - Edit and improve translations
/// - Receive improved translations via callback
///
/// Example usage:
/// ```dart
/// LanguageImprover(
///   languageHelper: LanguageHelper.instance,
///   onTranslationsUpdated: (updatedTranslations) {
///     // Handle the improved translations
///     print('Updated translations: $updatedTranslations');
///   },
/// )
/// ```
class LanguageImprover extends StatefulWidget {
  /// The LanguageHelper instance to use.
  /// If not provided, uses [LanguageHelper.instance].
  final LanguageHelper? languageHelper;

  /// Callback called when translations are updated.
  /// Receives a map of [LanguageCodes] to updated translations.
  /// Can return a Future to be awaited before popping the screen.
  final FutureOr<void> Function(Map<LanguageCodes, Map<String, dynamic>>)?
  onTranslationsUpdated;

  /// Callback called when the user cancels editing.
  final VoidCallback? onCancel;

  /// Whether to show the save button.
  /// Defaults to true.
  final bool showSaveButton;

  /// Whether to show the cancel button.
  /// Defaults to true.
  final bool showCancelButton;

  /// Initial default language code.
  /// If not provided, uses the first available language.
  final LanguageCodes? initialDefaultLanguage;

  /// Initial target language code to improve.
  /// If not provided, uses the current language.
  final LanguageCodes? initialTargetLanguage;

  /// Initial key to scroll to and focus on.
  /// If provided, the widget will automatically scroll to this key and
  /// optionally filter/search for it.
  final String? scrollToKey;

  /// Whether to automatically search for the [scrollToKey] when provided.
  /// Defaults to true.
  final bool autoSearchOnScroll;

  const LanguageImprover({
    super.key,
    this.languageHelper,
    this.onTranslationsUpdated,
    this.onCancel,
    this.showSaveButton = true,
    this.showCancelButton = true,
    this.initialDefaultLanguage,
    this.initialTargetLanguage,
    this.scrollToKey,
    this.autoSearchOnScroll = true,
  });

  @override
  State<LanguageImprover> createState() => _LanguageImproverState();
}

class _LanguageImproverState extends State<LanguageImprover>
    with TickerProviderStateMixin {
  late LanguageHelper _helper;
  LanguageCodes? _defaultLanguage;
  LanguageCodes? _targetLanguage;
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, dynamic> _editedTranslations = {};
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  final Set<String> _allKeys = {};
  final ScrollController _scrollController = ScrollController();
  final Map<String, GlobalKey> _keyMap = {};
  AnimationController? _flashAnimationController;
  Animation<double>? _flashAnimation;
  String? _flashingKey;
  int _flashRepeatCount = 0;
  static const int _maxFlashRepeats = 10;

  @override
  void initState() {
    super.initState();
    _helper = widget.languageHelper ?? LanguageHelper.instance;

    // Initialize flash animation controller (faster animation)
    _flashAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _flashAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeIn)),
        weight: 0.4,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.0,
          end: 0.0,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 0.6,
      ),
    ]).animate(_flashAnimationController!);

    _flashAnimationController!.addListener(() {
      if (mounted) {
        setState(() {
          // Trigger rebuild to update animation
        });
      }
    });

    // Handle animation completion for repeating
    _flashAnimationController!.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        _handleFlashAnimationComplete();
      }
    });

    // Get all available languages and keys
    _initializeLanguages().then((_) {
      if (mounted) {
        setState(() {
          // Trigger rebuild after data is loaded
        });

        // After data is loaded and widget rebuilt, scroll to key
        if (widget.scrollToKey != null) {
          // Pre-create the key in the map
          final targetKey = widget.scrollToKey!;
          if (!_keyMap.containsKey(targetKey)) {
            _keyMap[targetKey] = GlobalKey();
          }

          // Wait for multiple frames to ensure ListView is fully built
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _attemptScrollToKey();
            }
          });
        }
      }
    });

    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });

      // Scroll to target key if it matches the search
      if (widget.scrollToKey != null &&
          _filteredKeys.contains(widget.scrollToKey)) {
        // Wait for the ListView to rebuild with filtered results
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Future.delayed(const Duration(milliseconds: 200), () {
            if (mounted) {
              _scrollToKey(widget.scrollToKey!);
            }
          });
        });
      }
    });

    // Set search text if scrollToKey is provided and autoSearchOnScroll is true
    if (widget.scrollToKey != null && widget.autoSearchOnScroll) {
      // This will be set after data loads in _initializeLanguages
    }
  }

  void _scrollToKey(String targetKey) {
    // Wait for ScrollController to be attached
    void tryScrollWithController({int retryCount = 0}) {
      if (!mounted) return;

      // First, try to find the index of the target key in filtered keys
      final index = _filteredKeys.indexOf(targetKey);

      if (index >= 0 && _scrollController.hasClients) {
        // Calculate approximate position based on index
        // Estimate card height: padding (8*2) + margin (8*2) + card height (~200)
        const estimatedCardHeight = 250.0; // Approximate height per card
        final estimatedPosition = index * estimatedCardHeight;

        // Clamp position to valid range
        final maxScroll = _scrollController.position.maxScrollExtent;
        final scrollPosition = estimatedPosition.clamp(0.0, maxScroll);

        _scrollController.animateTo(
          scrollPosition,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );

        // After scrolling, try to use ensureVisible for precise positioning
        Future.delayed(const Duration(milliseconds: 600), () {
          if (mounted) {
            _scrollToKeyPrecise(targetKey);
          }
        });
      } else if (retryCount < 5) {
        // ScrollController not ready yet, retry
        Future.delayed(Duration(milliseconds: 100 + (retryCount * 50)), () {
          tryScrollWithController(retryCount: retryCount + 1);
        });
      } else {
        // Fallback to precise scrolling if controller never becomes ready
        _scrollToKeyPrecise(targetKey);
      }
    }

    tryScrollWithController();
  }

  /// Precise scrolling using Scrollable.ensureVisible
  void _scrollToKeyPrecise(String targetKey) {
    // Create the key if it doesn't exist yet
    if (!_keyMap.containsKey(targetKey)) {
      _keyMap[targetKey] = GlobalKey();
    }

    final globalKey = _keyMap[targetKey];

    // Wait for the widget to be built and context to be available
    void tryScroll({int retryCount = 0}) {
      if (!mounted) return;

      if (globalKey?.currentContext != null) {
        try {
          Scrollable.ensureVisible(
            globalKey!.currentContext!,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            alignment: 0.1, // Position slightly from top for better visibility
          );

          // Trigger flash animation when key becomes visible
          _triggerFlashAnimation(targetKey);
        } catch (e) {
          // If scroll fails, retry up to 3 times
          if (retryCount < 3) {
            Future.delayed(const Duration(milliseconds: 200), () {
              tryScroll(retryCount: retryCount + 1);
            });
          }
        }
      } else {
        // Context not available yet, retry up to 5 times
        if (retryCount < 5) {
          Future.delayed(Duration(milliseconds: 200 + (retryCount * 100)), () {
            tryScroll(retryCount: retryCount + 1);
          });
        }
      }
    }

    // Start trying to scroll
    tryScroll();
  }

  Future<void> _initializeLanguages() async {
    final codes = _helper.codes.toList();
    if (codes.isEmpty) return;

    // Set default language
    _defaultLanguage = widget.initialDefaultLanguage ?? codes.first;
    if (!codes.contains(_defaultLanguage)) {
      _defaultLanguage = codes.first;
    }

    // Set target language
    _targetLanguage = widget.initialTargetLanguage ?? _helper.code;
    if (!codes.contains(_targetLanguage) ||
        _targetLanguage == _defaultLanguage) {
      _targetLanguage = codes.firstWhere(
        (code) => code != _defaultLanguage,
        orElse: () => codes.first,
      );
    }

    // Ensure data is loaded for both default and target languages
    if (_defaultLanguage != null) {
      final defaultLang = _defaultLanguage!;
      await _ensureDataLoaded(defaultLang);
    }
    if (_targetLanguage != null) {
      final targetLang = _targetLanguage!;
      await _ensureDataLoaded(targetLang);
    }

    // Collect all keys from all available languages
    // Check both data and dataOverrides
    _allKeys.clear();
    for (final code in codes) {
      await _ensureDataLoaded(code);

      // Check both data and dataOverrides
      final data = _helper.data[code];
      final dataOverrides = _helper.dataOverrides[code];

      if (data != null) {
        _allKeys.addAll(data.keys);
      }
      if (dataOverrides != null) {
        _allKeys.addAll(dataOverrides.keys);
      }
    }

    // If no keys found, try to get them from the current language
    if (_allKeys.isEmpty) {
      await _ensureDataLoaded(_helper.code);
      final currentData = _helper.data[_helper.code];
      final currentOverrides = _helper.dataOverrides[_helper.code];
      if (currentData != null) {
        _allKeys.addAll(currentData.keys);
      }
      if (currentOverrides != null) {
        _allKeys.addAll(currentOverrides.keys);
      }
    }

    _allKeys.removeWhere((key) => key.startsWith('@path_'));

    // Initialize controllers and edited translations
    _initializeControllers();

    // Set search text if scrollToKey is provided and autoSearchOnScroll is true
    if (widget.scrollToKey != null &&
        widget.autoSearchOnScroll &&
        _allKeys.contains(widget.scrollToKey)) {
      _searchController.text = widget.scrollToKey!;
    }
  }

  /// Attempt to scroll to the target key
  void _attemptScrollToKey() {
    if (widget.scrollToKey == null) return;

    final targetKey = widget.scrollToKey!;

    // If key is not in all keys, can't scroll to it
    if (!_allKeys.contains(targetKey)) {
      return;
    }

    // If key is not in the filtered keys, try to filter first
    if (!_filteredKeys.contains(targetKey)) {
      if (widget.autoSearchOnScroll) {
        // Set search to show the key
        _searchController.text = targetKey;
        // Wait for filtering to complete and widget to rebuild
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) {
            _scrollToKey(targetKey);
          }
        });
      }
      return;
    }

    // Key should be visible, wait for ListView to build the item
    // We need to wait for the widget to actually be built in the ListView
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _scrollToKey(targetKey);
      }
    });
  }

  /// Ensure data is loaded for a specific language code
  Future<void> _ensureDataLoaded(LanguageCodes code) async {
    // Check if data is already loaded
    if (_helper.data.containsKey(code) ||
        _helper.dataOverrides.containsKey(code)) {
      return;
    }

    // Data might not be loaded yet, try to load it by changing to that code
    // This will trigger the data loading in the change method
    // But we need to restore the current code after
    final currentCode = _helper.code;
    if (currentCode != code) {
      await _helper.change(code);
      // Restore original code if needed (optional, as we'll use the loaded data)
      // Actually, we don't need to restore, just ensure data is loaded
    }
  }

  void _initializeControllers() {
    _controllers.clear();
    _editedTranslations.clear();

    if (_targetLanguage == null) return;

    // Check both data and dataOverrides (overrides take precedence)
    final targetData =
        _helper.dataOverrides[_targetLanguage] ?? _helper.data[_targetLanguage];
    if (targetData == null) return;

    for (final key in _allKeys) {
      // Get value from overrides first, then data
      final value =
          _helper.dataOverrides[_targetLanguage]?[key] ??
          _helper.data[_targetLanguage]?[key];

      if (value is String) {
        // Handle empty strings - they are valid values
        final controller = TextEditingController(text: value);
        controller.addListener(() {
          _editedTranslations[key] = controller.text;
        });
        _controllers[key] = controller;
        _editedTranslations[key] = value;
      } else if (value is LanguageConditions) {
        // Store LanguageConditions as-is for editing
        _editedTranslations[key] = value;
      } else if (value != null) {
        // For other types, store as-is
        _editedTranslations[key] = value;
      }
      // If value is null, don't add it to editedTranslations
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    _searchController.dispose();
    _scrollController.dispose();
    _flashAnimationController?.dispose();
    super.dispose();
  }

  /// Trigger flash animation for a specific key
  void _triggerFlashAnimation(String key) {
    if (!mounted) return;

    setState(() {
      _flashingKey = key;
      _flashRepeatCount = 0;
    });

    // Start the first flash
    _flashAnimationController?.reset();
    _flashAnimationController?.forward();
  }

  /// Handle flash animation completion - repeat if needed
  void _handleFlashAnimationComplete() {
    if (!mounted || _flashingKey == null) return;

    _flashRepeatCount++;

    if (_flashRepeatCount < _maxFlashRepeats) {
      // Repeat the animation
      _flashAnimationController?.reset();
      _flashAnimationController?.forward();
    } else {
      // Stop after max repeats
      _stopFlashAnimation();
    }
  }

  /// Stop the flash animation
  void _stopFlashAnimation() {
    if (!mounted) return;

    _flashAnimationController?.stop();
    _flashAnimationController?.reset();

    setState(() {
      _flashingKey = null;
      _flashRepeatCount = 0;
    });
  }

  /// Handle tap on the flashing card to stop animation
  void _onCardTap(String key) {
    if (_flashingKey == key) {
      _stopFlashAnimation();
    }
  }

  List<String> get _filteredKeys {
    if (_searchQuery.isEmpty) return _allKeys.toList();

    return _allKeys.where((key) {
      final defaultText = _getDefaultText(key);
      final targetText = _getTargetText(key);
      return key.toLowerCase().contains(_searchQuery) ||
          defaultText.toLowerCase().contains(_searchQuery) ||
          targetText.toLowerCase().contains(_searchQuery);
    }).toList();
  }

  String _getDefaultText(String key) {
    if (_defaultLanguage == null) return '';

    // Check both dataOverrides and data (overrides take precedence)
    final value =
        _helper.dataOverrides[_defaultLanguage]?[key] ??
        _helper.data[_defaultLanguage]?[key];

    if (value == null) return '';
    if (value is String) return value;
    if (value is LanguageConditions) {
      return 'LanguageConditions (${value.conditions.keys.join(', ')})';
    }
    return value.toString();
  }

  String _getTargetText(String key) {
    if (_editedTranslations.containsKey(key)) {
      final value = _editedTranslations[key];
      if (value is String) return value;
      if (value is LanguageConditions) {
        return 'LanguageConditions (${value.conditions.keys.join(', ')})';
      }
      return value?.toString() ?? '';
    }

    if (_targetLanguage == null) return '';

    // Check both dataOverrides and data (overrides take precedence)
    final value =
        _helper.dataOverrides[_targetLanguage]?[key] ??
        _helper.data[_targetLanguage]?[key];

    if (value == null) return '';
    if (value is String) return value;
    if (value is LanguageConditions) {
      return 'LanguageConditions (${value.conditions.keys.join(', ')})';
    }
    return value.toString();
  }

  dynamic _getTargetValue(String key) {
    if (_editedTranslations.containsKey(key)) {
      return _editedTranslations[key];
    }

    if (_targetLanguage == null) return null;

    // Check both dataOverrides and data (overrides take precedence)
    return _helper.dataOverrides[_targetLanguage]?[key] ??
        _helper.data[_targetLanguage]?[key];
  }

  LanguageConditions? _getDefaultLanguageCondition(String key) {
    if (_defaultLanguage == null) return null;

    // Check both dataOverrides and data (overrides take precedence)
    final value =
        _helper.dataOverrides[_defaultLanguage]?[key] ??
        _helper.data[_defaultLanguage]?[key];

    if (value is LanguageConditions) {
      return value;
    }
    return null;
  }

  Future<void> _saveTranslations() async {
    final updatedTranslations = <LanguageCodes, Map<String, dynamic>>{
      _targetLanguage!: Map<String, dynamic>.from(_editedTranslations),
    };

    // Call the callback and wait for it to complete if it's async
    final callback = widget.onTranslationsUpdated;
    if (callback != null) {
      await callback(updatedTranslations);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Translations saved successfully'),
          duration: Duration(seconds: 2),
        ),
      );

      // Pop the screen after translations are applied
      Navigator.of(context).pop();
    }
  }

  void _cancelEditing() {
    _initializeControllers();
    widget.onCancel?.call();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Changes discarded'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _convertStringToLanguageCondition(String key, String stringValue) {
    // Show dialog to get parameter name first
    showDialog(
      context: context,
      builder: (context) {
        final paramController = TextEditingController(text: 'count');
        bool isDisposed = false;

        return PopScope(
          canPop: true,
          onPopInvokedWithResult: (_, _) {
            // Only dispose if not already disposed
            if (!isDisposed) {
              isDisposed = true;
              paramController.dispose();
            }
          },
          child: AlertDialog(
            title: const Text('Convert to Condition'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Enter the parameter name that will be used in the translation:',
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: paramController,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'Parameter Name',
                    hintText: 'e.g., count, number, hours',
                    border: OutlineInputBorder(),
                    helperText: 'This parameter will be used in conditions',
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Current value:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(stringValue, style: const TextStyle(fontSize: 12)),
                      const SizedBox(height: 8),
                      const Text(
                        'This will become the default condition (_)',
                        style: TextStyle(
                          fontSize: 11,
                          fontStyle: FontStyle.italic,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  // Don't dispose here - let PopScope handle it
                  Navigator.of(context).pop();
                },
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  final param = paramController.text.trim();
                  if (param.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Parameter name cannot be empty'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }
                  final paramValue = param;
                  // Pop dialog - PopScope will handle controller disposal
                  Navigator.of(context).pop();

                  // Create a default LanguageConditions with the current string
                  final newCondition = LanguageConditions(
                    param: paramValue,
                    conditions: {
                      '_': stringValue, // Default condition
                    },
                  );

                  // Now show the editor to let user add more conditions
                  // Need to access the helper from parent context
                  final helper = _helper;
                  final defaultLanguage = _defaultLanguage;
                  final defaultCondition = defaultLanguage != null
                      ? (helper.data[defaultLanguage]?[key]
                                is LanguageConditions
                            ? helper.data[defaultLanguage]![key]
                                  as LanguageConditions
                            : null)
                      : null;

                  showDialog(
                    context: context,
                    builder: (context) => _LanguageConditionEditorDialog(
                      key: Key('$key-convert'),
                      translationKey: key,
                      initialCondition: newCondition,
                      defaultCondition: defaultCondition,
                      onSave: (editedCondition) {
                        // Get the controller to dispose later
                        final controllerToDispose = _controllers[key];

                        setState(() {
                          // Remove the controller from the map first
                          _controllers.remove(key);

                          // Update to LanguageConditions
                          _editedTranslations[key] = editedCondition;
                        });

                        // Dispose the controller after the frame completes
                        // to avoid using it after disposal
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          controllerToDispose?.dispose();
                        });

                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Converted to Condition successfully',
                            ),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                    ),
                  );
                },
                child: const Text('Continue'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _convertLanguageConditionToString(
    String key,
    LanguageConditions condition,
  ) {
    // Find the default condition value (_ or default) or use the first one
    String? defaultConditionKey;
    String? defaultConditionValue;

    // Try to find '_' or 'default' first
    if (condition.conditions.containsKey('_')) {
      defaultConditionKey = '_';
      defaultConditionValue = condition.conditions['_']?.toString();
    } else if (condition.conditions.containsKey('default')) {
      defaultConditionKey = 'default';
      defaultConditionValue = condition.conditions['default']?.toString();
    } else if (condition.conditions.isNotEmpty) {
      // Use the first condition if no default found
      final firstEntry = condition.conditions.entries.first;
      defaultConditionKey = firstEntry.key;
      defaultConditionValue = firstEntry.value?.toString();
    }

    if (defaultConditionValue == null || defaultConditionValue.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No valid condition value found'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Show dialog to confirm and optionally choose which condition to use
    showDialog(
      context: context,
      builder: (context) {
        String? selectedKey = defaultConditionKey;
        String? selectedValue = defaultConditionValue;

        return StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: const Text('Convert to String'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Select which condition value to use as the string:',
                  ),
                  const SizedBox(height: 12),
                  ...condition.conditions.entries.map((e) {
                    final isDefault =
                        e.key == '_' ||
                        e.key == 'default' ||
                        e.key == selectedKey;
                    return RadioListTile<String>(
                      title: Text(
                        e.key,
                        style: TextStyle(
                          fontWeight: isDefault
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                      subtitle: Text(
                        e.value.toString(),
                        style: const TextStyle(fontSize: 12),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      value: e.key,
                      // ignore: deprecated_member_use
                      groupValue: selectedKey,
                      // ignore: deprecated_member_use
                      onChanged: (value) {
                        setDialogState(() {
                          selectedKey = value;
                          selectedValue = e.value?.toString() ?? '';
                        });
                      },
                    );
                  }),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (selectedKey == null || selectedValue == null) {
                    return;
                  }
                  Navigator.of(context).pop();

                  // Convert to String
                  setState(() {
                    // Remove LanguageConditions from edited translations
                    _editedTranslations[key] = selectedValue!;

                    // Create a TextEditingController for the new String value
                    final controller = TextEditingController(
                      text: selectedValue!,
                    );
                    controller.addListener(() {
                      _editedTranslations[key] = controller.text;
                    });
                    _controllers[key] = controller;
                  });

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Converted to String using condition "$selectedKey"',
                      ),
                      backgroundColor: Colors.green,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
                child: const Text('Convert'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _editLanguageCondition(String key, LanguageConditions condition) {
    final defaultCondition = _getDefaultLanguageCondition(key);
    showDialog(
      context: context,
      builder: (context) => _LanguageConditionEditorDialog(
        key: Key(key),
        translationKey: key,
        initialCondition: condition,
        defaultCondition: defaultCondition,
        onSave: (editedCondition) {
          setState(() {
            _editedTranslations[key] = editedCondition;
          });
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Condition updated'),
              duration: Duration(seconds: 2),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_helper.codes.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Language Improver')),
        body: const Center(child: Text('No languages available')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Language Improver'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(120),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<LanguageCodes>(
                        initialValue: _defaultLanguage,
                        decoration: const InputDecoration(
                          labelText: 'Default Language',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        items: _helper.codes.map((code) {
                          return DropdownMenuItem(
                            value: code,
                            child: Text(code.name),
                          );
                        }).toList(),
                        onChanged: (value) async {
                          if (value != null && value != _targetLanguage) {
                            // Ensure data is loaded for the default language
                            if (!_helper.data.containsKey(value)) {
                              final currentCode = _helper.code;
                              // Load data for the default language
                              await _helper.change(value);
                              // Restore original language if it was different
                              if (currentCode != value) {
                                await _helper.change(currentCode);
                              }
                            }
                            setState(() {
                              _defaultLanguage = value;
                            });
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<LanguageCodes>(
                        initialValue: _targetLanguage,
                        decoration: const InputDecoration(
                          labelText: 'Target Language',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        items: _helper.codes
                            .where((code) => code != _defaultLanguage)
                            .map((code) {
                              return DropdownMenuItem(
                                value: code,
                                child: Text(code.name),
                              );
                            })
                            .toList(),
                        onChanged: (value) async {
                          if (value != null) {
                            // Ensure data is loaded for the target language
                            if (!_helper.data.containsKey(value)) {
                              final currentCode = _helper.code;
                              // Load data for the target language
                              await _helper.change(value);
                              // Restore original language if it was different
                              if (currentCode != value) {
                                await _helper.change(currentCode);
                              }
                            }
                            setState(() {
                              _targetLanguage = value;
                              _initializeControllers();
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search translations...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                            },
                          )
                        : null,
                    border: const OutlineInputBorder(),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: _filteredKeys.isEmpty
          ? const Center(child: Text('No translations found'))
          : Container(
              color: Theme.of(context).scaffoldBackgroundColor,
              child: ListView.separated(
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 16),
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 8,
                ),
                itemCount: _filteredKeys.length,
                itemBuilder: (context, index) {
                  final key = _filteredKeys[index];
                  final defaultText = _getDefaultText(key);
                  final targetValue = _getTargetValue(key);

                  // Create or get GlobalKey for this translation key
                  if (!_keyMap.containsKey(key)) {
                    _keyMap[key] = GlobalKey();
                  }
                  final cardKey = _keyMap[key]!;

                  // Get flash animation value if this key is flashing
                  final isFlashing = _flashingKey == key;
                  final flashValue = isFlashing && _flashAnimation != null
                      ? _flashAnimation!.value
                      : 0.0;

                  // Get theme-aware colors
                  final theme = Theme.of(context);
                  final cardColor = theme.cardColor;
                  final dividerColor = theme.dividerColor;
                  final colorScheme = theme.colorScheme;
                  final isDark = colorScheme.brightness == Brightness.dark;

                  // Flash highlight color - use blue with higher opacity for clearer visibility
                  final flashBlue = isDark
                      ? Colors.blue.withValues(
                          alpha: 0.5,
                        ) // More visible in dark
                      : Colors.blue.shade100; // Clearer in light

                  final flashBorderBlue = isDark
                      ? Colors
                            .blue
                            .shade300 // Brighter blue in dark
                      : Colors.blue.shade500; // Brighter blue in light

                  // Calculate animated colors based on flash value
                  final backgroundColor = isFlashing
                      ? Color.lerp(cardColor, flashBlue, flashValue)!
                      : cardColor;

                  final borderColor = isFlashing
                      ? Color.lerp(dividerColor, flashBorderBlue, flashValue)!
                      : dividerColor;

                  final borderWidth = isFlashing
                      ? 2.0 + (flashValue * 2.0)
                      : 1.0;

                  final elevation = isFlashing ? 4.0 + (flashValue * 4.0) : 2.0;

                  return GestureDetector(
                    onTap: () => _onCardTap(key),
                    child: Card(
                      key: cardKey,
                      margin: const EdgeInsets.symmetric(
                        vertical: 4,
                        horizontal: 12,
                      ),
                      elevation: elevation,
                      color: backgroundColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: borderColor,
                          width: borderWidth,
                        ),
                      ),
                      shadowColor: isFlashing
                          ? Colors.blue.withValues(alpha: 0.3)
                          : Colors.black.withValues(alpha: 0.08),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Translation key
                            Builder(
                              builder: (context) {
                                final theme = Theme.of(context);
                                final colorScheme = theme.colorScheme;
                                final isDark =
                                    colorScheme.brightness == Brightness.dark;

                                // Use a distinctive blue tint for the key container
                                // Complements the blue flash animation
                                final keyBgColor = isDark
                                    ? Colors.blue.withValues(alpha: 0.15)
                                    : Colors.blue.withValues(alpha: 0.08);
                                final keyTextColor = isDark
                                    ? Colors.blue.shade200
                                    : Colors.blue.shade700;
                                final keyBorderColor = isDark
                                    ? Colors.blue.withValues(alpha: 0.3)
                                    : Colors.blue.withValues(alpha: 0.2);

                                return Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: keyBgColor,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: keyBorderColor),
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Key:',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: keyTextColor,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        key,
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: keyTextColor,
                                          fontWeight: FontWeight.w500,
                                          fontFamily: 'monospace',
                                        ),
                                        maxLines: 3,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 12),

                            // Default language translation
                            if (targetValue is String)
                              Builder(
                                builder: (context) {
                                  final theme = Theme.of(context);
                                  final colorScheme = theme.colorScheme;
                                  final isDark =
                                      colorScheme.brightness == Brightness.dark;

                                  // Use a warm amber/orange tint for default translations
                                  // Creates nice contrast with blue flash
                                  final defaultBgColor = isDark
                                      ? Colors.orange.withValues(alpha: 0.15)
                                      : Colors.orange.withValues(alpha: 0.08);
                                  final defaultTextColor = isDark
                                      ? Colors.orange.shade200
                                      : Colors.orange.shade800;
                                  final defaultBorderColor = isDark
                                      ? Colors.orange.withValues(alpha: 0.3)
                                      : Colors.orange.withValues(alpha: 0.2);

                                  return Container(
                                    padding: const EdgeInsets.all(8),
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      color: defaultBgColor,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: defaultBorderColor,
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${_defaultLanguage?.name ?? 'Default'}:',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: defaultTextColor,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        _ExpandableText(
                                          text: defaultText,
                                          style: const TextStyle(fontSize: 14),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              )
                            else if (targetValue is LanguageConditions)
                              // Show default LanguageConditions for reference
                              Builder(
                                builder: (context) {
                                  final defaultCondition =
                                      _getDefaultLanguageCondition(key);
                                  if (defaultCondition != null) {
                                    final theme = Theme.of(context);
                                    final colorScheme = theme.colorScheme;
                                    final isDark =
                                        colorScheme.brightness ==
                                        Brightness.dark;

                                    // Use a warm amber/orange tint for default translations
                                    // Creates nice contrast with blue flash
                                    final defaultBgColor = isDark
                                        ? Colors.orange.withValues(alpha: 0.15)
                                        : Colors.orange.withValues(alpha: 0.08);
                                    final defaultTextColor = isDark
                                        ? Colors.orange.shade200
                                        : Colors.orange.shade800;
                                    final defaultBorderColor = isDark
                                        ? Colors.orange.withValues(alpha: 0.3)
                                        : Colors.orange.withValues(alpha: 0.2);

                                    return Container(
                                      padding: const EdgeInsets.all(8),
                                      margin: const EdgeInsets.only(bottom: 8),
                                      decoration: BoxDecoration(
                                        color: defaultBgColor,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: defaultBorderColor,
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '${_defaultLanguage?.name ?? 'Default'} (with Condition):',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: defaultTextColor,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Param: ${defaultCondition.param}',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey[700],
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          ...defaultCondition.conditions.entries.map((
                                            e,
                                          ) {
                                            final isDefault =
                                                e.key == '_' ||
                                                e.key == 'default';
                                            return Padding(
                                              padding: const EdgeInsets.only(
                                                bottom: 6,
                                              ),
                                              child: Row(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.center,
                                                children: [
                                                  Container(
                                                    width: 30,
                                                    height: 30,
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 8,
                                                          vertical: 4,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: isDefault
                                                          ? Colors.orange[200]
                                                          : Colors.orange[100],
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            8,
                                                          ),
                                                    ),
                                                    child: Center(
                                                      child: Text(
                                                        e.key,
                                                        style: TextStyle(
                                                          fontSize: 11,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: isDefault
                                                              ? Colors
                                                                    .orange[900]
                                                              : Colors
                                                                    .orange[800],
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Expanded(
                                                    child: Container(
                                                      padding:
                                                          const EdgeInsets.all(
                                                            8,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color: Colors.white,
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              8,
                                                            ),
                                                        border: Border.all(
                                                          color:
                                                              Colors.grey[300]!,
                                                        ),
                                                      ),
                                                      child: _ExpandableText(
                                                        text: e.value
                                                            .toString(),
                                                        style: const TextStyle(
                                                          fontSize: 12,
                                                        ),
                                                        maxLines: 2,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );
                                          }),
                                        ],
                                      ),
                                    );
                                  }
                                  return const SizedBox.shrink();
                                },
                              ),

                            const SizedBox(height: 12),

                            // Target language translation (editable)
                            if (targetValue is String)
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  TextField(
                                    controller: _controllers[key],
                                    decoration: InputDecoration(
                                      labelText:
                                          '${_targetLanguage?.name ?? 'Target'}:',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 8,
                                          ),
                                    ),
                                    style: const TextStyle(fontSize: 14),
                                    maxLines: null,
                                    minLines: 1,
                                  ),
                                  const SizedBox(height: 8),
                                  OutlinedButton.icon(
                                    onPressed: () =>
                                        _convertStringToLanguageCondition(
                                          key,
                                          targetValue,
                                        ),
                                    icon: const Icon(
                                      Icons.auto_awesome,
                                      size: 16,
                                    ),
                                    label: const Text(
                                      'Convert to Condition',
                                      style: TextStyle(fontSize: 12),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 12,
                                      ),
                                      minimumSize: Size.zero,
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                  ),
                                ],
                              )
                            else if (targetValue is LanguageConditions)
                              InkWell(
                                onTap: () =>
                                    _editLanguageCondition(key, targetValue),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Target LanguageConditions
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.blue[50],
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: Colors.blue[200]!,
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Text(
                                                '${_targetLanguage?.name ?? 'Target'}:',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.blue[900],
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              const Icon(
                                                Icons.edit,
                                                size: 16,
                                                color: Colors.blue,
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Param: ${targetValue.param}',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.blue[800],
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          ...targetValue.conditions.entries.map((
                                            e,
                                          ) {
                                            final isDefault =
                                                e.key == '_' ||
                                                e.key == 'default';
                                            return Padding(
                                              padding: const EdgeInsets.only(
                                                bottom: 6,
                                              ),
                                              child: Row(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.center,
                                                children: [
                                                  Container(
                                                    width: 30,
                                                    height: 30,
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 8,
                                                          vertical: 4,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: isDefault
                                                          ? Colors.blue[200]
                                                          : Colors.blue[100],
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            8,
                                                          ),
                                                    ),
                                                    child: Center(
                                                      child: Text(
                                                        e.key,
                                                        style: TextStyle(
                                                          fontSize: 11,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: isDefault
                                                              ? Colors.blue[900]
                                                              : Colors
                                                                    .blue[800],
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Expanded(
                                                    child: Container(
                                                      padding:
                                                          const EdgeInsets.all(
                                                            8,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color: Colors.white,
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              8,
                                                            ),
                                                        border: Border.all(
                                                          color:
                                                              Colors.blue[200]!,
                                                        ),
                                                      ),
                                                      child: _ExpandableText(
                                                        text: e.value
                                                            .toString(),
                                                        style: const TextStyle(
                                                          fontSize: 12,
                                                        ),
                                                        maxLines: 2,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );
                                          }),
                                        ],
                                      ),
                                    ),

                                    const SizedBox(height: 8),
                                    OutlinedButton.icon(
                                      onPressed: () =>
                                          _convertLanguageConditionToString(
                                            key,
                                            targetValue,
                                          ),
                                      icon: const Icon(
                                        Icons.auto_awesome,
                                        size: 16,
                                      ),
                                      label: const Text(
                                        'Convert to String',
                                        style: TextStyle(fontSize: 12),
                                      ),
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 12,
                                        ),
                                        minimumSize: Size.zero,
                                        tapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            else
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.amber[50],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${_targetLanguage?.name ?? 'Target'}:',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.amber[900],
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      targetValue?.toString() ?? 'null',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.amber[800],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (widget.showCancelButton)
            FloatingActionButton.extended(
              onPressed: _cancelEditing,
              heroTag: 'cancel',
              backgroundColor: Colors.grey,
              icon: const Icon(Icons.cancel),
              label: const Text('Cancel'),
            ),
          if (widget.showCancelButton && widget.showSaveButton)
            const SizedBox(width: 8),
          if (widget.showSaveButton)
            FloatingActionButton.extended(
              onPressed: _saveTranslations,
              heroTag: 'save',
              icon: const Icon(Icons.save),
              label: const Text('Save'),
            ),
        ],
      ),
    );
  }
}

/// Dialog widget for editing LanguageConditions
class _LanguageConditionEditorDialog extends StatefulWidget {
  final String translationKey;
  final LanguageConditions initialCondition;
  final void Function(LanguageConditions) onSave;
  final LanguageConditions? defaultCondition;

  const _LanguageConditionEditorDialog({
    required this.translationKey,
    required this.initialCondition,
    required this.onSave,
    this.defaultCondition,
    super.key,
  });

  @override
  State<_LanguageConditionEditorDialog> createState() =>
      _LanguageConditionEditorDialogState();
}

class _LanguageConditionEditorDialogState
    extends State<_LanguageConditionEditorDialog> {
  late TextEditingController _paramController;
  final Map<String, TextEditingController> _conditionControllers = {};
  final List<String> _conditionKeys = [];

  @override
  void initState() {
    super.initState();
    _paramController = TextEditingController(
      text: widget.initialCondition.param,
    );

    // Initialize condition controllers
    final conditions = widget.initialCondition.conditions;
    for (final entry in conditions.entries) {
      final conditionKey = entry.key;
      _conditionKeys.add(conditionKey);
      _conditionControllers[conditionKey] = TextEditingController(
        text: entry.value.toString(),
      );
    }

    // Sort keys: numeric keys first, then special keys like '_' and 'default'
    _conditionKeys.sort((a, b) {
      final aNum = int.tryParse(a);
      final bNum = int.tryParse(b);

      if (aNum != null && bNum != null) {
        return aNum.compareTo(bNum);
      }
      if (aNum != null) return -1;
      if (bNum != null) return 1;

      // Special keys go last
      if (a == '_' || a == 'default') return 1;
      if (b == '_' || b == 'default') return -1;

      return a.compareTo(b);
    });
  }

  @override
  void dispose() {
    _paramController.dispose();
    for (final controller in _conditionControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _addCondition() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Condition'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter condition key:'),
            const SizedBox(height: 8),
            TextField(
              controller: controller,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'e.g., 0, 1, _ or default',
                border: OutlineInputBorder(),
                helperText: 'Common keys: 0, 1, 2, _ (default)',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              controller.dispose();
              Navigator.of(context).pop();
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final value = controller.text.trim();
              if (value.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Condition key cannot be empty'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              if (_conditionKeys.contains(value)) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Condition key "$value" already exists'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              controller.dispose();
              Navigator.of(context).pop();
              setState(() {
                _conditionKeys.add(value);
                _conditionControllers[value] = TextEditingController();
                // Re-sort to maintain order
                _conditionKeys.sort((a, b) {
                  final aNum = int.tryParse(a);
                  final bNum = int.tryParse(b);

                  if (aNum != null && bNum != null) {
                    return aNum.compareTo(bNum);
                  }
                  if (aNum != null) return -1;
                  if (bNum != null) return 1;

                  if (a == '_' || a == 'default') return 1;
                  if (b == '_' || b == 'default') return -1;

                  return a.compareTo(b);
                });
              });
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _removeCondition(String key) {
    setState(() {
      _conditionKeys.remove(key);
      _conditionControllers[key]?.dispose();
      _conditionControllers.remove(key);
    });
  }

  void _save() {
    if (_paramController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Parameter name cannot be empty'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_conditionKeys.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('At least one condition is required'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validate all conditions have values
    for (final key in _conditionKeys) {
      final controller = _conditionControllers[key];
      if (controller == null || controller.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Condition "$key" cannot be empty'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    // Build conditions map
    final conditions = <String, dynamic>{};
    for (final key in _conditionKeys) {
      final controller = _conditionControllers[key]!;
      conditions[key] = controller.text.trim();
    }

    final editedCondition = LanguageConditions(
      param: _paramController.text.trim(),
      conditions: conditions,
    );

    widget.onSave(editedCondition);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.9,
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.edit, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Edit Condition',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.translationKey,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Show default LanguageConditions for reference
                    if (widget.defaultCondition != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  size: 18,
                                  color: Colors.grey[700],
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Reference (Default Language)',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Parameter: ${widget.defaultCondition!.param}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[800],
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Conditions:',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            ...widget.defaultCondition!.conditions.entries.map((
                              e,
                            ) {
                              final isDefault =
                                  e.key == '_' || e.key == 'default';
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 6),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 40,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isDefault
                                            ? Colors.orange[100]
                                            : Colors.grey[200],
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Center(
                                        child: Text(
                                          e.key,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 11,
                                            color: isDefault
                                                ? Colors.orange[900]
                                                : Colors.grey[900],
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          border: Border.all(
                                            color: Colors.grey[300]!,
                                          ),
                                        ),
                                        child: Text(
                                          e.value.toString(),
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    ],
                    // Parameter input
                    TextField(
                      controller: _paramController,
                      decoration: const InputDecoration(
                        labelText: 'Parameter Name',
                        hintText: 'e.g., count, hours, number',
                        border: OutlineInputBorder(),
                        helperText:
                            'The parameter used in the translation text',
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Conditions header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Conditions',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: _addCondition,
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Add Condition'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Conditions list
                    if (_conditionKeys.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Center(
                          child: Text(
                            'No conditions. Add one to get started.',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      )
                    else
                      ..._conditionKeys.map((conditionKey) {
                        final controller = _conditionControllers[conditionKey]!;
                        final isDefault =
                            conditionKey == '_' || conditionKey == 'default';

                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isDefault
                                            ? Colors.blue[100]
                                            : Colors.green[100],
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        conditionKey,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: isDefault
                                              ? Colors.blue[900]
                                              : Colors.green[900],
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                    if (isDefault) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.blue[200],
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: const Text(
                                          'DEFAULT',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.blue,
                                          ),
                                        ),
                                      ),
                                    ],
                                    const Spacer(),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline),
                                      color: Colors.red,
                                      onPressed: () =>
                                          _removeCondition(conditionKey),
                                      tooltip: 'Remove Condition',
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                TextField(
                                  controller: controller,
                                  decoration: InputDecoration(
                                    labelText: 'Translation Value',
                                    hintText:
                                        'Enter translation for this condition',
                                    border: const OutlineInputBorder(),
                                    helperText: isDefault
                                        ? 'Used when no other condition matches'
                                        : null,
                                  ),
                                  maxLines: null,
                                  minLines: 1,
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                  ],
                ),
              ),
            ),

            // Footer buttons
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: _save,
                    icon: const Icon(Icons.save),
                    label: const Text('Save'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Expandable text widget that shows long text with expand/collapse functionality
class _ExpandableText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final int maxLines;
  final int truncateLength;

  const _ExpandableText({
    required this.text,
    this.style,
    this.maxLines = 3,
    // ignore: unused_element_parameter
    this.truncateLength = 100,
  });

  @override
  State<_ExpandableText> createState() => _ExpandableTextState();
}

class _ExpandableTextState extends State<_ExpandableText> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final textLength = widget.text.length;
    final isLong = textLength > widget.truncateLength;

    if (!isLong) {
      return Text(widget.text, style: widget.style);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                _isExpanded
                    ? widget.text
                    : '${widget.text.substring(0, widget.truncateLength)}...',
                style: widget.style,
                maxLines: _isExpanded ? null : widget.maxLines,
                overflow: _isExpanded ? null : TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        if (isLong)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$textLength chars',
                    style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: () {
                    setState(() {
                      _isExpanded = !_isExpanded;
                    });
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _isExpanded ? Icons.expand_less : Icons.expand_more,
                        size: 16,
                        color: Theme.of(context).primaryColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _isExpanded ? 'Show less' : 'Show more',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
