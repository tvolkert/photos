import 'dart:async';
import 'dart:typed_data';
import 'dart:convert';

import 'package:flutter/scheduler.dart';

import '../photos_library_api/exceptions.dart';
import '../photos_library_api/media_item.dart';

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

  static const Duration interval = Duration(seconds: 1, milliseconds: 750);

  Timer _timer;

  void start() {
    if (_timer != null) {
      throw StateError('Already started');
    }
    _scheduleProduce();
  }

  void stop() {
    if (_timer != null) {
      _timer.cancel();
      _timer = null;
    }
  }

  bool get isStarted => _timer != null;

  void _scheduleProduce() {
    _timer = Timer(interval * timeDilation, _addCard);
  }

  Future<void> _addCard();
}

class _ApiPhotoCardProducer extends PhotoCardProducer {
  _ApiPhotoCardProducer(this.model, this.montage) : super._();

  final PhotosLibraryApiModel model;
  final PhotoMontage montage;

  @override
  Future<void> _addCard() async {
    final FilesBinding files = FilesBinding.instance;

    if (files.countFile.existsSync() && files.photosFile.existsSync()) {
      int count = int.parse(await files.countFile.readAsString());
      int skip = random.nextInt(count);

      try {
        String id = await files.photosFile
            .openRead()
            .cast<List<int>>()
            .transform(utf8.decoder)
            .transform(const LineSplitter())
            .skip(skip)
            .first;
        try {
          MediaItem mediaItem = await model.getMediaItem(id);
          if (mediaItem == null) {
            stop();
            return;
          }
          await montage.addPhoto(mediaItem);
        } on GetMediaItemException catch (error) {
          print('Error getting media item ${error.mediaItemId}');
          print(error.reasonPhrase);
          print(error.responseBody);
        }
      } on StateError {
        // Our count seems to have gotten out of sync.
      }
    }

    _scheduleProduce();
  }
}

class _StaticPhotoCardProducer extends PhotoCardProducer {
  _StaticPhotoCardProducer(this.montage) : super._();

  final PhotoMontage montage;

  @override
  Future<void> _addCard() async {
  }
}
