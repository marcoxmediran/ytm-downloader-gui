import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:audiotags/audiotags.dart';
import 'package:ffmpeg_kit_flutter_audio/ffmpeg_kit.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart';
import 'package:media_scanner/media_scanner.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

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

    // Get album art
    final thumbnailUrl = music.thumbnails.maxResUrl;
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
      trackArtist: music.author.substring(0, music.author.length - 8),
      album: splitDescription(music.description)[4],
      year: music.publishDate!.year,
      pictures: [
        Picture(
          pictureType: PictureType.coverFront,
          bytes: Uint8List.fromList(encodePng(albumArt)),
        ),
      ],
    );
    tags.insert(0, tag);
    final fileName = '${tag.trackArtist} - ${tag.title}';

    // Download file
    final manifest = await yt.videos.streamsClient.getManifest(link);
    StreamInfo streamInfo = manifest.audioOnly.withHighestBitrate();
    var stream = yt.videos.streamsClient.get(streamInfo);
    var tempWebm = File('$tempPath/$fileName.webm');
    var fileStream = tempWebm.openWrite();
    await stream.pipe(fileStream);
    await fileStream.flush();
    await fileStream.close();

    // Close YouTubeExplode's http client
    yt.close();

    // Extract opus audio stream from webm file
    var command =
        '-i "$tempPath/$fileName.webm" -vn -c:a copy -y "$downloadPath/$fileName.opus"';
    await FFmpegKit.execute(command);

    // Apply audio tags
    await AudioTags.write('$downloadPath/$fileName.opus', tag);

    // Refresh storage media
    await MediaScanner.loadMedia(path: downloadPath);
  }
}
