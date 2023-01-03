import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:file/file.dart';

/// A class containing statistics about the contents of a database file.
///
/// This class can be created and passed to [DatabaseFileCodec.decodeFile],
/// which will populate the statistics for the file.
class DatabaseFileStats {
  /// The length of the longest encoded byte list found in the database file.
  int maxByteLength = 0;

  /// The length of the longest decoded media item id found in the database
  /// file.
  int maxMediaItemIdLength = 0;
}

/// A class that can encode and decode media item ids for insertion into and
/// extraction from a database file.
class DatabaseFileCodec {
  /// Creates a new [DatabaseFileCodec].
  const DatabaseFileCodec();

  /// The amount of space, in bytes, reserved for each photo entry in the
  /// database files.
  ///
  /// Entries that take up less than this space will have a sequence of
  /// [paddingByte] bytes appended to them until they reach this block size.
  ///
  /// Having this be a fixed size (rather than delineating entries with a
  /// newline, for instance) allows us to randomly jump to any entry in a
  /// database.
  ///
  /// Empirically, the largest media item id length observed (from a
  /// collection of 22K photos/videos) is 119 characters. They're also all
  /// standard ASCII characters, so they encode in utf-8 to a maximum of
  /// 199 bytes. Thus, 128 bytes as the block size should be large enough to
  /// handle any media item id that Google Photos gives us.
  static const int blockSize = 128;

  /// The value that will be appended to the end of each database entry until
  /// the entry size reaches [blockSize].
  ///
  /// See also:
  ///
  ///  * [paddingStart], which marks the beginning of the padding sequence so
  ///    that we can identify the padding bytes from the actual utf8 bytes.
  static const int paddingByte = 0;

  /// A sequence of bytes that starts the padding sequence in a database entry.
  ///
  /// This allows us to identify the padding bytes from the actual utf8 bytes.
  static const List<int> paddingStart = <int>[0, 0, 0, 0];

  /// Encodes the specified media item into a byte array representing the id
  /// of the media item.
  ///
  /// The returned byte array is suitable for insertion into a database file.
  List<int> encodeMediaItemId(String mediaItemId) {
    final List<int> result = _padRight(utf8.encode(mediaItemId));
    assert(result.length == blockSize);
    return result;
  }

  /// Encodes the specified media items into a byte array representing the ids
  /// of the media items.
  ///
  /// The returned byte array is suitable for insertion into a database file.
  List<int> encodeMediaItemIds(Iterable<String> mediaItemIds) {
    final List<int> result = mediaItemIds
        .map<List<int>>((String id) => encodeMediaItemId(id))
        .expand((List<int> bytes) => bytes)
        .toList();
    assert(result.length == mediaItemIds.length * blockSize);
    return result;
  }

  /// Decodes the specified encoded block of bytes into a media item id.
  String decodeMediaItemId(List<int> byteBlock) {
    assert(byteBlock.length == blockSize);
    final List<int> bytes = _unpadBytes(byteBlock);
    return utf8.decode(bytes);
  }

  /// Decodes a database file into a format suitable for human consumption.
  ///
  /// The decoded byte array will be a utf-8 encoded String that contains one
  /// media item id per line.
  Future<Uint8List> decodeFile(File encoded, {DatabaseFileStats? collectStats}) async {
    assert(encoded.existsSync());
    assert(encoded.statSync().size % blockSize == 0);
    final int count = encoded.statSync().size ~/ blockSize;
    final RandomAccessFile handle = await encoded.open();
    StringBuffer buf = StringBuffer();
    try {
      for (int i = 0; i < count; i++) {
        final int offset = i * blockSize;
        handle.setPositionSync(offset);
        Uint8List bytesRead = await handle.read(blockSize);
        assert(bytesRead.length == blockSize);
        final List<int> meaningfulBytes = _unpadBytes(bytesRead);
        final String mediaItemId = utf8.decode(meaningfulBytes);
        if (collectStats != null) {
          collectStats.maxByteLength = math.max(
            collectStats.maxByteLength,
            meaningfulBytes.length,
          );
          collectStats.maxMediaItemIdLength = math.max(
            collectStats.maxMediaItemIdLength,
            mediaItemId.length,
          );
        }
        buf.writeln(mediaItemId);
      }
    } finally {
      handle.closeSync();
    }
    return utf8.encoder.convert(buf.toString());
  }

  static List<int> _padRight(List<int> bytes) {
    assert(bytes.length <= blockSize);
    return List<int>.generate(blockSize, (int index) {
      if (index < bytes.length) {
        return bytes[index];
      } else if (index - bytes.length < paddingStart.length) {
        return paddingStart[index - bytes.length];
      } else {
        return paddingByte;
      }
    });
  }

  static List<int> _unpadBytes(List<int> bytes) {
    final int? paddingStart = _getPaddingStart(bytes);
    return paddingStart == null ? bytes : bytes.sublist(0, paddingStart);
  }

  static int? _getPaddingStart(List<int> bytes) {
    bool matchAt(int index) {
      assert(index >= 0);
      assert(index + paddingStart.length <= bytes.length);
      for (int i = 0; i < paddingStart.length; i++) {
        if (bytes[index + i] != paddingStart[i]) {
          return false;
        }
      }
      return true;
    }

    for (int j = 0; j <= bytes.length - paddingStart.length; j++) {
      if (matchAt(j)) {
        return j;
      }
    }
    return null;
  }
}
