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
  final Widget Function(BuildContext _) builder;

  /// The plugin only rebuilds the root widget even when you use multiple [LanguageBuilder],
  /// So, you can set this value to `true` if you want to force rebuild
  /// this widget when the language is changed. Use the default value
  /// from LanguageHelper.initial() if this value is null.
  final bool? forceRebuild;

  /// Add the custom instance of `LanguageHelper`.
  final LanguageHelper? languageHelper;

  @override
  State<LanguageBuilder> createState() => _LanguageBuilderState();
}

class _LanguageBuilderState extends State<LanguageBuilder> with UpdateLanguage {
  var _key = UniqueKey();
  late LanguageHelper _languageHelper;

  /// Update the language
  @override
  void updateLanguage() {
    if (mounted) {
      setState(() {
        _key = UniqueKey();
      });
    }
  }

  /// Get the root state
  static _LanguageBuilderState? _of(BuildContext context) {
    return context.findRootAncestorStateOfType<_LanguageBuilderState>();
  }

  @override
  void initState() {
    super.initState();
    _languageHelper = widget.languageHelper ?? LanguageHelper.instance;
    if ((widget.forceRebuild == true ||
        (widget.forceRebuild == null && _languageHelper._forceRebuild))) {
      if (_languageHelper._states.add(this)) {
        printDebug(() =>
            'Added $this to the states because the `forceRebuild` is `true`');
      }
    } else {
      final getRoot = _of(context);

      // Because the Widget trees are built from a higher level to a lower level,
      // so all the posible `root` widgets have definitely been added to the list
      // of the states. So we just need to add the state that its' parent is null.
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
      key: _key,
      child: widget.builder(context),
    );
  }
}

class Tr extends StatelessWidget {
  /// This is a short version of [LanguageBuilder].
  ///
  /// Wrap the widget that you want to change when changing language
  ///
  /// Ex:
  /// ``` dart
  /// Tr((_) => 'hello world'.tr),
  /// ```
  const Tr(
    this.builder, {
    super.key,
    this.forceRebuild = false,
    this.languageHelper,
  });

  /// Add your builder
  final Widget Function(BuildContext _) builder;

  /// The plugin only rebuilds the root widget even when you use multiple [LanguageBuilder],
  /// So, you can set this value to `true` if you want to force rebuild
  /// this widget when the language is changed. Use the default value
  /// from LanguageHelper.initial() if this value is null.
  final bool forceRebuild;

  /// Add the custom instance of `LanguageHelper`.
  final LanguageHelper? languageHelper;

  @override
  Widget build(BuildContext context) {
    return LanguageBuilder(
      key: key,
      builder: builder,
      forceRebuild: forceRebuild,
      languageHelper: languageHelper,
    );
  }
}
