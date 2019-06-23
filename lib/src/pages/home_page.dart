import 'package:flutter/material.dart';
import 'package:scoped_model/scoped_model.dart';
import 'package:photos/src/model/photos_library_api_model.dart';
import 'package:photos/src/pages/login_page.dart';

import 'photos_page.dart';

class HomePage extends StatelessWidget {
  HomePage({
    Key key,
    @required this.allowSignIn,
  }) : assert(allowSignIn != null);

  final bool allowSignIn;

  @override
  Widget build(BuildContext context) {
    return ScopedModelDescendant<PhotosLibraryApiModel>(
      builder: (BuildContext context, Widget child, PhotosLibraryApiModel apiModel) {
        switch (apiModel.authState) {
          case AuthState.pending:
            // Black screen while we try to log in.
            return Container();
          case AuthState.unauthenticated:
            return allowSignIn ? LoginPage() : PhotosPage();
          case AuthState.authenticated:
            return PhotosPage();
          default:
            throw StateError('Auth state not supported: ${apiModel.authState}');
        }
      },
    );
  }
}
