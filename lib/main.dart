import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:photos/src/model/photos_library_api_model.dart';
import 'package:photos/src/pages/home_page.dart';
import 'package:scoped_model/scoped_model.dart';

@pragma('vm:entry-point')
void main() => run(allowSignIn: true);

@pragma('vm:entry-point')
void dream() => run(allowSignIn: false);

void run({@required bool allowSignIn}) {
  final apiModel = PhotosLibraryApiModel();
  apiModel.signInSilently();
  runApp(
    ScopedModel<PhotosLibraryApiModel>(
      model: apiModel,
      child: MaterialApp(
        title: 'Photos Screensaver',
        home: HomePage(allowSignIn: allowSignIn),
      ),
    ),
  );
  imageCache.maximumSize = 50;
}
