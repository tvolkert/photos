import 'dart:async';
import 'dart:convert';
import 'dart:io' show FileMode, HttpStatus;

import 'package:file/file.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:scoped_model/scoped_model.dart';

import 'files.dart';
import '../photos_library_api/batch_get_request.dart';
import '../photos_library_api/batch_get_response.dart';
import '../photos_library_api/exceptions.dart';
import '../photos_library_api/list_media_items_request.dart';
import '../photos_library_api/list_media_items_response.dart';
import '../photos_library_api/media_item.dart';
import '../photos_library_api/media_item_result.dart';
import '../photos_library_api/photos_library_api_client.dart';
import '../photos_library_api/status.dart';

const Duration _kBackOffDuration = Duration(minutes: 1);

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
  PhotosLibraryApiClient? _client;
  GoogleSignInAccount? _currentUser;

  static const kBlockSize = 1024;
  static const kPaddingByte = 0;
  static const List<int> kPaddingStart = <int>[0, 0, 0, 0];

  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: <String>[
    'https://www.googleapis.com/auth/photoslibrary.readonly',
  ]);

  Future<void> _onSignInComplete() async {
    _currentUser = _googleSignIn.currentUser;
    PhotosLibraryApiState newState;
    if (_currentUser == null) {
      newState = PhotosLibraryApiState.unauthenticated;
      _client = null;
    } else {
      newState = PhotosLibraryApiState.authenticated;
      _client = PhotosLibraryApiClient(_currentUser!.authHeaders);

      final FilesBinding files = FilesBinding.instance;
      bool upToDate = files.photosFile.existsSync();
      if (upToDate) {
        final FileStat stat = files.photosFile.statSync();
        final Duration sinceLastModified = DateTime.now().difference(stat.modified);
        upToDate = sinceLastModified < const Duration(days: 7);
      }
      if (!upToDate) {
        _load().catchError((dynamic error, StackTrace stackTrace) {
          print('$error\n$stackTrace');
        });
      }
    }
    state = newState;
  }

  List<int> _padRight(List<int> bytes) {
    assert(bytes.length <= kBlockSize);
    return List<int>.generate(kBlockSize, (int index) {
      if (index < bytes.length) {
        return bytes[index];
      } else if (index - bytes.length < kPaddingStart.length) {
        return kPaddingStart[index - bytes.length];
      } else {
        return kPaddingByte;
      }
    });
  }

  List<int> _serializeIds(Iterable<MediaItem> mediaItems) {
    return mediaItems
        .map((MediaItem item) => item.id)
        .map<List<int>>((String id) => utf8.encode(id))
        .map<List<int>>(_padRight)
        .expand((List<int> bytes) => bytes)
        .toList();
  }

  Iterable<MediaItem> _extractPhotos(Iterable<MediaItem> mediaItems) {
    return mediaItems.where((MediaItem item) => item.mediaMetadata.photo != null);
  }

  Iterable<MediaItem> _extractVideos(Iterable<MediaItem> mediaItems) {
    return mediaItems.where((MediaItem item) => item.mediaMetadata.video != null);
  }

  Future<void> _appendPhotosToFile(File file, Iterable<MediaItem> mediaItems) async {
    final List<int> bytes = _serializeIds(_extractPhotos(mediaItems));
    if (bytes.isNotEmpty) {
      await file.writeAsBytes(bytes, mode: FileMode.append, flush: true);
    }
  }

  Future<void> _appendVideosToFile(File file, Iterable<MediaItem> mediaItems) async {
    final List<int> bytes = _serializeIds(_extractVideos(mediaItems));
    if (bytes.isNotEmpty) {
      await file.writeAsBytes(bytes, mode: FileMode.append, flush: true);
    }
  }

  Future<void> _load() async {
    debugPrint('Reloading photo cache...');
    final FilesBinding files = FilesBinding.instance;
    final File tmpPhotoFile = files.photosFile.parent.childFile(files.photosFile.basename + ".tmp");
    final File tmpVideoFile = files.videosFile.parent.childFile(files.videosFile.basename + ".tmp");
    if (tmpPhotoFile.existsSync()) {
      await tmpPhotoFile.delete(recursive: true);
    }
    if (tmpVideoFile.existsSync()) {
      await tmpVideoFile.delete(recursive: true);
    }
    assert(!tmpPhotoFile.existsSync());
    assert(!tmpVideoFile.existsSync());
    try {
      String? nextPageToken;
      int count = 0;
      while (count == 0 || nextPageToken != null) {
        debugPrint('Loaded $count items...');
        try {
          final ListMediaItemsResponse response = await _listMediaItems(nextPageToken);
          if (response.mediaItems.isEmpty && count == 0) {
            // Special case of an empty photo library.
            await tmpPhotoFile.create();
            await tmpVideoFile.create();
            break;
          }
          await _appendPhotosToFile(tmpPhotoFile, response.mediaItems);
          await _appendVideosToFile(tmpVideoFile, response.mediaItems);
          count += response.mediaItems.length;
          nextPageToken = response.nextPageToken;
        } on PhotosApiException catch (error) {
          if (error.statusCode == HttpStatus.tooManyRequests) {
            await Future.delayed(const Duration(minutes: 1));
            continue;
          } else {
            rethrow;
          }
        }
        await Future.delayed(const Duration(milliseconds: 1));
      }
      debugPrint('Done loading $count items.');
      await tmpPhotoFile.rename(files.photosFile.path);
      await tmpVideoFile.rename(files.videosFile.path);
    } catch (error, stackTrace) {
      print('$error\n$stackTrace');
    } finally {
      if (tmpPhotoFile.existsSync()) {
        await tmpPhotoFile.delete(recursive: true);
      }
      if (tmpVideoFile.existsSync()) {
        await tmpVideoFile.delete(recursive: true);
      }
    }
  }

  PhotosLibraryApiState get state => _state;
  set state(PhotosLibraryApiState value) {
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

  Future<void> signInSilently() async {
    await _googleSignIn.signInSilently();
    await _onSignInComplete();
  }

  Future<ListMediaItemsResponse> _listMediaItems([String? nextPageToken]) async {
    final ListMediaItemsRequest request = ListMediaItemsRequest(
      pageSize: 100,
      pageToken: nextPageToken,
    );
    return await _client!.listMediaItems(request);
  }

  Future<MediaItem?> getMediaItem(String id) async {
    MediaItem? result;
    while (result == null) {
      try {
        result = await _client!.getMediaItem(id);
      } on GetMediaItemException catch (error) {
        switch (error.statusCode) {
          case HttpStatus.unauthorized:
            debugPrint('Renewing OAuth access token...');
            await signInSilently();
            if (state == PhotosLibraryApiState.unauthenticated) {
              // TODO: retry
              debugPrint('Unable to renew OAuth access token; bailing out');
              return null;
            }
            break;
          case HttpStatus.tooManyRequests:
            final PhotosLibraryApiState previousState = state;
            state = PhotosLibraryApiState.rateLimited;
            await Future.delayed(_kBackOffDuration);
            state = previousState;
            break;
          default:
            rethrow;
        }
      }
    }
    return result;
  }

  Future<List<MediaItem>> getMediaItems(List<String> mediaItemIds) async {
    List<MediaItem>? results;
    while (results == null) {
      try {
        final BatchGetRequest request = BatchGetRequest(mediaItemIds: mediaItemIds);
        final BatchGetResponse response = await _client!.batchGet(request);
        results = response.mediaItemResults
            .where((MediaItemResult result) => result.mediaItem != null)
            .map<MediaItem>((MediaItemResult result) => result.mediaItem!)
            .toList();
        assert(() {
          final List<Status> failures = response.mediaItemResults
              .where((MediaItemResult result) => result.status != null)
              .map<Status>((MediaItemResult result) => result.status!)
              .toList();
          if (failures.isNotEmpty) {
            final StringBuffer failureDetails = StringBuffer();
            for (Status failure in failures) {
              failureDetails.write('Error ${failure.code}: ${failure.message}');
              if (failure.details != null) {
                failureDetails.write(': ${failure.details}');
              }
              failureDetails.writeln();
            }
            debugPrint("Unable to fetch the following media items:\n$failureDetails");
          }
          return true;
        }());
      } on PhotosApiException catch (error) {
        switch (error.statusCode) {
          case HttpStatus.unauthorized:
            debugPrint('Renewing OAuth access token...');
            await signInSilently();
            if (state == PhotosLibraryApiState.unauthenticated) {
              // TODO: retry
              debugPrint('Unable to renew OAuth access token; bailing out');
              return <MediaItem>[];
            }
            break;
          case HttpStatus.tooManyRequests:
            final PhotosLibraryApiState previousState = state;
            state = PhotosLibraryApiState.rateLimited;
            await Future.delayed(_kBackOffDuration);
            state = previousState;
            break;
          default:
            debugPrint('${error.statusCode} ${error.reasonPhrase} : ${error.responseBody}');
            debugPrint('Request was ${error.requestUrl}');
            debugPrint('${StackTrace.current}');
            return <MediaItem>[];
        }
      }
    }
    return results;
  }
}
