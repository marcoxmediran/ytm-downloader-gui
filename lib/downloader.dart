import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:audiotags/audiotags.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:media_scanner/media_scanner.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:ffmpeg_kit_flutter_audio/ffmpeg_kit.dart';
import 'package:image/image.dart';

class Downloader {
  static bool isValidLink(BuildContext context, String link) {
    return link.contains('music.youtube.com/watch?v=');
  }

  static String getId(String link) {
    final index = link.indexOf('=');
    return link.substring(index + 1, index + 12);
  }

  static List<String> splitDescription(String description) {
    LineSplitter ls = const LineSplitter();
    return ls.convert(description);
  }

  static Future<void> download(String id) async {
    // Check permissions and get temp path
    await Permission.manageExternalStorage.request().isGranted;
    Directory tempDir = await getTemporaryDirectory();
    const downloadPath = '/storage/emulated/0/Music';

    // Get audio details
    final yt = YoutubeExplode();
    final song = await yt.videos.get(id);

    // Download file
    final manifest = await yt.videos.streamsClient.getManifest(id);
    StreamInfo streamInfo = manifest.audioOnly.withHighestBitrate();
    var stream = yt.videos.streamsClient.get(streamInfo);
    var tempWebm = File('${tempDir.path}/temp.webm');
    var fileStream = tempWebm.openWrite();
    await stream.pipe(fileStream);
    await fileStream.flush();
    await fileStream.close();

    // Close YouTubeExplode's http client
    yt.close();

    // Get album art
    final thumbnailUrl = song.thumbnails.maxResUrl;
    final http.Response response = await http.get(Uri.parse(thumbnailUrl));
    final originalImage = response.bodyBytes;
    final decodedImage = decodeImage(originalImage);
    final albumArt = copyCrop(
      decodedImage!,
      x: 280,
      y: 0,
      width: 720,
      height: 720,
    );

    // Convert webm to mp3
    var command =
        '-i "${tempDir.path}/temp.webm" "$downloadPath/${song.title}.mp3"';
    FFmpegKit.execute(command).then((session) async {
      // Apply audio tags
      Tag tag = Tag(
        title: song.title,
        trackArtist: song.author.substring(0, song.author.length - 8),
        album: splitDescription(song.description)[4],
        year: song.publishDate!.year,
        pictures: [
          Picture(
            pictureType: PictureType.coverFront,
            bytes: Uint8List.fromList(encodePng(albumArt)),
          ),
        ],
      );
      AudioTags.write('$downloadPath/${song.title}.mp3', tag);

      // Refresh storage media
      MediaScanner.loadMedia(path: downloadPath);
    });
  }
}
