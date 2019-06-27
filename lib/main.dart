import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:scoped_model/scoped_model.dart';

import 'src/model/photo_cards.dart';
import 'src/model/photos_library_api_model.dart';
import 'src/pages/home_page.dart';

@pragma('vm:entry-point')
void main() => run(interactive: true);

@pragma('vm:entry-point')
void dream() => run(interactive: false);

void run({@required bool interactive}) {
  assert(interactive != null);
  final PhotosLibraryApiModel apiModel = PhotosLibraryApiModel();
  apiModel.signInSilently();
  runApp(
    ScopedModel<PhotosLibraryApiModel>(
      model: apiModel,
      child: MaterialApp(
        title: 'Photos Screensaver',
        home: HomePage(
          interactive: interactive,
          montageBuilder: () => PhotoMontage(),
        ),
      ),
    ),
  );

  // Limit the size of the image cache to ~the number of images that can be on-screen at a time.
  // TODO: lower this value
  imageCache.maximumSize = 100;
}
