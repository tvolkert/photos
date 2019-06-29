import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'exceptions.dart';
import 'media_item.dart';
import 'search_media_items_request.dart';
import 'search_media_items_response.dart';

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
      throw PhotosApiException(response);
    }

    return SearchMediaItemsResponse.fromJson(jsonDecode(response.body));
  }

  Future<MediaItem> getMediaItem(String id) async {
    final http.Response response = await http.get(
      'https://photoslibrary.googleapis.com/v1/mediaItems/$id',
      headers: await _authHeaders,
    );

    if (response.statusCode != HttpStatus.ok) {
      throw GetMediaItemException(id, response);
    }

    return MediaItem.fromJson(jsonDecode(response.body));
  }
}
