import 'package:flutter/widgets.dart';

import 'src/model/app.dart';
import 'src/model/auth.dart';
import 'src/model/photos_library_api_model.dart';
import 'src/pages/home_page.dart';
import 'src/pages/app.dart';
import 'src/pages/settings.dart';

@pragma('vm:entry-point')
void main() => settingsMain();

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
