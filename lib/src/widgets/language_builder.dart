part of '../language_helper.dart';

/// @Source https://hillel.dev/2018/08/15/flutter-how-to-rebuild-the-entire-app-to-change-the-theme-or-locale/

/// A widget that rebuilds when the language changes.
///
/// [LanguageBuilder] is a [StatefulWidget] that manages rebuilds when the
/// associated [LanguageHelper] instance changes its language. It also provides
/// the helper to extension methods (`tr`, `trP`, etc.) via a stack mechanism
/// during the build phase.
///
/// The [LanguageHelper] used by this widget is determined by the following
/// priority order:
/// 1. Explicit `languageHelper` parameter
/// 2. [LanguageScope] from the widget tree (via [LanguageHelper.maybeOf])
/// 3. [LanguageHelper.instance] (fallback)
///
/// When building, [LanguageBuilder] pushes its helper onto a stack so that
/// extension methods can access it. This allows extension methods to work
/// with scoped helpers from [LanguageScope] without needing [BuildContext].
///
/// Example:
/// ```dart
/// LanguageBuilder(
///   builder: (context) => Column(
///     children: [
///       Text('Hello'.tr), // Uses the helper from LanguageScope or instance
///       Text('World'.trP({'count': 42})),
///     ],
///   ),
/// )
/// ```
///
/// With [LanguageScope]:
/// ```dart
/// LanguageScope(
///   languageHelper: myCustomHelper,
///   child: LanguageBuilder(
///     builder: (context) => Text('Hello'.tr), // Uses myCustomHelper
///   ),
/// )
/// ```
class LanguageBuilder extends StatefulWidget {
  /// Creates a [LanguageBuilder] that rebuilds when the language changes.
  ///
  /// The [builder] function will be called to build the widget tree whenever
  /// the associated [LanguageHelper] changes its language.
  const LanguageBuilder({
    super.key,
    required this.builder,
    this.forceRebuild,
    this.languageHelper,
    this.refreshTree = false,
  });

  /// The builder function that creates the widget tree.
  ///
  /// This function is called during build and whenever the language changes.
  /// Extension methods (`tr`, `trP`, etc.) called within this builder will
  /// use the helper associated with this [LanguageBuilder].
  final Widget Function(BuildContext context) builder;

  /// Controls when this widget rebuilds on language change.
  ///
  /// When you have multiple [LanguageBuilder] widgets in your tree, only the
  /// root widget typically rebuilds by default.
  ///
  /// - `true`  → always rebuild this widget when the language is changed.
  /// - `false` → only rebuild the root widget (default behavior).
  /// - `null`  → fallback to [LanguageHelper.forceRebuild] default.
  final bool? forceRebuild;

  /// If `true`, the widget will be completely refreshed when the language changes.
  ///
  /// When enabled, the entire widget tree will be destroyed and recreated using
  /// [KeyedSubtree]. This can be expensive but may be necessary for widgets that
  /// don't properly handle language changes.
  ///
  /// Use this only when you specifically need to reset widget state or when dealing
  /// with widgets that don't properly handle language changes.
  final bool refreshTree;

  /// An explicit [LanguageHelper] instance to use.
  ///
  /// If provided, this takes priority over any [LanguageScope] in the widget tree.
  /// If `null`, the widget will look for a [LanguageScope] ancestor, and if none
  /// is found, it will fall back to [LanguageHelper.instance].
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

  /// Gets the [LanguageHelper] to use based on priority:
  ///
  /// 1. Explicit `languageHelper` parameter (if provided)
  /// 2. [LanguageScope] from widget tree (via [LanguageHelper.maybeOf])
  /// 3. [LanguageHelper.instance] (fallback)
  LanguageHelper _getLanguageHelper() {
    return widget.languageHelper ??
        LanguageHelper.maybeOf(context) ??
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
    // during the synchronous build phase. Extension methods (tr, trP, etc.) don't have
    // BuildContext, so they rely on LanguageHelper._current to find the scoped helper.
    //
    // The stack is managed during build because Flutter builds are synchronous, so
    // when extension methods are called during widget.builder(context), they can
    // safely access the stack.
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
      // This ensures the stack is clean for the next build phase
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
