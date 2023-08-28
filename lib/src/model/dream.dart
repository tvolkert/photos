import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'app.dart';

mixin DreamBinding on AppBindingBase {
  /// The singleton instance of this object.
  static late DreamBinding _instance;
  static DreamBinding get instance => _instance;

  static const _channel = MethodChannel('photos.tvolkert.dev/channel');

  Future<void> wakeUp() async {
    try {
      await _channel.invokeMethod('wakeUp');
    } on PlatformException catch (error, stack) {
      debugPrint('failed to wake up: $error\n$stack');
    } on MissingPluginException {
      debugPrint('No platform implementation for wakeUp()');
    }
  }

  Future<Map<String, dynamic>> getDeviceInfo() async {
    try {
      Map<String, dynamic>? result = await _channel.invokeMapMethod<String, dynamic>('getDeviceInfo');
      return result!;
    } on PlatformException catch (error, stack) {
      debugPrint('failed to get device info: $error\n$stack');
      return const <String, dynamic>{};
    } on MissingPluginException {
      return const <String, dynamic>{};
    }
  }

  Future<void> writeFileToDownloads(String basename, Uint8List bytes) async {
    debugPrint('Writing $basename (${bytes.length} bytes) to downloads folder.');
    try {
      await _channel.invokeMethod<void>('writeFileToDownloads', <String, Object>{
        'basename': basename,
        'bytes': bytes,
      });
    } on PlatformException catch (error, stack) {
      debugPrint('failed to write file: $error\n$stack');
    } on MissingPluginException {
      // No-op
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
