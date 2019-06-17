import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:photos/src/photos_library_api/media_item.dart';
import 'package:photos/src/photos_library_api/search_media_items_request.dart';
import 'package:photos/src/photos_library_api/search_media_items_response.dart';

class PhotosLibraryApiClient {
  const PhotosLibraryApiClient(this._authHeaders);

  final Future<Map<String, String>> _authHeaders;

  Future<SearchMediaItemsResponse> searchMediaItems(SearchMediaItemsRequest request) async {
    final http.Response response = await http.post(
      'https://photoslibrary.googleapis.com/v1/mediaItems:search',
      body: jsonEncode(request),
      headers: await _authHeaders,
    );

    if (response.statusCode != 200) {
      throw PhotosApiException._(response);
    }

    return SearchMediaItemsResponse.fromJson(jsonDecode(response.body));
  }

  Future<MediaItem> getMediaItem(String id) async {
    final http.Response response = await http.get(
      'https://photoslibrary.googleapis.com/v1/mediaItems/$id',
      headers: await _authHeaders,
    );

    if (response.statusCode != HttpStatus.ok) {
      throw GetMediaItemException._(id, response);
    }

    return MediaItem.fromJson(jsonDecode(response.body));
  }
}

class PhotosApiException implements Exception {
  /// Creates a new [PhotosApiException].
  PhotosApiException._(http.Response response)
      : statusCode = response.statusCode,
        reasonPhrase = response.reasonPhrase,
        responseBody = response.body;

  /// The HTTP status code that the server responded with.
  ///
  /// See also:
  ///  * [HttpStatus] for a list of known HTTP status codes.
  final int statusCode;

  /// A human-readable description of the HTTP status.
  final String reasonPhrase;

  /// The body of the response that the server responded with.
  final String responseBody;
}

class GetMediaItemException extends PhotosApiException {
  /// Creates a new [GetMediaItemException].
  GetMediaItemException._(this.mediaItemId, http.Response response) : super._(response);

  /// The id of the media item that was attempted to be retrieved.
  ///
  /// The product URL for a given media item is https://photos.google.com/lr/photo/$id.
  final String mediaItemId;
}
