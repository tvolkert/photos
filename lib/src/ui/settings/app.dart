import 'package:flutter/material.dart' show CircularProgressIndicator;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'package:photos/src/model/ui.dart';
import 'package:photos/src/ui/common/app.dart';
import 'package:photos/src/ui/common/notifications.dart';

import 'nav.dart';
import 'home.dart';

class SettingsAppLoadingScreen extends StatelessWidget {
  const SettingsAppLoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: SettingsNav.defaultBgColor,
      child: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}

class SettingsApp extends StatefulWidget {
  const SettingsApp({super.key});

  static const Map<ShortcutActivator, Intent> _settingsShortcuts = <ShortcutActivator, Intent>{
    SingleActivator(LogicalKeyboardKey.select): ActivateIntent(),
    SingleActivator(LogicalKeyboardKey.arrowRight): ActivateIntent(),
    SingleActivator(LogicalKeyboardKey.tab): ActivateIntent(),
  };

  @override
  State<SettingsApp> createState() => _SettingsAppState();
}

class _SettingsAppState extends State<SettingsApp> with AppControllerMixin<SettingsApp> {
  @override
  void initState() {
    super.initState();
    UiBinding.instance.controller = this;
  }

  @override
  void dispose() {
    UiBinding.instance.controller = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget result = _SettingsAppScope(
      state: this,
      isShowDebugInfo: isShowDebugInfo,
      child: FocusScope(
        child: DefaultTextStyle(
          style: const TextStyle(color: Color(0xffffffff)),
          child: Stack(
            fit: StackFit.passthrough,
            children: <Widget>[
              const SettingsNav(root: SettingsHome()),
              NotificationsPanel(
                upperLeft: ErrorsNotification(errors),
              ),
            ],
          ),
        ),
      ),
    );
    assert(() {
      result = CheckedModeBanner(child: result);
      return true;
    }());
    return Shortcuts(
      shortcuts: {
        ...WidgetsApp.defaultShortcuts,
        ...SettingsApp._settingsShortcuts,
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          ...WidgetsApp.defaultActions,
        },
        child: Localizations(
          delegates: const [DefaultWidgetsLocalizations.delegate],
          locale: const Locale('en'),
          child: Title(
            title: 'Photos Screensaver',
            color: const Color(0xff000000),
            child: FocusTraversalGroup(
              policy: ReadingOrderTraversalPolicy(),
              child: result,
            ),
          ),
        ),
      ),
    );
  }
}

class _SettingsAppScope extends InheritedWidget {
  const _SettingsAppScope({
    required this.state,
    required this.isShowDebugInfo,
    required Widget child,
  }) : super(child: child);

  final _SettingsAppState state;
  final bool isShowDebugInfo;

  @override
  bool updateShouldNotify(_SettingsAppScope old) {
    return isShowDebugInfo != old.isShowDebugInfo;
  }
}
