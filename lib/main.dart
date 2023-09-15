import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'src/model/app.dart';
import 'src/model/auth.dart';
import 'src/model/photos_library_api_model.dart';
import 'src/model/ui.dart';
import 'src/ui/montage/home_page.dart';
import 'src/ui/montage/app.dart';
import 'src/ui/settings/app.dart';

/// This exists merely for convenience during development.
void main() => dream();

@pragma('vm:entry-point')
void settingsMain() {
  _runWithErrorChecking(() async {
    await AppBinding.ensureInitialized();
    runApp(const SettingsAppLoadingScreen());
    await AuthBinding.instance.signInSilently();
    runApp(const SettingsApp());
  });
}

@pragma('vm:entry-point')
void dream() async {
  _runWithErrorChecking(() async {
    await AppBinding.ensureInitialized();
    final PhotosLibraryApiModel apiModel = PhotosLibraryApiModel();
    AuthBinding.instance.signInSilently();
    runApp(
      PhotosApp(
        interactive: false,
        apiModel: apiModel,
        child: const HomePage(),
      ),
    );
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
