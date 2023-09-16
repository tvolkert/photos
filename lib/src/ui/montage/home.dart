import 'package:flutter/widgets.dart';

import 'package:photos/src/model/photo_producer.dart';
import 'package:photos/src/model/photos_api.dart';
import 'package:photos/src/ui/common/notifications.dart';

import 'app.dart';
import 'photos_page.dart';

class PhotosHome extends StatelessWidget {
  const PhotosHome({super.key});

  @override
  Widget build(BuildContext context) {
    switch (PhotosApp.of(context).state) {
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
