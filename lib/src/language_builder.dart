part of 'language_helper.dart';

/// @Source https://hillel.dev/2018/08/15/flutter-how-to-rebuild-the-entire-app-to-change-the-theme-or-locale/

class LanguageBuilder extends StatefulWidget {
  /// Wrap the widget that you want to change when changing language
  const LanguageBuilder({
    Key? key,
    required this.builder,
    this.forceRebuild,
  }) : super(key: key);

  /// Add your builder
  final Widget Function(BuildContext _) builder;

  /// The plugin only rebuilds the root widget even when you use multiple [LanguageBuilder],
  /// So, you can set this value to `true` if you want to force rebuild
  /// this widget when the language is changed. Use the default value
  /// from LanguageHelper.initial() if this value is null.
  final bool? forceRebuild;

  @override
  State<LanguageBuilder> createState() => _LanguageBuilderState();
}

class _LanguageBuilderState extends State<LanguageBuilder> with UpdateLanguage {
  var _key = UniqueKey();
  final _languageHelper = LanguageHelper.instance;

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
  static _LanguageBuilderState? _of(BuildContext context, bool forceRebuild) {
    if (forceRebuild) return null;
    return context.findRootAncestorStateOfType<_LanguageBuilderState>();
  }

  @override
  void didChangeDependencies() {
    final getRoot = _of(
      context,
      widget.forceRebuild == true ||
          (widget.forceRebuild == null && _languageHelper._forceRebuild),
    );

    if (getRoot == null) {
      printDebug(
          'Cannot find the root context of this context. Add $this to states');
      _languageHelper._states.add(this);

      // Because the Widget trees are built from a higher level to a lower level,
      // so all the posible `root` widgets have definitely been added to the list
      // of the states. So this code is redundant.
      //
      // } else if (!_languageHelper._states.contains(getRoot)) {
      //   printDebug('Added root context $getRoot to LanguageHelper states');
      //   _languageHelper._states.add(getRoot);
    } else {
      printDebug('This root context $this was already contained in states');
    }

    printDebug('Length of the states: ${_languageHelper._states.length}');

    super.didChangeDependencies();
  }

  @override
  void dispose() {
    printDebug('Removed $this from LanguageHelper states');
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
  const Tr(this.builder, {super.key, this.forceRebuild = false});

  /// Add your builder
  final Widget Function(BuildContext _) builder;

  /// The plugin only rebuilds the root widget even when you use multiple [LanguageBuilder],
  /// So, you can set this value to `true` if you want to force rebuild
  /// this widget when the language is changed. Use the default value
  /// from LanguageHelper.initial() if this value is null.
  final bool forceRebuild;

  @override
  Widget build(BuildContext context) {
    return LanguageBuilder(
      key: key,
      builder: builder,
      forceRebuild: forceRebuild,
    );
  }
}
