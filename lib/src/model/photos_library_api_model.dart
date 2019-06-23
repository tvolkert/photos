import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:scoped_model/scoped_model.dart';

import '../photos_library_api/filters.dart';
import '../photos_library_api/media_item.dart';
import '../photos_library_api/media_type.dart';
import '../photos_library_api/media_type_filter.dart';
import '../photos_library_api/photos_library_api_client.dart';
import '../photos_library_api/search_media_items_request.dart';
import '../photos_library_api/search_media_items_response.dart';

import 'photo.dart';
import 'random.dart';

enum AuthState {
  pending,
  authenticated,
  unauthenticated,
}

class PhotosLibraryApiModel extends Model {
  AuthState _authState = AuthState.pending;
  PhotosLibraryApiClient _client;
  GoogleSignInAccount _currentUser;

  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: <String>[
    'https://www.googleapis.com/auth/photoslibrary.readonly',
  ]);

  Future<void> _onSignInComplete({bool fetchPhotos = true}) async {
    _currentUser = _googleSignIn.currentUser;
    AuthState newAuthState;
    if (_currentUser == null) {
      newAuthState = AuthState.unauthenticated;
      _client = null;
    } else {
      newAuthState = AuthState.authenticated;
      _client = PhotosLibraryApiClient(_currentUser.authHeaders);
    }
    if (fetchPhotos && newAuthState == AuthState.authenticated) {
      // TODO(tvolkert): don't delete, but don't blindly append
      await _fetchPhotos(delete: false);
    }
    if (_authState != newAuthState) {
      _authState = newAuthState;
      notifyListeners();
    }
  }

  Future<void> _fetchPhotos({bool delete = false}) async {
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
      SearchMediaItemsResponse response = await _request(nextPageToken);
      Iterable<String> ids = response.mediaItems?.map((MediaItem mediaItem) => mediaItem.id);
      if (ids != null) {
        await photosFile.writeAsString(ids.join('\n'), mode: FileMode.append, flush: true);
        await countFile.writeAsString('${count + response.mediaItems.length}', flush: true);
      }
      if (response.nextPageToken != null) {
        nextPageTokenFile.writeAsString(response.nextPageToken, flush: true);
        Timer(const Duration(seconds: 2), () {
          _fetchPhotos();
        });
      }
    } on PhotosApiException {
      Timer(const Duration(seconds: 2), () {
        _fetchPhotos();
      });
    }
  }

  AuthState get authState => _authState;

  Future<bool> signIn() async {
    if (_currentUser != null) {
      assert(authState == AuthState.authenticated);
      return true;
    }

    assert(authState != AuthState.authenticated);
    await _googleSignIn.signIn();
    await _onSignInComplete();
    return authState == AuthState.authenticated;
  }

  Future<void> signOut() async {
    await _googleSignIn.disconnect();
    _currentUser = null;
    _authState = AuthState.unauthenticated;
    _client = null;
  }

  Future<void> signInSilently({bool fetchPhotosAfterSignIn = true}) async {
    await _googleSignIn.signInSilently();
    await _onSignInComplete(fetchPhotos: fetchPhotosAfterSignIn);
  }

  Future<SearchMediaItemsResponse> _request([String nextPageToken]) async {
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

  Stream<Photo> get photos async* {
    try {
      Directory documentsDirectory = await getApplicationDocumentsDirectory();
      File photosFile = File(path.join(documentsDirectory.path, 'photos'));
      File countFile = File(path.join(documentsDirectory.path, 'count'));

      int i = -1;
      while (++i >= 0) {
        int skip;
        if (countFile.existsSync()) {
          int count = int.parse(await countFile.readAsString());
          skip = random.nextInt(count);
        }
        if (photosFile.existsSync()) {
          try {
            String id = await photosFile
                .openRead()
                .transform(utf8.decoder)
                .transform(const LineSplitter())
                .skip(skip ?? i)
                .first;
            MediaItem mediaItem;
            try {
              mediaItem = await _client.getMediaItem(id);
            } on GetMediaItemException catch (error) {
              if (error.statusCode == HttpStatus.unauthorized) {
                // Need to renew our OAuth access token.
                debugPrint('Renewing OAuth access token...');
                await signInSilently(fetchPhotosAfterSignIn: false);
                if (authState == AuthState.unauthenticated) {
                  // Unable to renew OAuth token.
                  debugPrint('Unable to renew OAuth access token; bailing out');
                  return;
                }
              } else {
                print('Error getting media item ${error.mediaItemId}');
                print(error.reasonPhrase);
                print(error.responseBody);
                continue;
              }
            }
            assert(mediaItem != null);

            Size screenSize = window.physicalSize;
            Size scaledSize = applyBoxFit(BoxFit.scaleDown, mediaItem.size, screenSize).destination;
            String url = '${mediaItem.baseUrl}=w${scaledSize.width.toInt()}-h${scaledSize.height.toInt()}';

            final HttpClient httpClient = HttpClient();
            final Uri resolved = Uri.base.resolve(url);
            final HttpClientRequest request = await httpClient.getUrl(resolved);
            final HttpClientResponse response = await request.close();
            if (response.statusCode != HttpStatus.ok) {
              debugPrint('HTTP request failed, statusCode: ${response.statusCode}, $resolved');
              // TODO(tvolkert): retry?
              continue;
            }

            yield Photo(
              mediaItem,
              scaledSize / window.devicePixelRatio,
              window.devicePixelRatio,
              await consolidateHttpClientResponseBytes(response),
            );
          } on StateError {
            // Our count seems to have gotten out of sync.
          }
        }
        await Future.delayed(const Duration(seconds: 4));
      }
    } catch (error, stackTrace) {
      // TODO(flutter/flutter#34545): remove this try/catch.
      debugPrint('$error\n$stackTrace');
    }
  }
}
