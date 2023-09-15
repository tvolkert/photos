import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/material.dart' show CircularProgressIndicator;

import 'src/model/app.dart';
import 'src/model/auth.dart';
import 'src/model/photos_library_api_model.dart';
import 'src/model/ui.dart';
import 'src/ui/home_page.dart';
import 'src/ui/app.dart';
import 'src/ui/settings.dart';

/// This exists merely for convenience during development.
void main() => dream();

@pragma('vm:entry-point')
void settingsMain() {
  _runWithErrorChecking(() async {
    await AppBinding.ensureInitialized();
    runApp(const _LoadingScreen());
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

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

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
