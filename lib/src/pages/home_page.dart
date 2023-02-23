import 'package:flutter/widgets.dart';

import 'package:scoped_model/scoped_model.dart';

import '../model/photos_library_api_model.dart';

import 'login_page.dart';
import 'photos_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return ScopedModelDescendant<PhotosLibraryApiModel>(
      builder: (BuildContext context, Widget? child, PhotosLibraryApiModel apiModel) {
        switch (apiModel.state) {
          case PhotosLibraryApiState.pendingAuthentication:
            // Show a blank screen while we try to non-interactively sign in.
            return Container();
          case PhotosLibraryApiState.unauthenticated:
            return const LoginPage();
          case PhotosLibraryApiState.authenticated:
            return const GooglePhotosMontageContainer();
          case PhotosLibraryApiState.rateLimited:
            return const AssetPhotosMontageContainer();
        }
      },
    );
  }
}
