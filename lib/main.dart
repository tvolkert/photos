import 'package:flutter/widgets.dart';

import 'package:scoped_model/scoped_model.dart';

import 'src/model/app.dart';
import 'src/model/photos_library_api_model.dart';
import 'src/pages/home_page.dart';
import 'src/pages/app.dart';

@pragma('vm:entry-point')
void main() => run(interactive: true);

@pragma('vm:entry-point')
void dream() => run(interactive: false);

Future<void> run({required bool interactive}) async {
  await AppBinding.ensureInitialized();
  final PhotosLibraryApiModel apiModel = PhotosLibraryApiModel();
  apiModel.signInSilently();
  runApp(
    PhotosApp(
      interactive: interactive,
      child: ScopedModel<PhotosLibraryApiModel>(
        model: apiModel,
        child: const HomePage(),
      ),
    ),
  );
}
