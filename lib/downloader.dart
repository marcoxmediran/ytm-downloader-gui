import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:audiotags/audiotags.dart';
import 'package:ffmpeg_kit_flutter_audio/ffmpeg_kit.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart';
import 'package:media_scanner/media_scanner.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

import 'package:ytm_downloader_gui/globals.dart';

class Downloader {
  // Singleton pattern
  static final Downloader _downloader = Downloader._internal();
  factory Downloader() {
    return _downloader;
  }
  Downloader._internal();
  var tags = <Tag>[];

  // Functions
  bool isValidLink(String link) {
    return link.contains('music.youtube.com/watch?v=');
  }

  List<String> splitDescription(String description) {
    LineSplitter ls = const LineSplitter();
    return ls.convert(description);
  }

  Future<void> download(String link) async {
    // Check permissions and get temp path
    await Permission.manageExternalStorage.request().isGranted;
    Directory tempDir = await getTemporaryDirectory();
    var tempPath = tempDir.path;
    const downloadPath = '/storage/emulated/0/Music';

    // Get audio details
    final yt = YoutubeExplode();
    final music = await yt.videos.get(link);
    final id = music.id;
    final description = splitDescription(music.description);

    // Get album art
    final thumbnailUrl = 'https://img.youtube.com/vi/$id/maxresdefault.jpg';
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

    // Generate audio tags
    Tag tag = Tag(
      title: music.title,
      trackArtist: music.author.replaceAll(' - Topic', ''),
      album: (description.length >= 4) ? description[4] : music.title,
      year: music.publishDate!.year,
      pictures: [
        Picture(
          pictureType: PictureType.coverFront,
          bytes: Uint8List.fromList(encodePng(albumArt)),
        ),
      ],
    );
    tags.insert(0, tag);

    // Notify start of download
    final snackBar = SnackBar(
      content: Text('Downloading ${tag.title}'),
      behavior: SnackBarBehavior.floating,
    );
    Globals.scaffoldMessengerKey.currentState?.showSnackBar(snackBar);

    // Download file
    final manifest = await yt.videos.streamsClient.getManifest(id);
    StreamInfo streamInfo = manifest.audioOnly.last;
    var stream = yt.videos.streamsClient.get(streamInfo);
    var tempWebm = File('$tempPath/$id.webm');
    var fileStream = tempWebm.openWrite();
    await stream.pipe(fileStream);
    await fileStream.flush();
    await fileStream.close();

    // Close YouTubeExplode's http client
    yt.close();

    // Extract opus audio stream from webm file
    var command =
        '-i "$tempPath/$id.webm" -vn -c:a copy -y "$tempPath/$id.opus"';
    await FFmpegKit.execute(command);

    // Apply audio tags
    await AudioTags.write('$tempPath/$id.opus', tag);

    // Copy and rename file
    final fileName = '${tag.title} - ${tag.trackArtist}'
        .replaceAll(RegExp(r'''[:/'"*<>?\|]'''), '_');
    await File('$tempPath/$id.opus').copy('$downloadPath/$fileName.opus');

    // File cleanup
    await File('$tempPath/$id.opus').delete();
    await File('$tempPath/$id.webm').delete();

    // Refresh storage media
    await MediaScanner.loadMedia(path: downloadPath);
  }
}
