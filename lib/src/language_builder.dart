part of 'language_helper.dart';

/// @Source https://hillel.dev/2018/08/15/flutter-how-to-rebuild-the-entire-app-to-change-the-theme-or-locale/

class LanguageBuilder extends StatefulWidget {
  /// Wrap the widget that you want to change when changing language
  const LanguageBuilder({
    super.key,
    required this.builder,
    this.forceRebuild,
    this.languageHelper,
  });

  /// Add your builder
  final Widget Function(BuildContext context) builder;

  /// The plugin only rebuilds the root widget even when you use multiple [LanguageBuilder].
  ///
  /// - `true`  → always rebuild this widget when the language is changed.
  /// - `false` → only rebuild the root widget.
  /// - `null`  → fallback to `LanguageHelper.forceRebuild` default.
  final bool? forceRebuild;

  /// Add the custom instance of `LanguageHelper`.
  final LanguageHelper? languageHelper;

  @override
  State<LanguageBuilder> createState() => _LanguageBuilderState();
}

class _LanguageBuilderState extends State<LanguageBuilder> with UpdateLanguage {
  late LanguageHelper _languageHelper;

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
  _LanguageBuilderState? _of(BuildContext context) {
    final root = context.findRootAncestorStateOfType<_LanguageBuilderState>();
    if (root == null ||
        !root.mounted ||
        root._languageHelper != _languageHelper) {
      return null;
    }
    return root;
  }

  @override
  void initState() {
    super.initState();
    _languageHelper = widget.languageHelper ?? LanguageHelper.instance;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final effectiveForceRebuild =
        widget.forceRebuild ?? _languageHelper._forceRebuild;

    if (effectiveForceRebuild) {
      if (_languageHelper._states.add(this)) {
        printDebug(
          () => 'Added $this to the states because `forceRebuild` is true',
        );
      }
    } else {
      final getRoot = _of(context);

      // Root detection: add only if this is the highest `LanguageBuilder`.
      if (getRoot == null && _languageHelper._states.add(this)) {
        printDebug(() => 'Added $this to the states');
      } else {
        printDebug(() => '$this was already contained in the states');
      }
    }
    printDebug(() => 'Length of the states: ${_languageHelper._states.length}');
  }

  @override
  void dispose() {
    printDebug(() => 'Removed $this from the states');
    _languageHelper._states.remove(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(
      key: ValueKey(_languageHelper.locale),
      child: widget.builder(context),
    );
  }
}

class Tr extends StatelessWidget {
  /// A shorthand version of [LanguageBuilder].
  ///
  /// Example:
  /// ```dart
  /// Tr((_) => 'hello world'.tr),
  /// ```
  const Tr(this.builder, {super.key, this.forceRebuild, this.languageHelper});

  /// Add your builder
  final Widget Function(BuildContext _) builder;

  /// Controls when to rebuild.
  ///
  /// - `true`  → always rebuild this widget when the language is changed.
  /// - `false` → only rebuild the root widget.
  /// - `null`  → fallback to `LanguageHelper.forceRebuild` default.
  final bool? forceRebuild;

  /// Add the custom instance of `LanguageHelper`.
  final LanguageHelper? languageHelper;

  @override
  Widget build(BuildContext context) {
    return LanguageBuilder(
      builder: builder,
      forceRebuild: forceRebuild,
      languageHelper: languageHelper,
    );
  }
}
