import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'metadata.dart';

class Downloader {
  static bool isValidLink(BuildContext context, String link) {
    if (link.contains('music.youtube.com/watch?v=')) {
      return true;
    }
    return false;
  }

  static String getId(String link) {
    final index = link.indexOf('=');
    return link.substring(index + 1, index + 12);
  }

  static List<String> splitDescription(String description) {
    LineSplitter ls = const LineSplitter();
    return ls.convert(description);
  }

  static Future<SongMetadata> getMetadata(String id) async {
    final yt = YoutubeExplode();
    var song = await yt.videos.get(id);
    yt.close();
    var description = splitDescription(song.description);
    var metadata = SongMetadata(
      title: description[2].split(' · ')[0],
      artist: description[2].split(' · ')[1],
      album: description[4],
      year: '${song.publishDate}'.substring(0, 4),
    );
    return metadata;
  }

  static Future<void> downloadSong(
      String id, SongMetadata metadata, String downloadPath) async {
    // Check permissions and get temp path
    await Permission.manageExternalStorage.request().isGranted;
    Directory tempDir = await getTemporaryDirectory();

    // Get audio stream
    final yt = YoutubeExplode();
    final manifest = await yt.videos.streamsClient.getManifest(id);
    StreamInfo streamInfo = manifest.audioOnly.withHighestBitrate();

    // Download file
    var stream = yt.videos.streamsClient.get(streamInfo);
    var file = File('${tempDir.path}/temp.webm');
    var fileStream = file.openWrite();
    await stream.pipe(fileStream);
    await fileStream.flush();
    await fileStream.close();

    // Close YouTubeExplode's http client
    yt.close();

    //MetadataWriter.convertToMp3(downloadPath);
    MetadataWriter.writeMetadata(metadata, id, downloadPath, tempDir.path);
  }
}
