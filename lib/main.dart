import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:photos/src/model/photos_library_api_model.dart';
import 'package:photos/src/pages/home_page.dart';
import 'package:scoped_model/scoped_model.dart';

@pragma('vm:entry-point')
void main() => run(interactive: true);

@pragma('vm:entry-point')
void dream() => run(interactive: false);

void run({@required bool interactive}) {
  assert(interactive != null);
  final apiModel = PhotosLibraryApiModel();
  apiModel.signInSilently();
  runApp(
    ScopedModel<PhotosLibraryApiModel>(
      model: apiModel,
      child: MaterialApp(
        title: 'Photos Screensaver',
        home: HomePage(interactive: interactive),
      ),
    ),
  );


  // Limit the size of the image cache to ~the number of images that can be on-screen at a time.
  imageCache.maximumSize = 50;
}
