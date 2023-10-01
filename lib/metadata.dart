import 'package:ffmpeg_kit_flutter_audio/ffmpeg_kit.dart';

class MetadataWriter {
  static void writeMetadata(SongMetadata metadata, String downloadPath) {
    var command = '-i "$downloadPath/temp.webm" ';
    command += '-vn -acodec libmp3lame -ab 192k ';
    command += '-metadata title="${metadata.title}" ';
    command += '-metadata artist="${metadata.artist}" ';
    command += '-metadata album="${metadata.album}" ';
    command += '-metadata year="${metadata.year}" ';
    command += '-y "$downloadPath/${metadata.title}.mp3"';
    print('writing metadata');
    print(command);
    FFmpegKit.execute(command);
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
