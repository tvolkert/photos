import 'package:flutter/widgets.dart';
import 'package:flutter/material.dart' show CircularProgressIndicator;

import 'src/model/app.dart';
import 'src/model/auth.dart';
import 'src/model/photos_library_api_model.dart';
import 'src/pages/home_page.dart';
import 'src/pages/app.dart';
import 'src/pages/settings.dart';

/// This exists merely for convenience during development.
void main() => dream();

@pragma('vm:entry-point')
void settingsMain() async {
  await AppBinding.ensureInitialized();
  runApp(const LoadingScreen());
  await AuthBinding.instance.signInSilently();
  runApp(const SettingsApp());
}

@pragma('vm:entry-point')
void dream() async {
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
}

class LoadingScreen extends StatelessWidget {
  const LoadingScreen({super.key});

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
