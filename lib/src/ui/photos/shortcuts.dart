import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'intents.dart';

/// A [ShortcutManager] customized for the photos app.
///
/// This will cause key events to stop propagation to other handlers when a
/// shortcut has been registered. This enables a top-level key press handler to
/// catch all propagating key events and call [DreamBinding.wakeUp].
class PhotosShortcutManager extends ShortcutManager {
  PhotosShortcutManager() : super(shortcuts: _shortcuts);

  static const Map<ShortcutActivator, Intent> _shortcuts = <ShortcutActivator, Intent>{
    SingleActivator(LogicalKeyboardKey.arrowLeft): RewindIntent(),
    SingleActivator(LogicalKeyboardKey.mediaRewind): RewindIntent(),
    SingleActivator(LogicalKeyboardKey.mediaSkipBackward): RewindIntent(),
    SingleActivator(LogicalKeyboardKey.arrowRight): FastForwardIntent(),
    SingleActivator(LogicalKeyboardKey.mediaFastForward): FastForwardIntent(),
    SingleActivator(LogicalKeyboardKey.mediaSkipForward): FastForwardIntent(),
    SingleActivator(LogicalKeyboardKey.keyS): SpinIntent(),
    SingleActivator(LogicalKeyboardKey.add): ZoomIntent(),
    SingleActivator(LogicalKeyboardKey.minus): ShrinkIntent(),
  };

  @override
  @protected
  KeyEventResult handleKeypress(BuildContext context, KeyEvent event) {
    KeyEventResult result = super.handleKeypress(context, event);
    return result == KeyEventResult.handled
        ? KeyEventResult.handled
        : result;
  }
}
