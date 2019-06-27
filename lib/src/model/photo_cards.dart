import 'package:flutter/foundation.dart';
import 'package:scoped_model/scoped_model.dart';

import 'photo.dart';
import 'random.dart';

typedef PhotoMontageBuilder = PhotoMontage Function();

class PhotoMontage extends Model {
  PhotoMontage({
    int layerCount: defaultLayerCount,
    int topLayerColumnCount = defaultTopLayerColumnCount,
    this.padding = defaultPadding,
  }) {
    _layers = List<PhotoLayer>.generate(
      layerCount,
      (int index) => PhotoLayer._(
        montage: this,
        index: index,
        columnCount: index + topLayerColumnCount,
      ),
      growable: false,
    );
  }

  static const int defaultLayerCount = 3;
  static const int defaultTopLayerColumnCount = 2;
  static const double defaultPadding = 0.02;

  final double padding;
  List<PhotoLayer> _layers;

  int get layers => _layers.length;

  PhotoCard addPhoto(Photo photo) {
    List<PhotoColumn> candidates = _layers
        .map<List<PhotoColumn>>((PhotoLayer layer) => layer._columns)
        .expand<PhotoColumn>((List<PhotoColumn> columns) => columns)
        .where((PhotoColumn column) => column._cards.isEmpty || column._cards.last.isClear)
        .toList();
    if (candidates.isEmpty) {
      return null;
    }
    PhotoColumn column = candidates[random.nextInt(candidates.length)];
    PhotoCard card = PhotoCard._(photo: photo, column: column);
    column._cards.insert(0, card);
    debugPrint('notifying listeners');
    notifyListeners();
    return card;
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

//
//  @override
//  int get hashCode => hashValues(stack, index);
//
//  @override
//  bool operator ==(dynamic other) {
//    if (runtimeType != other.runtimeType) {
//      return false;
//    }
//    PhotoLayer typedOther = other;
//    return stack == typedOther.stack && index == typedOther.index;
//  }
}

class PhotoColumn {
  PhotoColumn._({
    @required this.layer,
    @required this.index,
  });

  final PhotoLayer layer;
  final int index;
  final List<PhotoCard> _cards = <PhotoCard>[];

//  @override
//  int get hashCode => hashValues(layer, index);
//
//  @override
//  bool operator ==(dynamic other) {
//    if (runtimeType != other.runtimeType) {
//      return false;
//    }
//    PhotoColumn typedOther = other;
//    return layer == typedOther.layer && index == typedOther.index;
//  }
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

  bool get isClear => _top > photo.size.height;

  double get scale => photo.scale / width;

  /// The left offset of this card, expressed as a percentage of screen width.
  double get left {
    double left = (column.index + 1) * column.layer.montage.padding;
    left += column.index * width;
    return left;
  }

  /// The width of this card, expressed as a percentage of screen width.
  double get width {
    double totalPadding = (column.layer.columns + 1) * column.layer.montage.padding;
    double remainingWidth = 1 - totalPadding;
    return remainingWidth / column.layer.columns;
  }

  void nextFrame() {
    PhotoLayer layer = column.layer;
    int layerCount = layer.montage._layers.length;
    _top += (layerCount - layer.index) / layerCount;
  }

  void dispose() {
    debugPrint('disposing of photo in column ${column.index} of layer ${column.layer.index}');
    bool removed = column._cards.remove(this);
    assert(removed);
    debugPrint('notifying listeners');
    column.layer.montage._notifyListeners();
  }

//  @override
//  int get hashCode => hashValues(photo, column);
//
//  @override
//  bool operator ==(dynamic other) {
//    if (runtimeType != other.runtimeType) {
//      return false;
//    }
//    PhotoCard typedOther = other;
//    return photo == typedOther.photo && column == typedOther.column;
//  }
}
