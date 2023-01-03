import 'dart:async';
import 'dart:io' show FileMode, HttpStatus;
import 'dart:math' as math;

import 'package:file/file.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:scoped_model/scoped_model.dart';

import '../photos_library_api/batch_get_request.dart';
import '../photos_library_api/batch_get_response.dart';
import '../photos_library_api/exceptions.dart';
import '../photos_library_api/list_media_items_request.dart';
import '../photos_library_api/list_media_items_response.dart';
import '../photos_library_api/media_item.dart';
import '../photos_library_api/media_item_result.dart';
import '../photos_library_api/photos_library_api_client.dart';
import '../photos_library_api/status.dart';

import 'codecs.dart';
import 'files.dart';
import 'random.dart' as random_binding;
import 'random_picking_strategy.dart';

const Duration _kBackOffDuration = Duration(minutes: 1);
const Duration maxStaleness = Duration(days: 7);

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

/// ## The database files
///
/// This class manages two database files, [FilesBinding.photosFile] for photos
/// and [FilesBinding.videosFile] for videos. Each file contains a list of
/// Google Photos media item ids representing the entire set of photos (or
/// videos) in the user's library. These files are created asynchronously when
/// the user first signs in and then automatically updated for freshness (see
/// [maxStaleness]) after that.
///
/// Each entry in a database file is a utf8-encoded [MediaItem.id], which is
/// then right-padded with [paddingByte] until the byte sequence reaches a
/// length of [blockSize].
class PhotosLibraryApiModel extends Model {
  PhotosLibraryApiState _state = PhotosLibraryApiState.pendingAuthentication;
  PhotosLibraryApiClient? _client;
  GoogleSignInAccount? _currentUser;

  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: <String>[
    'https://www.googleapis.com/auth/photoslibrary.readonly',
  ]);

  /// Callback that runs once a sign-in attempt has completed, either
  /// explicitly or silently.
  ///
  /// A completed sign-in attempt does _not_ mean that the user is
  /// authenticated; the attempt might have been completed unsuccessfully or
  /// been aborted.
  ///
  /// This method sets the API [state] and refreshes the database files if
  /// needed (and if the user is authenticated).
  ///
  /// See also:
  ///
  ///  * [populateDatabase], which updates the database files.
  Future<void> _handleSignInComplete() async {
    _currentUser = _googleSignIn.currentUser;
    PhotosLibraryApiState newState;
    if (_currentUser == null) {
      newState = PhotosLibraryApiState.unauthenticated;
      _client = null;
    } else {
      newState = PhotosLibraryApiState.authenticated;
      _client = PhotosLibraryApiClient(_currentUser!.authHeaders);
      if (!_areDatabaseFilesUpToDate) {
        _refreshDatabaseFiles();
      }
    }
    state = newState;
  }

  /// Tells whether or not the database files are sufficiently up to date or
  /// whether they need refreshing.
  bool get _areDatabaseFilesUpToDate {
    final FilesBinding files = FilesBinding.instance;
    bool upToDate = files.photosFile.existsSync();
    if (upToDate) {
      final FileStat stat = files.photosFile.statSync();
      final Duration sinceLastModified = DateTime.now().difference(stat.modified);
      upToDate = sinceLastModified < maxStaleness;
    }
    return upToDate;
  }

  /// Refresh the database files.
  void _refreshDatabaseFiles() {
    populateDatabase().catchError((dynamic error, StackTrace stackTrace) {
      debugPrint('$error\n$stackTrace');
    });
  }

  Iterable<String> _extractPhotos(Iterable<MediaItem> mediaItems) {
    return mediaItems
        .where((MediaItem item) => item.mediaMetadata.photo != null)
        .map<String>((MediaItem item) => item.id);
  }

  Iterable<String> _extractVideos(Iterable<MediaItem> mediaItems) {
    return mediaItems
        .where((MediaItem item) => item.mediaMetadata.video != null)
        .map<String>((MediaItem item) => item.id);
  }

  Future<void> _appendPhotosToFile(File file, Iterable<MediaItem> mediaItems) async {
    const DatabaseFileCodec codec = DatabaseFileCodec();
    final List<int> bytes = codec.encodeMediaItemIds(_extractPhotos(mediaItems));
    if (bytes.isNotEmpty) {
      await file.writeAsBytes(bytes, mode: FileMode.append, flush: true);
    }
  }

  Future<void> _appendVideosToFile(File file, Iterable<MediaItem> mediaItems) async {
    const DatabaseFileCodec codec = DatabaseFileCodec();
    final List<int> bytes = codec.encodeMediaItemIds(_extractVideos(mediaItems));
    if (bytes.isNotEmpty) {
      await file.writeAsBytes(bytes, mode: FileMode.append, flush: true);
    }
  }

  /// Populates [FilesBinding.photosFile] and [FilesBinding.videosFile] with
  /// the complete list of photos & videos that the sign-in user has in their
  /// Google Photos library.
  ///
  /// Once this method is complete, batches of photo/video details will be able
  /// to be loaded in random order from Google Photos. When this app is first
  /// run, this method will not have completed yet (it'll be running in the
  /// background), and the app will display asset photos instead of photos
  /// loaded from Google Photos.
  ///
  /// This method is called automatically whenever it is detected that this
  /// data is older than [maxStaleness].
  Future<void> populateDatabase() async {
    debugPrint('Reloading photo cache...');
    final FilesBinding files = FilesBinding.instance;
    final File tmpPhotoFile = files.photosFile.parent.childFile('${files.photosFile.basename}.tmp');
    final File tmpVideoFile = files.videosFile.parent.childFile('${files.videosFile.basename}.tmp');
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
        } on http.ClientException catch (error) {
          debugPrint('Error trying to list media items: $error');
          debugPrint('Retrying in 10 seconds');
          await Future.delayed(const Duration(seconds: 10));
          continue;
        }
        await Future.delayed(const Duration(milliseconds: 1));
      }
      debugPrint('Done loading $count items.');
      await tmpPhotoFile.rename(files.photosFile.path);
      await tmpVideoFile.rename(files.videosFile.path);
    } catch (error, stackTrace) {
      debugPrint('$error\n$stackTrace');
    } finally {
      if (tmpPhotoFile.existsSync()) {
        await tmpPhotoFile.delete(recursive: true);
      }
      if (tmpVideoFile.existsSync()) {
        await tmpVideoFile.delete(recursive: true);
      }
    }
  }

  /// Picks [batchSize] media item ids at random from the photo database.
  ///
  /// This may only be called if the photos database file has already been
  /// created.
  Future<List<String>> pickRandomMediaItems(int batchSize, {math.Random? random}) async {
    random ??= random_binding.random;
    const DatabaseFileCodec codec = DatabaseFileCodec();
    final FilesBinding files = FilesBinding.instance;
    assert(files.photosFile.existsSync());
    final int count = files.photosFile.statSync().size ~/ DatabaseFileCodec.blockSize;
    final RandomPickingStrategy strategy = RandomPickingStrategy(max: count, random: random);
    final List<String> mediaItemIds = <String>[];
    final RandomAccessFile handle = await files.photosFile.open();
    try {
      for (int index in strategy.pickN(batchSize)) {
        final int offset = index * DatabaseFileCodec.blockSize;
        handle.setPositionSync(offset);
        final Uint8List byteBlock = await handle.read(DatabaseFileCodec.blockSize);
        final String mediaItemId = codec.decodeMediaItemId(byteBlock);
        mediaItemIds.add(mediaItemId);
      }
    } finally {
      handle.closeSync();
    }
    assert(mediaItemIds.length == batchSize);
    return mediaItemIds;
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
    await _handleSignInComplete();
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
    await _handleSignInComplete();
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
