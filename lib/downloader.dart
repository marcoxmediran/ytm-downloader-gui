import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:audiotags/audiotags.dart';

class Downloader {
  static Future downloadStream(String link) async {
    String downloadPath = '/storage/emulated/0/Music';

    // Get audio stream
    final yt = YoutubeExplode();
    final manifest = await yt.videos.streamsClient.getManifest(link);
    StreamInfo streamInfo = manifest.audioOnly.withHighestBitrate();

    // Download file
    var stream = yt.videos.streamsClient.get(streamInfo);
    var file = File('$downloadPath/test.mp3');
    var fileStream = file.openWrite();
    await stream.pipe(fileStream);
    await fileStream.flush();
    await fileStream.close();

    // Close YouTubeExplode's http client
    yt.close();
  }

  static void playground(String link) async {
    String downloadPath = '/storage/emulated/0/Music';

    final yt = YoutubeExplode();
    var videoMetadata = await yt.videos.get(link);
    final String description = videoMetadata.description;
    yt.close();

    LineSplitter ls = const LineSplitter();
    List<String> splitDescription = ls.convert(description);

    Tag tag = Tag(
      title: splitDescription[4],
      pictures: [],
    );

    AudioTags.write('$downloadPath/test.mp3', tag);
  }
}
