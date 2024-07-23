import 'dart:async';
import 'dart:convert' show json;
import 'dart:io' show HttpStatus;
import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/widgets.dart';

import 'package:photos/src/model/photo_producer.dart';
import 'package:photos/src/photos_library_api/media_item.dart';
import 'package:photos/src/photos_library_api/media_metadata.dart';
import 'package:photos/src/ui/photos/photos_page.dart';

import 'content_provider.dart';
import 'photo.dart';

mixin UnsplashContentProvider on ContentProviderBinding {
  @override
  Future<void> init() async {
    // No-op
  }

  @override
  Widget buildHome(BuildContext context) {
    return MontageContainer(producer: UnsplashPhotoProducer());
  }

  @override
  String getMediaItemUrl(MediaItem item, ui.Size size) =>'${item.baseUrl}&w=${size.width.toInt()}&h=${size.height.toInt()}&fit=max&fm=jpg';
}

class UnsplashPhotoProducer extends PhotoProducer {
  UnsplashPhotoProducer();

  int _iter = _maxSize;
  final List<MediaItem> queue = <MediaItem>[];
  Completer<void>? _queueCompleter;

  static const int _batchSize = 30;
  static const int _maxSize = 1200;

  Future<void> _queueItems() {
    if (_queueCompleter != null) {
      return _queueCompleter!.future;
    }
    _queueCompleter = Completer<void>();
    final Future<void> result = _doQueueItems();
    _queueCompleter!.complete(result);
    _queueCompleter = null;
    return result;
  }

  /// Method that does the actual work of queueing media items.
  ///
  /// Assuming the database files have been created, this method will always
  /// make a request to the Google Photos API, even if other requests are still
  /// pending. To ensure that we reuse existing pending requests, use
  /// [_queueItems] instead.
  Future<void> _doQueueItems() async {
    final String clientId = await rootBundle.loadString('assets/unsplash_client_id');
    final Uri url = Uri.https('api.unsplash.com', '/photos/random', <String, dynamic>{
      'count': '$_batchSize',
    });
    final http.Response response = await http.get(url, headers: <String, String>{
      'Authorization': 'Client-ID $clientId'
    });

    if (response.statusCode != HttpStatus.ok) {
      throw '~!@ BAD RESPONSE\n\n${response.headers}\n\n${response.body}';
    }

    final List<Map<String, dynamic>> data = json.decode(response.body).cast<Map<String, dynamic>>();
    final List<MediaItem> items = <MediaItem>[];
    for (Map<String, dynamic> datum in data) {
      items.add(MediaItem(
        id: datum['id'],
        description: datum['description'],
        productUrl: datum['links']['html'],
        baseUrl: datum['urls']['raw'],
        mediaMetadata: MediaMetadata(
          width: datum['width'].toString(),
          height: datum['height'].toString(),
        ),
      ));
    }
    queue.addAll(items);
  }

  @override
  Future<Photo> produce({
    required BuildContext context,
    required Size sizeConstraints,
    double scaleMultiplier = 1,
  }) async {
    final ui.FlutterView window = View.of(context);

    if (++_iter >= _maxSize) {
      _iter = 0;
    }

    if (_iter >= queue.length) {
      await _queueItems();
    }

    if (_iter >= queue.length) {
      // ignore: use_build_context_synchronously
      return await const AssetPhotoProducer().produce(
        context: context,
        sizeConstraints: sizeConstraints,
        scaleMultiplier: scaleMultiplier,
      );
    } else {
      final double scale = window.devicePixelRatio * scaleMultiplier;
      final MediaItem mediaItem = queue[_iter];
      final Size photoLogicalSize = applyBoxFit(
        BoxFit.scaleDown,
        mediaItem.size!,
        sizeConstraints,
      ).destination;
      return Photo(
        id: mediaItem.id,
        mediaItem: mediaItem,
        size: photoLogicalSize,
        scale: scale,
        boundingConstraints: sizeConstraints,
        image: NetworkImage(ContentProviderBinding.instance.getMediaItemUrl(mediaItem, photoLogicalSize * scale), scale: scale),
      );
    }
  }
}
