part of '../language_helper.dart';

/// @Source https://hillel.dev/2018/08/15/flutter-how-to-rebuild-the-entire-app-to-change-the-theme-or-locale/

class LanguageBuilder extends StatefulWidget {
  /// Wrap the widget that you want to change when changing language
  const LanguageBuilder({
    super.key,
    required this.builder,
    this.forceRebuild,
    this.languageHelper,
    this.refreshTree = false,
  });

  /// Add your builder
  final Widget Function(BuildContext context) builder;

  /// The plugin only rebuilds the root widget even when you use multiple [LanguageBuilder].
  ///
  /// - `true`  → always rebuild this widget when the language is changed.
  /// - `false` → only rebuild the root widget.
  /// - `null`  → fallback to `LanguageHelper.forceRebuild` default.
  final bool? forceRebuild;

  /// If `true`, the widget will be refreshed when the language is changed.
  /// It will rebuild the entire tree of the widget.
  final bool refreshTree;

  /// Add the custom instance of `LanguageHelper`.
  final LanguageHelper? languageHelper;

  @override
  State<LanguageBuilder> createState() => _LanguageBuilderState();
}

class _LanguageBuilderState extends State<LanguageBuilder> with UpdateLanguage {
  late LanguageHelper _languageHelper;
  bool get _forceRebuild =>
      widget.forceRebuild ?? _languageHelper._forceRebuild;

  /// Update the language
  @override
  void updateLanguage() {
    if (mounted) {
      setState(() {
        /* Update the state */
      });
    }
  }

  /// Get the root state
  _LanguageBuilderState? _of() {
    final root = context.findRootAncestorStateOfType<_LanguageBuilderState>();
    if (root == null ||
        !root.mounted ||
        root._languageHelper != _languageHelper) {
      return null;
    }
    return root;
  }

  /// Get the LanguageHelper based on priority:
  /// 1. Explicit languageHelper parameter
  /// 2. LanguageScope from widget tree
  /// 3. LanguageHelper.instance
  LanguageHelper _getLanguageHelper() {
    return widget.languageHelper ??
        LanguageScope.maybeOf(context) ??
        LanguageHelper.instance;
  }

  @override
  void initState() {
    super.initState();
    // Initialize with fallback, will be updated in didChangeDependencies
    _languageHelper = widget.languageHelper ?? LanguageHelper.instance;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Update languageHelper from LanguageScope if needed
    final newHelper = _getLanguageHelper();
    if (_languageHelper != newHelper) {
      // Remove from old helper's states
      _languageHelper._states.remove(this);
      // Add to new helper's states
      _languageHelper = newHelper;
      if (_languageHelper._states.add(this)) {
        printDebug(() => 'Added $this to the states');
      }
      printDebug(
        () => 'Length of the states: ${_languageHelper._states.length}',
      );
    } else if (_languageHelper._states.add(this)) {
      printDebug(() => 'Added $this to the states');
      printDebug(
        () => 'Length of the states: ${_languageHelper._states.length}',
      );
    }
  }

  @override
  void dispose() {
    printDebug(() => 'Removed $this from the states');
    _languageHelper._states.remove(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Push the current helper to the scope stack so extension methods can access it
    LanguageHelper._push(_languageHelper);
    try {
      final result = widget.refreshTree
          ? KeyedSubtree(
              key: ValueKey(_languageHelper.locale),
              child: widget.builder(context),
            )
          : widget.builder(context);
      return result;
    } finally {
      // Pop the helper from the stack after build completes
      LanguageHelper._pop();
    }
  }
}

class Tr extends StatelessWidget {
  /// A shorthand version of [LanguageBuilder].
  ///
  /// Example:
  /// ```dart
  /// Tr((_) => 'hello world'.tr),
  /// ```
  const Tr(
    this.builder, {
    super.key,
    this.forceRebuild,
    this.languageHelper,
    this.refreshTree = false,
  });

  /// Add your builder
  final Widget Function(BuildContext _) builder;

  /// Controls when to rebuild.
  ///
  /// - `true`  → always rebuild this widget when the language is changed.
  /// - `false` → only rebuild the root widget.
  /// - `null`  → fallback to `LanguageHelper.forceRebuild` default.
  final bool? forceRebuild;

  /// If `true`, the widget will be refreshed when the language is changed.
  /// It will rebuild the entire tree of the widget.
  final bool refreshTree;

  /// Add the custom instance of `LanguageHelper`.
  final LanguageHelper? languageHelper;

  @override
  Widget build(BuildContext context) {
    return LanguageBuilder(
      builder: builder,
      forceRebuild: forceRebuild,
      refreshTree: refreshTree,
      languageHelper: languageHelper,
    );
  }
}
