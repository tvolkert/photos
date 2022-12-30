import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'app.dart';

mixin DreamBinding on AppBindingBase {
  /// The singleton instance of this object.
  static late DreamBinding _instance;
  static DreamBinding get instance => _instance;

  static const _channel = MethodChannel('photos.stefaney.com/channel');

  Future<void> wakeUp() async {
    try {
      await _channel.invokeMethod('wakeUp');
    } on PlatformException catch (error, stack) {
      debugPrint('failed to wake up: $error\n$stack');
    } on MissingPluginException catch (error) {
      // This channel is only wired up in non-interactive mode (when running as
      // a screensaver), so a `MissingPluginException` signals that `wakeUp`
      // was called when running in interactive mode.
      assert(false, 'wakeUp() was called in interactive mode');
    }
  }

  @override
  @protected
  @mustCallSuper
  Future<void> initInstances() async {
    await super.initInstances();
    _instance = this;
  }
}
