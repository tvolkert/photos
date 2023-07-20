import 'package:flutter/foundation.dart';

import 'package:google_sign_in/google_sign_in.dart';

import 'app.dart';

typedef PostSignInCallback = Future<void> Function();

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
    if (user != previousUser && _onUserChanged != null) {
      await _onUserChanged!();
    }
  }

  /// Callback that runs when the current user has changed, either by sign-in
  /// or sign-out.
  PostSignInCallback? _onUserChanged;
  PostSignInCallback? get onUserChanged => _onUserChanged;
  set onUserChanged(PostSignInCallback? callback) {
    _onUserChanged = callback;
  }

  /// Callback that runs when the current user renews their auth tokens.
  PostSignInCallback? _onAuthTokensRenewed;
  PostSignInCallback? get onAuthTokensRenewed => _onAuthTokensRenewed;
  set onAuthTokensRenewed(PostSignInCallback? callback) {
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
  }

  Future<void> signInSilently() async {
    await _googleSignIn.signInSilently();
    await _setCurrentUser(_googleSignIn.currentUser);
  }

  Future<void> renewExpiredAuthToken() async {
    assert(_googleSignIn.currentUser != null);
    // This will force the retrieval of new OAuth tokens.
    await _googleSignIn.currentUser?.authentication;
    if (_onAuthTokensRenewed != null) {
      await _onAuthTokensRenewed!();
    }
  }
}
