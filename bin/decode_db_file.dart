// ignore_for_file: avoid_print

import 'dart:typed_data';

import 'package:photos/src/model/codecs.dart';
import 'package:file/file.dart';
import 'package:file/local.dart';

void main(List<String> args) async {
  const FileSystem fs = LocalFileSystem();
  const DatabaseFileCodec codec = DatabaseFileCodec();
  final DatabaseFileStats stats = DatabaseFileStats();
  final File inputFile = fs.file(args[0]);
  final File outputFile = fs.file(args[1]);
  final Uint8List decodedBytes = await codec.decodeFile(inputFile, collectStats: stats);
  await outputFile.writeAsBytes(decodedBytes);
  print('success');
  print('Max media item id length was ${stats.maxMediaItemIdLength}');
  print('Max encoded byte length was ${stats.maxByteLength}');
}
