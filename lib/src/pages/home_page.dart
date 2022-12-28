import 'package:flutter/material.dart';
import 'package:scoped_model/scoped_model.dart';

import '../model/photos_library_api_model.dart';

import 'interactive_login_required_page.dart';
import 'login_page.dart';
import 'photos_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({
    Key? key,
    required this.interactive,
  }) : super(key: key);

  /// Whether the user is able to interact with the application.
  ///
  /// When the application is running as a screen-saver, any attempt by the
  /// user to interact with the application will wake up the OS and quit the
  /// application. In such cases, the application is said to be in a
  /// non-interactive state.
  final bool interactive;

  @override
  Widget build(BuildContext context) {
    return ScopedModelDescendant<PhotosLibraryApiModel>(
      builder: (BuildContext context, Widget? child, PhotosLibraryApiModel apiModel) {
        switch (apiModel.state) {
          case PhotosLibraryApiState.pendingAuthentication:
            // Show a blank screen while we try to non-interactively sign in.
            return Container();
          case PhotosLibraryApiState.unauthenticated:
            return interactive ? const LoginPage() : const InteractiveLoginRequiredPage();
          case PhotosLibraryApiState.authenticated:
            return const GooglePhotosMontageContainer();
          case PhotosLibraryApiState.rateLimited:
            return const AssetPhotosMontageContainer();
          default:
            throw StateError('Auth state not supported: ${apiModel.state}');
        }
      },
    );
  }
}
