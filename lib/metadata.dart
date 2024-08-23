import 'dart:io';
import 'package:ffmpeg_kit_flutter_audio/ffmpeg_kit.dart';
import 'package:audiotags/audiotags.dart';
import 'package:http/http.dart' as http;
import 'package:media_scanner/media_scanner.dart';

class MetadataWriter {
  static writeMetadata(
      SongMetadata metadata, String id, String downloadPath, String tempDir) {
    // Convert webm to mp3
    var command = '-i "$tempDir/temp.webm" ';
    command += '-vn -acodec libmp3lame -ab 192k ';
    command += '-y "$downloadPath/${metadata.title}.mp3"';
    FFmpegKit.execute(command).then((value) async {
      // Download album art
      String albumArtLink = 'https://i.ytimg.com/vi/$id/maxresdefault.jpg';
      final http.Response response = await http.get(Uri.parse(albumArtLink));

      var tempWebm = File('$tempDir/temp.webm');

      // Write Metadata
      Tag tag = Tag(
          title: metadata.title,
          trackArtist: metadata.artist,
          album: metadata.album,
          year: int.parse(metadata.year),
          pictures: [
            Picture(
                bytes: response.bodyBytes,
                pictureType: PictureType.other),
          ]);

      AudioTags.write('$downloadPath/${metadata.title}.mp3', tag);
      MediaScanner.loadMedia(path: downloadPath);

      // Clean up
      await tempWebm.delete();
    });
  }
}

class SongMetadata {
  final String title;
  final String artist;
  final String album;
  final String year;

  const SongMetadata({
    required this.title,
    required this.artist,
    required this.album,
    required this.year,
  });
}
