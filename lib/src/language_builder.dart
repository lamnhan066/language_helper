part of '../language_helper.dart';

// ignore: deprecated_member_use_from_same_package
@Deprecated('Use `LanguageBuilder` insteads')
class LanguageNotifier extends LanguageBuilder {
  const LanguageNotifier({
    super.key,
    required super.builder,
    super.forceRebuild,
  });
}

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
      _languageHelper._print(
          'Cannot find the root context of this context. Add $this to states');
      _languageHelper._states.add(this);
    } else if (!_languageHelper._states.contains(getRoot)) {
      _languageHelper
          ._print('Added root context $getRoot to LanguageHelper states');
      _languageHelper._states.add(getRoot);
    } else {
      _languageHelper
          ._print('This root context $this was already contained in states');
    }

    _languageHelper
        ._print('Length of the states: ${_languageHelper._states.length}');

    super.didChangeDependencies();
  }

  @override
  void dispose() {
    _languageHelper._print('Removed $this from LanguageHelper states');
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

class Lhb extends StatelessWidget {
  /// This is a short version of [LanguageBuilder] which means `LanguageHelperBuilder`.
  ///
  /// Wrap the widget that you want to change when changing language
  const Lhb(this.builder, {super.key, this.forceRebuild = false});

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
