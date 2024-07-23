import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:photos/src/model/content_provider.dart';

import 'src/model/app.dart';
import 'src/model/auth.dart';
import 'src/model/ui.dart';
import 'src/ui/photos/app.dart';
import 'src/ui/settings/app.dart';

/// This exists merely for convenience during development.
void main() => dream();

@pragma('vm:entry-point')
void settingsMain() {
  _runWithErrorChecking(() async {
    await SettingsAppBinding.ensureInitialized();
    runApp(const SettingsAppLoadingScreen());
    await AuthBinding.instance.signInSilently();
    runApp(const SettingsApp());
  });
}

@pragma('vm:entry-point')
void dream() async {
  _runWithErrorChecking(() async {
    await PhotosAppBinding.ensureInitialized();
    await ContentProviderBinding.instance.init();
    runApp(const PhotosApp());
  });
}

void _runWithErrorChecking(AsyncCallback callback) {
  runZonedGuarded<void>(
    callback,
    (Object error, StackTrace stack) {
      debugPrint('Caught unhandled error by zone error handler.');
      debugPrint('$error\n$stack');
      UiBinding.instance.controller?.addError(error, stack);
    },
  );
}
