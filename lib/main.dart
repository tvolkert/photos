import 'package:flutter/material.dart';
import 'package:photos/src/model/app.dart';
import 'package:scoped_model/scoped_model.dart';

import 'src/model/photos_library_api_model.dart';
import 'src/pages/home_page.dart';

@pragma('vm:entry-point')
void main() => run(interactive: true);

@pragma('vm:entry-point')
void dream() => run(interactive: false);

Future<void> run({required bool interactive}) async {
  await AppBinding.ensureInitialized();
  final PhotosLibraryApiModel apiModel = PhotosLibraryApiModel();
  apiModel.signInSilently();
  runApp(
    MaterialApp(
      title: 'Photos Screensaver',
      home: ScopedModel<PhotosLibraryApiModel>(
        model: apiModel,
        child: HomePage(
          interactive: interactive,
        ),
      ),
    ),
  );

  // Limit the size of the image cache to ~the number of images that can be on-screen at a time.
  // TODO: lower this value
  imageCache.maximumSize = 100;
}
