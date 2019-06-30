import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:scoped_model/scoped_model.dart';

import '../photos_library_api/exceptions.dart';
import '../photos_library_api/filters.dart';
import '../photos_library_api/media_item.dart';
import '../photos_library_api/media_type.dart';
import '../photos_library_api/media_type_filter.dart';
import '../photos_library_api/photos_library_api_client.dart';
import '../photos_library_api/search_media_items_request.dart';
import '../photos_library_api/search_media_items_response.dart';

enum PhotosLibraryApiState {
  /// The user has not yet attempted authentication or is in the process of
  /// authenticating.
  pendingAuthentication,

  /// The user has authenticated and is in possession of a valid OAuth 2.0
  /// access token.
  authenticated,

  /// The user has attempted authentication and failed, or their OAuth access
  /// token has expired and in need of renewal.
  unauthenticated,

  /// The user has successfully authenticated, but they are being rate limited
  /// by the Google Photos API and are temporarily not allowed to make further
  /// API requests.
  rateLimited,
}

class PhotosLibraryApiModel extends Model {
  PhotosLibraryApiState _state = PhotosLibraryApiState.pendingAuthentication;
  PhotosLibraryApiClient _client;
  GoogleSignInAccount _currentUser;

  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: <String>[
    'https://www.googleapis.com/auth/photoslibrary.readonly',
  ]);

  Future<void> _onSignInComplete({bool fetchPhotos = true}) async {
    _currentUser = _googleSignIn.currentUser;
    PhotosLibraryApiState newState;
    if (_currentUser == null) {
      newState = PhotosLibraryApiState.unauthenticated;
      _client = null;
    } else {
      newState = PhotosLibraryApiState.authenticated;
      _client = PhotosLibraryApiClient(_currentUser.authHeaders);
    }
    if (fetchPhotos && newState == PhotosLibraryApiState.authenticated) {
      // TODO(tvolkert): don't delete, but don't blindly append
      await _populatePhotosFile(delete: false);
    }
    state = newState;
  }

  Future<void> _populatePhotosFile({bool delete = false}) async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    File nextPageTokenFile = File(path.join(documentsDirectory.path, 'nextPageToken'));
    File photosFile = File(path.join(documentsDirectory.path, 'photos'));
    File countFile = File(path.join(documentsDirectory.path, 'count'));
    if (delete) {
      if (nextPageTokenFile.existsSync()) nextPageTokenFile.deleteSync();
      if (photosFile.existsSync()) photosFile.deleteSync();
      if (countFile.existsSync()) countFile.deleteSync();
    }
    String nextPageToken;
    if (nextPageTokenFile.existsSync()) {
      nextPageToken = await nextPageTokenFile.readAsString();
    }
    int count = 0;
    if (countFile.existsSync()) {
      count = int.parse(await countFile.readAsString());
    }
    try {
      SearchMediaItemsResponse response = await _searchMediaItems(nextPageToken);
      Iterable<String> ids = response.mediaItems?.map((MediaItem mediaItem) => mediaItem.id);
      if (ids != null) {
        await photosFile.writeAsString(ids.join('\n'), mode: FileMode.append, flush: true);
        await countFile.writeAsString('${count + response.mediaItems.length}', flush: true);
      }
      if (response.nextPageToken != null) {
        nextPageTokenFile.writeAsString(response.nextPageToken, flush: true);
        Timer(const Duration(seconds: 2), () {
          _populatePhotosFile();
        });
      }
    } on PhotosApiException {
      Timer(const Duration(seconds: 2), () {
        _populatePhotosFile();
      });
    }
  }

  PhotosLibraryApiState get state => _state;
  set state(PhotosLibraryApiState value) {
    assert(value != null);
    if (_state != value) {
      _state = value;
      notifyListeners();
    }
  }

  Future<bool> signIn() async {
    if (_currentUser != null) {
      assert(state == PhotosLibraryApiState.authenticated);
      return true;
    }

    assert(state != PhotosLibraryApiState.authenticated);
    await _googleSignIn.signIn();
    await _onSignInComplete();
    return state == PhotosLibraryApiState.authenticated;
  }

  Future<void> signOut() async {
    await _googleSignIn.disconnect();
    _currentUser = null;
    _client = null;
    state = PhotosLibraryApiState.unauthenticated;
  }

  Future<void> signInSilently({bool fetchPhotosAfterSignIn = true}) async {
    await _googleSignIn.signInSilently();
    await _onSignInComplete(fetchPhotos: fetchPhotosAfterSignIn);
  }

  Future<SearchMediaItemsResponse> _searchMediaItems([String nextPageToken]) async {
    final SearchMediaItemsRequest request = SearchMediaItemsRequest(
      pageSize: 100,
      pageToken: nextPageToken,
      filters: Filters(
        mediaTypeFilter: MediaTypeFilter(
          mediaTypes: <MediaType>[MediaType.photo],
        ),
      ),
    );
    return await _client.searchMediaItems(request);
  }

  Future<MediaItem> getMediaItem(String id) async {
    MediaItem result;
    while (result == null) {
      try {
        result = await _client.getMediaItem(id);
      } on GetMediaItemException catch (error) {
        switch (error.statusCode) {
          case HttpStatus.unauthorized:
            debugPrint('Renewing OAuth access token...');
            await signInSilently(fetchPhotosAfterSignIn: false);
            if (state == PhotosLibraryApiState.unauthenticated) {
              debugPrint('Unable to renew OAuth access token; bailing out');
              return null;
            }
            break;
          case HttpStatus.tooManyRequests:
            state = PhotosLibraryApiState.rateLimited;
            return null;
            break;
          default:
            rethrow;
        }
      }
    }
    return result;
  }
}
