import 'package:flutter/services.dart';
import 'package:id3_codec/id3_codec.dart';

class MetadataWriter {
  static Future<void> writeMetadata(
      SongMetadata metadata, String id, String downloadPath) async {
    final data = await rootBundle.load('$downloadPath/${metadata.title}.mp3');
    final bytes = data.buffer.asUint8List();

    final header =
        await rootBundle.load('https://i.ytimg.com/vi/$id/maxresdefault.jpg');
    final headerBytes = header.buffer.asUint8List();

    final encoder = ID3Encoder(bytes);
    final resultBytes = encoder.encodeSync(MetadataV2p4Body(
      title: metadata.title,
      imageBytes: headerBytes,
      artist: metadata.artist,
      album: metadata.album,
      encoding: metadata.date,
    ));
  }
}

class SongMetadata {
  final String title;
  final String artist;
  final String album;
  final String date;

  const SongMetadata({
    required this.title,
    required this.artist,
    required this.album,
    required this.date,
  });
}
