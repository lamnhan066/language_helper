part of '../language_helper.dart';

/// @Source https://hillel.dev/2018/08/15/flutter-how-to-rebuild-the-entire-app-to-change-the-theme-or-locale/

/// Widget that rebuilds when the language changes. Provides helper to
/// extension methods (`tr`, `trP`, etc.) via a stack mechanism during build.
/// Helper priority: explicit parameter > [LanguageScope] >
/// [LanguageHelper.instance].
///
/// Example:
/// ```dart
/// LanguageBuilder(
///   builder: (context) => Column(
///     children: [
///       Text('Hello'.tr),
///       Text('World'.trP({'count': 42})),
///     ],
///   ),
/// )
/// ```
class LanguageBuilder extends StatefulWidget {
  /// Creates a builder that rebuilds when the language changes.
  const LanguageBuilder({
    required this.builder, super.key,
    this.forceRebuild,
    this.languageHelper,
    this.refreshTree = false,
  });

  /// Builder function called during build and when language changes. Extension
  /// methods use this builder's helper.
  final Widget Function(BuildContext context) builder;

  /// Controls rebuild behavior: `true` = always rebuild, `false` = only root
  /// rebuilds (default), `null` = use [LanguageHelper.forceRebuild].
  final bool? forceRebuild;

  /// If true, completely refreshes the widget tree using [KeyedSubtree] when
  /// language changes. Expensive but may be necessary for widgets that don't
  /// properly handle language changes.
  final bool refreshTree;

  /// Explicit helper instance. Takes priority over [LanguageScope]. If null,
  /// uses [LanguageScope] or [LanguageHelper.instance].
  final LanguageHelper? languageHelper;

  @override
  State<LanguageBuilder> createState() => _LanguageBuilderState();
}

class _LanguageBuilderState extends State<LanguageBuilder> with UpdateLanguage {
  late LanguageHelper _languageHelper;
  bool get _forceRebuild =>
      widget.forceRebuild ?? _languageHelper._forceRebuild;

  /// Updates the language
  @override
  void updateLanguage() {
    if (mounted) {
      setState(() {
        /* Update the state */
      });
    }
  }

  /// Gets the root state from the widget tree
  _LanguageBuilderState? _of() {
    final root = context.findRootAncestorStateOfType<_LanguageBuilderState>();
    if (root == null ||
        !root.mounted ||
        root._languageHelper != _languageHelper) {
      return null;
    }
    return root;
  }

  /// Gets the helper to use: explicit parameter > [LanguageScope] > [LanguageHelper.instance]
  LanguageHelper _getLanguageHelper() {
    return widget.languageHelper ?? LanguageHelper.of(context);
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
        _languageHelper._logger?.debug(() => 'Added $this to the states');
      }
      _languageHelper._logger?.debug(
        () => 'Length of the states: ${_languageHelper._states.length}',
      );
    } else if (_languageHelper._states.add(this)) {
      _languageHelper._logger?.debug(() => 'Added $this to the states');
      _languageHelper._logger?.debug(
        () => 'Length of the states: ${_languageHelper._states.length}',
      );
    }
  }

  @override
  void dispose() {
    _languageHelper._logger?.debug(() => 'Removed $this from the states');
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

/// Convenience wrapper around [LanguageBuilder] for simple translation
/// widgets. Use for quick translations; use [LanguageBuilder] when you need
/// direct helper access.
///
/// Example:
/// ```dart
/// Tr((_) => Text('Hello'.tr)),
///
/// Tr(
///   (_) => Text('Hello'.tr),
///   forceRebuild: true,
/// ),
/// ```
class Tr extends StatelessWidget {
  /// Creates a [Tr] widget that builds its child with translation support.
  ///
  /// The [builder] function will be called to build the widget whenever the
  /// language changes. Extension methods (`tr`, `trP`, etc.) will work
  /// within this builder.
  const Tr(
    this.builder, {
    super.key,
    this.forceRebuild,
    this.languageHelper,
    this.refreshTree = false,
  });

  /// Builder function called during build and when language changes. Extension
  /// methods use this widget's helper.
  final Widget Function(BuildContext _) builder;

  /// Controls rebuild behavior: `true` = always rebuild, `false` = only root
  /// rebuilds (default), `null` = use [LanguageHelper.forceRebuild].
  final bool? forceRebuild;

  /// If true, completely refreshes the widget tree using [KeyedSubtree] when
  /// language changes. Defaults to false.
  final bool refreshTree;

  /// Explicit helper instance. Takes priority over [LanguageScope]. If null,
  /// uses [LanguageScope] or [LanguageHelper.instance].
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
