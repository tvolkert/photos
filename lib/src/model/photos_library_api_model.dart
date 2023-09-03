import 'dart:async';
import 'dart:io' show FileMode, HttpStatus;
import 'dart:math' as math;

import 'package:file/file.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;

import '../model/auth.dart';
import '../model/ui.dart';
import '../pages/app.dart';
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

  /// The user was previously authenticated, but their authentication token has
  /// expired and needs renewal.
  authenticationExpired,

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
class PhotosLibraryApiModel extends ChangeNotifier {
  PhotosLibraryApiState _state = PhotosLibraryApiState.pendingAuthentication;
  PhotosLibraryApiClient? _client;

  PhotosLibraryApiModel() {
    AuthBinding.instance.onAuthenticationAction = _handleAuthenticationAction;
    AuthBinding.instance.onAuthTokensRenewed = _handleAuthTokensRenewed;
  }

  /// Callback that runs when the current user changes.
  ///
  /// This method sets the API [state] and refreshes the database files if
  /// needed (and if the user is authenticated).
  ///
  /// See also:
  ///
  ///  * [populateDatabase], which updates the database files.
  Future<void> _handleAuthenticationAction(GoogleSignInAccount? previousUser) async {
    final AuthBinding auth = AuthBinding.instance;
    PhotosLibraryApiState newState;
    if (!auth.isSignedIn) {
      newState = PhotosLibraryApiState.unauthenticated;
      _client = null;
    } else {
      newState = PhotosLibraryApiState.authenticated;
      _client = PhotosLibraryApiClient(auth.user.authHeaders);
      if (!_areDatabaseFilesUpToDate) {
        _refreshDatabaseFiles();
      }
    }
    state = newState;
  }

  Future<void> _handleAuthTokensRenewed() async {
    final AuthBinding auth = AuthBinding.instance;
    _client = PhotosLibraryApiClient(auth.user.authHeaders);
    state = PhotosLibraryApiState.authenticated;
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
    final PhotosAppController? app = UiBinding.instance.getTypedController();
    app?.setLibraryUpdateStatus((PhotosLibraryUpdateStatus.updating, null));
    populateDatabase().then((value) {
      app?.setLibraryUpdateStatus((PhotosLibraryUpdateStatus.success, null));
    }).catchError((dynamic error, StackTrace stackTrace) {
      app?.setLibraryUpdateStatus((PhotosLibraryUpdateStatus.error, '$error'));
      debugPrint('$error\n$stackTrace');
    }).whenComplete(() {
      Timer(const Duration(seconds: 30), () {
        app?.setLibraryUpdateStatus((PhotosLibraryUpdateStatus.idle, null));
      });
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

  /// Handles the case where a signed-in user has their auth token expire.
  ///
  /// Parts of the app that detect signals that the auth token has expired
  /// should call this method when those signals are detected.
  ///
  /// While it may yield unnecessary network traffic, it is functionally safe
  /// to call this method even when the auth token has not expired.
  Future<void> handleAuthTokenExpired() async {
    debugPrint('Detected expired OAuth token; renewing...');
    state = PhotosLibraryApiState.authenticationExpired;
    try {
      await AuthBinding.instance.renewExpiredAuthToken();
    } catch (error, stack) {
      debugPrint('Error while trying to renew auth token: $error\n$stack');
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
    final PhotosAppController? app = UiBinding.instance.getTypedController();
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
        app?.setLibraryUpdateStatus((
          PhotosLibraryUpdateStatus.updating,
          'Loaded $count photos...',
        ));
        debugPrint('Loaded $count items...');
        try {
          final ListMediaItemsResponse response = await _listMediaItems(nextPageToken);
          if (response.mediaItemsOrEmpty.isEmpty && count == 0) {
            // Special case of an empty photo library.
            await tmpPhotoFile.create();
            await tmpVideoFile.create();
            break;
          }
          await _appendPhotosToFile(tmpPhotoFile, response.mediaItemsOrEmpty);
          await _appendVideosToFile(tmpVideoFile, response.mediaItemsOrEmpty);
          count += response.mediaItemsOrEmpty.length;
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
    final Map<String, int> debugMediaItemIndexes = <String, int>{};
    try {
      for (int index in strategy.pickN(batchSize)) {
        final int offset = index * DatabaseFileCodec.blockSize;
        handle.setPositionSync(offset);
        final Uint8List bytes = await handle.read(DatabaseFileCodec.blockSize);
        String mediaItemId = codec.decodeMediaItemId(bytes);
        assert(
          mediaItemId.isNotEmpty,
          'In ${files.photosFile.path}, media item $index'
          '(offset $offset) was empty. Bytes were $bytes',
        );
        assert(() {
          if (debugMediaItemIndexes.containsKey(mediaItemId)) {
            final int existingIndex = debugMediaItemIndexes[mediaItemId]!;
            debugPrint('Duplicate media item ID ($mediaItemId) found at indexes $existingIndex and $index');
            mediaItemId = '';
            batchSize--;
          } else {
            debugMediaItemIndexes[mediaItemId] = index;
          }
          return true;
        }());
        if (mediaItemId.isNotEmpty) {
          // In debug mode, this would have failed an assert already;
          // This check is thus for release mode only.
          mediaItemIds.add(mediaItemId);
        }
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

  Future<ListMediaItemsResponse> _listMediaItems([String? nextPageToken]) async {
    final ListMediaItemsRequest request = ListMediaItemsRequest(
      pageSize: 100,
      pageToken: nextPageToken,
    );
    return await _client!.listMediaItems(request);
  }

  // Future<MediaItem?> getMediaItem(String id) async {
  //   MediaItem? result;
  //   while (result == null) {
  //     try {
  //       result = await _client!.getMediaItem(id);
  //     } on GetMediaItemException catch (error) {
  //       switch (error.statusCode) {
  //         case HttpStatus.unauthorized:
  //           debugPrint('Renewing OAuth access token in getMediaItem...');
  //           await AuthBinding.instance.signInSilently();
  //           if (state == PhotosLibraryApiState.unauthenticated) {
  //             // TODO: retry
  //             debugPrint('Unable to renew OAuth access token; bailing out');
  //             return null;
  //           }
  //           break;
  //         case HttpStatus.tooManyRequests:
  //           final PhotosLibraryApiState previousState = state;
  //           state = PhotosLibraryApiState.rateLimited;
  //           await Future.delayed(_kBackOffDuration);
  //           state = previousState;
  //           break;
  //         default:
  //           rethrow;
  //       }
  //     }
  //   }
  //   return result;
  // }

  static int _getMediaItemsInvocation = 0;
  Future<List<MediaItem>> getMediaItems(List<String> mediaItemIds) async {
    List<MediaItem>? results;
    int attempt = 0;
    while (results == null) {
      assert(() {
        _getMediaItemsInvocation++;
        attempt++;
        return true;
      }());
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
            assert(() {
              debugPrint('Received ${error.statusCode} while trying to betch get media item IDs. '
                  'Reason given was "${error.reasonPhrase}". State is currently $state');
              debugPrint('Renewing OAuth access token in getMediaItems (attempt #$attempt, invocation #$_getMediaItemsInvocation)...');
              return true;
            }());
            await handleAuthTokenExpired();
            assert(() {
              debugPrint('Successfully renewed OAuth token; state is now $state (attempt #$attempt, invocation #$_getMediaItemsInvocation)');
              return true;
            }());
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
            debugPrint('Media item IDs (${mediaItemIds.length}) were:');
            mediaItemIds.forEach(debugPrint);
            debugPrint('${StackTrace.current}');
            return <MediaItem>[];
        }
      }
    }
    return results;
  }
}
