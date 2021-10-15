import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:file/file.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

import '../photos_library_api/media_item.dart';
import '../photos_library_api/media_metadata.dart';

import 'files.dart';
import 'photo_cards.dart';
import 'photos_library_api_model.dart';
import 'random.dart';

typedef PhotoCardProducerBuilder = PhotoCardProducer Function(
  PhotosLibraryApiModel model,
  PhotoMontage montage,
);

abstract class PhotoCardProducer {
  factory PhotoCardProducer(
    PhotosLibraryApiModel model,
    PhotoMontage montage,
  ) = _ApiPhotoCardProducer;

  factory PhotoCardProducer.asset(PhotoMontage montage) = _StaticPhotoCardProducer;

  PhotoCardProducer._();

  static const Duration interval = Duration(seconds: 5);

  Timer? _timer;

  void start() {
    if (_timer != null) {
      throw StateError('Already started');
    }
    _scheduleOneTimeProduce();
  }

  void stop() {
    if (_timer != null) {
      _timer!.cancel();
      _timer = null;
    }
  }

  bool get isStarted => _timer != null;

  void _scheduleOneTimeProduce() {
    _timer = Timer(interval * timeDilation, _produce);
  }

  Future<void> _produce();
}

class _ApiPhotoCardProducer extends PhotoCardProducer {
  _ApiPhotoCardProducer(this.model, this.montage) : super._();

  final PhotosLibraryApiModel model;
  final PhotoMontage montage;
  final List<MediaItem> _queue = <MediaItem>[];

  static const _kBatchSize = 50;

  Future<void> queueItems() async {
    final FilesBinding files = FilesBinding.instance;

    if (files.countFile.existsSync() && files.photosFile.existsSync()) {
      final int count = int.parse(await files.countFile.readAsString());
      final int realCount = files.photosFile.statSync().size ~/ PhotosLibraryApiModel.kBlockSize;
      assert(count == realCount);
      final List<String> mediaItemIds = <String>[];
      final RandomAccessFile handle = await files.photosFile.open();
      try {
        for (int i = 0; i < _kBatchSize; i++) {
          final int offset = random.nextInt(count) * PhotosLibraryApiModel.kBlockSize;
          handle.setPositionSync(offset);
          final List<int> bytes = _unpadBytes(await handle.read(PhotosLibraryApiModel.kBlockSize));
          final String mediaItemId = utf8.decode(bytes);
          mediaItemIds.add(mediaItemId);
        }
      } finally {
        handle.closeSync();
      }
      assert(mediaItemIds.length == _kBatchSize);
      Iterable<MediaItem> items = await model.getMediaItems(mediaItemIds);
      items = items.where((MediaItem item) => item.size != null);
      assert(() {
        if (items.length != _kBatchSize) {
          debugPrint('Expecting $_kBatchSize items, but retrieved ${items.length}');
        }
        return true;
      }());
      _queue.insertAll(0, items);
    }
  }

  List<int> _unpadBytes(Uint8List bytes) {
    final int? paddingStart = _getPaddingStart(bytes);
    return paddingStart == null ? bytes : bytes.sublist(0, paddingStart);
  }

  int? _getPaddingStart(Uint8List bytes) {
    bool matchAt(int index) {
      assert(index >= 0);
      assert(index + PhotosLibraryApiModel.kPaddingStart.length <= bytes.length);
      for (int i = 0; i < PhotosLibraryApiModel.kPaddingStart.length; i++) {
        if (bytes[index + i] != PhotosLibraryApiModel.kPaddingStart[i]) {
          return false;
        }
      }
      return true;
    }
    int? paddingStart;
    for (int j = 0; j <= bytes.length - PhotosLibraryApiModel.kPaddingStart.length; j++) {
      if (matchAt(j)) {
        return j;
      }
    }
    return null;
  }

  @override
  Future<void> _produce() async {
    if (_queue.isEmpty) {
      await queueItems();
    }

    if (_queue.isEmpty) {
      // We were unable to queue any real photos; produce a static photo.
      await _produceStaticPhoto(montage);
    } else {
      await montage.addMediaItem(_queue.removeLast());
    }
    _scheduleOneTimeProduce();
  }
}

class _StaticPhotoCardProducer extends PhotoCardProducer {
  _StaticPhotoCardProducer(this.montage) : super._();

  final PhotoMontage montage;

  @override
  Future<void> _produce() => _produceStaticPhoto(montage);
}

Future<void> _produceStaticPhoto(PhotoMontage montage) async {
  const MediaItem sample = MediaItem(
    id: 'test',
    baseUrl:
        'https://lh3.googleusercontent.com/ogw/ADea4I4W_CNuQmCCPTLweMp6ndpZmVOgwL7GCClptOUZG6M',
    mediaMetadata: MediaMetadata(
      width: '256',
      height: '256',
    ),
  );
  await montage.addMediaItem(sample);
}
