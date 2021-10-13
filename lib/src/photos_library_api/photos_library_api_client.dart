import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'batch_get_request.dart';
import 'batch_get_response.dart';
import 'exceptions.dart';
import 'list_media_items_request.dart';
import 'list_media_items_response.dart';
import 'media_item.dart';
import 'search_media_items_request.dart';
import 'search_media_items_response.dart';

class PhotosLibraryApiClient {
  const PhotosLibraryApiClient(this._authHeaders);

  final Future<Map<String, String>> _authHeaders;

  Future<ListMediaItemsResponse> listMediaItems(ListMediaItemsRequest request) async {
    final http.Response response = await http.get(
      Uri.https('photoslibrary.googleapis.com', '/v1/mediaItems', <String, dynamic>{
        'pageSize': request.pageSize,
        if (request.pageToken != null) 'pageToken': request.pageToken,
      }),
      headers: await _authHeaders,
    );

    if (response.statusCode != 200) {
      throw PhotosApiException(response);
    }

    return ListMediaItemsResponse.fromJson(jsonDecode(response.body));
  }

  Future<SearchMediaItemsResponse> searchMediaItems(SearchMediaItemsRequest request) async {
    final http.Response response = await http.post(
      Uri.parse('https://photoslibrary.googleapis.com/v1/mediaItems:search'),
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
      Uri.parse('https://photoslibrary.googleapis.com/v1/mediaItems/$id'),
      headers: await _authHeaders,
    );

    if (response.statusCode != HttpStatus.ok) {
      throw GetMediaItemException(id, response);
    }

    return MediaItem.fromJson(jsonDecode(response.body));
  }

  Future<BatchGetResponse> batchGet(BatchGetRequest request) async {
    final http.Response response = await http.get(
      Uri.https('photoslibrary.googleapis.com', '/v1/mediaItems:batchGet', <String, dynamic>{
        'mediaItemIds': request.mediaItemIds,
      }),
      headers: await _authHeaders,
    );

    if (response.statusCode != 200) {
      throw PhotosApiException(response);
    }

    return BatchGetResponse.fromJson(jsonDecode(response.body));
  }
}
