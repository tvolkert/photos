import 'package:flutter/widgets.dart';

import '../model/photos_library_api_model.dart';

import 'app.dart';
import 'login_page.dart';
import 'photos_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    switch (PhotosApp.of(context).apiModel.state) {
      case PhotosLibraryApiState.pendingAuthentication:
        // Show a blank screen while we try to non-interactively sign in.
        return Container();
      case PhotosLibraryApiState.unauthenticated:
        return const LoginPage();
      case PhotosLibraryApiState.authenticated:
      case PhotosLibraryApiState.authenticationExpired:
        return const GooglePhotosMontageContainer();
      case PhotosLibraryApiState.rateLimited:
        return const AssetPhotosMontageContainer();
    }
  }
}
