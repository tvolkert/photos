import 'package:flutter/widgets.dart';

import '../model/photo_producer.dart';
import '../model/photos_library_api_model.dart';

import 'app.dart';
import 'notifications.dart';
import 'photos_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final PhotosLibraryApiState state = PhotosApp.of(context).apiModel.state;
    switch (state) {
      case PhotosLibraryApiState.pendingAuthentication:
        // Show a blank screen while we try to non-interactively sign in.
        return Container();
      case PhotosLibraryApiState.unauthenticated:
        return const MontageScaffold(
          producer: AssetPhotoProducer(),
          bottomBarNotification: NeedToLoginNotification(),
        );
      case PhotosLibraryApiState.authenticated:
      case PhotosLibraryApiState.authenticationExpired:
        return const GooglePhotosMontageContainer();
      case PhotosLibraryApiState.rateLimited:
        return const AssetPhotosMontageContainer();
    }
  }
}
