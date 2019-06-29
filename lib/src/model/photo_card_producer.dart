import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import '../photos_library_api/exceptions.dart';
import '../photos_library_api/media_item.dart';

import 'photo_cards.dart';
import 'photos_library_api_model.dart';
import 'random.dart';

typedef PhotoCardProducerBuilder = PhotoCardProducer Function(
  PhotosLibraryApiModel model,
  PhotoMontage montage,
);

class PhotoCardProducer {
  PhotoCardProducer(this.model, this.montage) {
    debugPrint('creating new producer - ${StackTrace.current}');
  }

  static const Duration interval = Duration(seconds: 1, milliseconds: 750);

  final PhotosLibraryApiModel model;
  final PhotoMontage montage;

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

  Future<void> _addCard() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    File photosFile = File(path.join(documentsDirectory.path, 'photos'));
    File countFile = File(path.join(documentsDirectory.path, 'count'));

    if (countFile.existsSync() && photosFile.existsSync()) {
      int count = int.parse(await countFile.readAsString());
      int skip = random.nextInt(count);

      try {
        String id = await photosFile
            .openRead()
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
