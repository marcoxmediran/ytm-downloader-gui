import 'package:flutter/material.dart';
import 'downloader.dart';

Future<dynamic> showDownloadForm(
    BuildContext context, String id, SongMetadata metadata) {
  final TextEditingController songTitleController = TextEditingController();
  final TextEditingController songArtistController = TextEditingController();
  final TextEditingController songAlbumController = TextEditingController();
  final TextEditingController songDateController = TextEditingController();
  final TextEditingController downloadPathController = TextEditingController();
  final formKey = GlobalKey<FormState>();
  const formGaps = 16.0;
  return showModalBottomSheet(
    useSafeArea: true,
    isScrollControlled: true,
    context: context,
    builder: (BuildContext context) {
      songTitleController.text = metadata.title;
      songArtistController.text = metadata.artist;
      songAlbumController.text = metadata.album;
      songDateController.text = metadata.date;
      downloadPathController.text = '/storage/emulated/0/Music';
      return SingleChildScrollView(
        padding: EdgeInsets.only(
          left: 24.0,
          right: 24.0,
          top: 32.0,
          bottom: MediaQuery.of(context).viewInsets.bottom + 64.0,
        ),
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Center(
                  child: Image.network(
                      'https://i.ytimg.com/vi/$id/maxresdefault.jpg')),
              const SizedBox(height: formGaps),
              Row(
                children: [
                  Flexible(
                    child: TextFormField(
                      controller: songTitleController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        label: Text('Title'),
                      ),
                    ),
                  ),
                  const SizedBox(width: formGaps),
                  Flexible(
                    child: TextFormField(
                      controller: songArtistController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        label: Text('Artist'),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: formGaps),
              Row(
                children: [
                  Flexible(
                    child: TextFormField(
                      controller: songAlbumController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        label: Text('Album'),
                      ),
                    ),
                  ),
                  const SizedBox(width: formGaps),
                  Flexible(
                    child: TextFormField(
                      controller: songDateController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        label: Text('Date'),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: formGaps),
              TextFormField(
                controller: downloadPathController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  label: Text('Download Location'),
                ),
              ),
              const SizedBox(height: formGaps),
              ElevatedButton(
                onPressed: () async {
                  await Downloader.downloadSong(
                      id, metadata, downloadPathController.text);
                  if (!context.mounted) return;
                  Navigator.of(context).pop();
                },
                child: const Text('Download'),
              )
            ],
          ),
        ),
      );
    },
  );
}
