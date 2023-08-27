import 'package:flutter/foundation.dart';

import 'package:google_sign_in/google_sign_in.dart';
import 'package:photos/src/model/files.dart';

import 'app.dart';

typedef OnAuthenticationActionCallback = Future<void> Function(GoogleSignInAccount? previousUser);
typedef OnAuthTokensRenewedCallback = Future<void> Function();

mixin AuthBinding on AppBindingBase {
  /// The singleton instance of this object.
  static late AuthBinding _instance;
  static AuthBinding get instance => _instance;

  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: <String>[
    'email',
    'https://www.googleapis.com/auth/photoslibrary.readonly',
  ]);

  GoogleSignInAccount? _currentUser;
  Future<void> _setCurrentUser(GoogleSignInAccount? user) async {
    GoogleSignInAccount? previousUser = _currentUser;
    _currentUser = user;
    if (_onAuthenticationAction != null) {
      await _onAuthenticationAction!(previousUser);
    }
  }

  /// Callback that runs when the current user has changed, either by sign-in
  /// or sign-out.
  OnAuthenticationActionCallback? _onAuthenticationAction;
  OnAuthenticationActionCallback? get onAuthenticationAction => _onAuthenticationAction;
  set onAuthenticationAction(OnAuthenticationActionCallback? callback) {
    _onAuthenticationAction = callback;
  }

  /// Callback that runs when the current user renews their auth tokens.
  OnAuthTokensRenewedCallback? _onAuthTokensRenewed;
  OnAuthTokensRenewedCallback? get onAuthTokensRenewed => _onAuthTokensRenewed;
  set onAuthTokensRenewed(OnAuthTokensRenewedCallback? callback) {
    _onAuthTokensRenewed = callback;
  }

  @override
  @protected
  @mustCallSuper
  Future<void> initInstances() async {
    await super.initInstances();
    _instance = this;
  }

  bool get isSignedIn => _currentUser != null;

  GoogleSignInAccount get user {
    if (!isSignedIn) {
      throw StateError('No current user');
    }
    return _currentUser!;
  }

  GoogleSignInAccount? get maybeUser => _currentUser;

  Future<void> signIn() async {
    if (!isSignedIn) {
      await _googleSignIn.signIn();
      await _setCurrentUser(_googleSignIn.currentUser);
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.disconnect();
    await _setCurrentUser(null);
    if (FilesBinding.instance.photosFile.existsSync()) {
      FilesBinding.instance.photosFile.deleteSync(recursive: true);
    }
    if (FilesBinding.instance.videosFile.existsSync()) {
      FilesBinding.instance.videosFile.deleteSync(recursive: true);
    }
  }

  Future<void> signInSilently() async {
    await _googleSignIn.signInSilently();
    await _setCurrentUser(_googleSignIn.currentUser);
  }

  Future<void> renewExpiredAuthToken() async {
    if (!isSignedIn) {
      throw StateError('No current user');
    }
    // This will force the retrieval of new OAuth tokens.
    await _googleSignIn.currentUser?.authentication;
    if (_onAuthTokensRenewed != null) {
      await _onAuthTokensRenewed!();
    }
  }
}
