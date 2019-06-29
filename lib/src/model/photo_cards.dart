import 'dart:io';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/scheduler.dart';
import 'package:scoped_model/scoped_model.dart';

import '../photos_library_api/media_item.dart';
import 'http_status_exception.dart';
import 'photo.dart';
import 'random.dart';

typedef PhotoMontageBuilder = PhotoMontage Function();

class PhotoMontage extends Model {
  PhotoMontage({
    int layerCount: defaultLayerCount,
    Map<int, int> columnsByLayer = defaultColumnsByLayer,
    this.padding = defaultPadding,
  }) {
    _layers = List<PhotoLayer>.generate(
      layerCount,
      (int index) => PhotoLayer._(
        montage: this,
        index: index,
        columnCount: columnsByLayer[index],
      ),
      growable: false,
    );
  }

  static const int defaultLayerCount = 3;
  static const double defaultPadding = 0.02;

  static const Map<int, int> defaultColumnsByLayer = <int, int>{
    0: 2,
    1: 3,
    2: 5,
  };

  final double padding;
  List<PhotoLayer> _layers;

  int get layers => _layers.length;

  Future<PhotoCard> addPhoto(MediaItem mediaItem) async {
    List<PhotoColumn> candidates = _layers
        .map<List<PhotoColumn>>((PhotoLayer layer) => layer._columns)
        .expand<PhotoColumn>((List<PhotoColumn> columns) => columns)
        .where((PhotoColumn column) => column._cards.isEmpty || column._cards.first.isClear)
        .toList();
    if (candidates.isEmpty) {
      return null;
    }

    PhotoColumn column = candidates[random.nextInt(candidates.length)];
    Photo photo = await _loadPhoto(mediaItem, column);

    PhotoCard card = PhotoCard._(photo: photo, column: column);
    column._cards.insert(0, card);
    notifyListeners();
    return card;
  }

  Future<Photo> _loadPhoto(MediaItem mediaItem, PhotoColumn column) async {
    Size sizeConstraints = Size.square(column.width * window.physicalSize.width);
    Size photoSize = applyBoxFit(BoxFit.scaleDown, mediaItem.size, sizeConstraints).destination;
    String url = '${mediaItem.baseUrl}=w${photoSize.width.toInt()}-h${photoSize.height.toInt()}';

    final HttpClient httpClient = HttpClient();
    final Uri resolved = Uri.base.resolve(url);
    final HttpClientRequest request = await httpClient.getUrl(resolved);
    final HttpClientResponse response = await request.close();
    if (response.statusCode != HttpStatus.ok) {
      throw HttpStatusException(response.statusCode);
    }

    return Photo(
      mediaItem,
      photoSize / window.devicePixelRatio,
      window.devicePixelRatio,
      await consolidateHttpClientResponseBytes(response),
    );
  }

  Iterable<PhotoCard> get cards => _layers.reversed
      .map<List<PhotoColumn>>((PhotoLayer layer) => layer._columns)
      .expand<PhotoColumn>((List<PhotoColumn> columns) => columns)
      .map<List<PhotoCard>>((PhotoColumn column) => column._cards)
      .expand<PhotoCard>((List<PhotoCard> cards) => cards);

  void _notifyListeners() {
    notifyListeners();
  }
}

class PhotoLayer {
  PhotoLayer._({
    @required this.montage,
    @required this.index,
    int columnCount,
  }) {
    _columns = List<PhotoColumn>.generate(
      columnCount,
      (int index) => PhotoColumn._(layer: this, index: index),
      growable: false,
    );
  }

  final PhotoMontage montage;
  final int index;
  List<PhotoColumn> _columns;

  int get columns => _columns.length;
}

class PhotoColumn {
  PhotoColumn._({
    @required this.layer,
    @required this.index,
  });

  final PhotoLayer layer;
  final int index;
  final List<PhotoCard> _cards = <PhotoCard>[];

  /// The width of this column, expressed as a percentage of screen width.
  double get width {
    double totalPadding = (layer.columns + 1) * layer.montage.padding;
    double remainingWidth = 1 - totalPadding;
    return remainingWidth / layer.columns;
  }

  /// The left offset of this column, expressed as a percentage of screen width.
  double get left {
    double left = (index + 1) * layer.montage.padding;
    left += index * width;
    return left;
  }
}

class PhotoCard {
  PhotoCard._({
    @required this.photo,
    @required this.column,
  });

  final Photo photo;
  final PhotoColumn column;

  double get top => _top;
  double _top = 0;

  double get bottom => _top - photo.size.height;

  bool get isClear => bottom > 0;

  double get scale => photo.scale / column.width;

  void nextFrame() {
    PhotoLayer layer = column.layer;
    int layerCount = layer.montage._layers.length;
    _top += (layerCount - layer.index) / layerCount / timeDilation;
  }

  void dispose() {
    bool removed = column._cards.remove(this);
    assert(removed);
    column.layer.montage._notifyListeners();
  }
}
