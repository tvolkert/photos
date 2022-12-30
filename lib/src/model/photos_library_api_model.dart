import 'dart:async';
import 'dart:convert';
import 'dart:io' show FileMode, HttpStatus;
import 'dart:math' show Random;

import 'package:file/file.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
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

  /// The amount of space, in bytes, reserved for each photo entry in the
  /// database files.
  ///
  /// Entries that take up less than this space will have a sequence of
  /// [paddingByte] bytes appended to them until they reach this block size.
  ///
  /// Having this be a fixed size (rather than delineating entries with a
  /// newline, for instance) allows us to randomly jump to any entry in a
  /// database.
  static const blockSize = 1024;

  /// The value that will be appended to the end of each database entry until
  /// the entry size reaches [blockSize].
  ///
  /// See also:
  ///
  ///  * [paddingStart], which marks the beginning of the padding sequence so
  ///    that we can identify the padding bytes from the actual utf8 bytes.
  static const paddingByte = 0;

  /// A sequence of bytes that starts the padding sequence in a database entry.
  ///
  /// This allows us to identify the padding bytes from the actual utf8 bytes.
  static const List<int> paddingStart = <int>[0, 0, 0, 0];

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

  List<int> _padRight(List<int> bytes) {
    assert(bytes.length <= blockSize);
    return List<int>.generate(blockSize, (int index) {
      if (index < bytes.length) {
        return bytes[index];
      } else if (index - bytes.length < paddingStart.length) {
        return paddingStart[index - bytes.length];
      } else {
        return paddingByte;
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
  Future<List<String>> pickRandomMediaItems(int batchSize, {Random? random}) async {
    random ??= random_binding.random;
    final FilesBinding files = FilesBinding.instance;
    assert(files.photosFile.existsSync());
    final int count = files.photosFile.statSync().size ~/ blockSize;
    final RandomPickingStrategy strategy = RandomPickingStrategy(max: count, random: random);
    final List<String> mediaItemIds = <String>[];
    final RandomAccessFile handle = await files.photosFile.open();
    try {
      for (int index in strategy.pickN(batchSize)) {
        final int offset = index * blockSize;
        handle.setPositionSync(offset);
        final List<int> bytes = _unpadBytes(await handle.read(blockSize));
        final String mediaItemId = utf8.decode(bytes);
        mediaItemIds.add(mediaItemId);
      }
    } finally {
      handle.closeSync();
    }
    assert(mediaItemIds.length == batchSize);
    return mediaItemIds;
  }

  List<int> _unpadBytes(Uint8List bytes) {
    final int? paddingStart = _getPaddingStart(bytes);
    return paddingStart == null ? bytes : bytes.sublist(0, paddingStart);
  }

  int? _getPaddingStart(Uint8List bytes) {
    bool matchAt(int index) {
      assert(index >= 0);
      assert(index + paddingStart.length <= bytes.length);
      for (int i = 0; i < paddingStart.length; i++) {
        if (bytes[index + i] != paddingStart[i]) {
          return false;
        }
      }
      return true;
    }

    for (int j = 0; j <= bytes.length - paddingStart.length; j++) {
      if (matchAt(j)) {
        return j;
      }
    }
    return null;
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
