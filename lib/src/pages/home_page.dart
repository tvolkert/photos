import 'package:flutter/material.dart';
import 'package:scoped_model/scoped_model.dart';

import '../model/photo_card_producer.dart';
import '../model/photo_cards.dart';
import '../model/photos_library_api_model.dart';

import 'interactive_login_required_page.dart';
import 'login_page.dart';
import 'photos_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({
    Key? key,
    required this.interactive,
    required this.montageBuilder,
    required this.producerBuilder,
  }) : super(key: key);

  /// Whether the user is able to interact with the application.
  ///
  /// When the application is running as a screen-saver, any attempt by the
  /// user to interact with the application will wake up the OS and quit the
  /// application. In such cases, the application is said to be in a
  /// non-interactive state.
  final bool interactive;

  final PhotoMontageBuilder montageBuilder;

  final PhotoCardProducerBuilder producerBuilder;

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
            return PhotosHome(
              montageBuilder: montageBuilder,
              producerBuilder: producerBuilder,
            );
          case PhotosLibraryApiState.rateLimited:
            return PhotosHome(
              montageBuilder: montageBuilder,
              producerBuilder: (PhotosLibraryApiModel model, PhotoMontage montage) {
                return PhotoCardProducer.asset(montage);
              },
            );
          default:
            throw StateError('Auth state not supported: ${apiModel.state}');
        }
      },
    );
  }
}
