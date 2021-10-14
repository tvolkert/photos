import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
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
    final Uri url = Uri.https('photoslibrary.googleapis.com', '/v1/mediaItems', <String, dynamic>{
      'pageSize': '${request.pageSize}',
      if (request.pageToken != null) 'pageToken': request.pageToken,
    });
    final http.Response response = await http.get(url, headers: await _authHeaders);

    if (response.statusCode != HttpStatus.ok) {
      throw PhotosApiException(url, response);
    }

    try {
      return ListMediaItemsResponse.fromJson(jsonDecode(response.body));
    } catch (error) {
      debugPrint(response.body);
      rethrow;
    }
  }

  Future<SearchMediaItemsResponse> searchMediaItems(SearchMediaItemsRequest request) async {
    final Uri url = Uri.parse('https://photoslibrary.googleapis.com/v1/mediaItems:search');
    final http.Response response = await http.post(
      url,
      body: jsonEncode(request),
      headers: await _authHeaders,
    );

    if (response.statusCode != 200) {
      throw PhotosApiException(url, response);
    }

    return SearchMediaItemsResponse.fromJson(jsonDecode(response.body));
  }

  Future<MediaItem> getMediaItem(String id) async {
    final Uri url = Uri.parse('https://photoslibrary.googleapis.com/v1/mediaItems/$id');
    final http.Response response = await http.get(
      url,
      headers: await _authHeaders,
    );

    if (response.statusCode != HttpStatus.ok) {
      throw GetMediaItemException(id, url, response);
    }

    return MediaItem.fromJson(jsonDecode(response.body));
  }

  Future<BatchGetResponse> batchGet(BatchGetRequest request) async {
    final Uri url = Uri.https('photoslibrary.googleapis.com', '/v1/mediaItems:batchGet', <String, dynamic>{
      'mediaItemIds': request.mediaItemIds,
    });
    final http.Response response = await http.get(url, headers: await _authHeaders);

    if (response.statusCode != 200) {
      throw PhotosApiException(url, response);
    }

    return BatchGetResponse.fromJson(jsonDecode(response.body));
  }
}
