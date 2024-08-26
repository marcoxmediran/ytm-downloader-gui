import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_sharing_intent/model/sharing_file.dart';
import 'package:ytm_downloader_gui/downloader.dart';
import 'package:flutter_sharing_intent/flutter_sharing_intent.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final downloader = Downloader();

  final TextEditingController _linkController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  late StreamSubscription _intentDataStreamSubscription;

  @override
  void initState() {
    initSharingListener();
    super.initState();
  }

  @override
  void dispose() {
    _intentDataStreamSubscription.cancel();
    super.dispose();
  }

  initSharingListener() {
    _intentDataStreamSubscription = FlutterSharingIntent.instance
        .getMediaStream()
        .listen((List<SharedFile> value) {
      if (value.isNotEmpty) {
        var link = value.map((f) => f.value).join(',');
        if (downloader.isValidLink(link)) {
          _linkController.text = link;
          downloader.download(downloader.getId(link));
        }
      }
    });

    FlutterSharingIntent.instance
        .getInitialSharing()
        .then((List<SharedFile> value) {
      if (value.isNotEmpty) {
        var link = value.map((f) => f.value).join(",");
        if (downloader.isValidLink(link)) {
          _linkController.text = link;
          downloader.download(downloader.getId(link));
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            child: const Icon(Icons.download_outlined),
            onPressed: () async {
              String link = _linkController.text;
              if (downloader.isValidLink(link)) {
                String id = downloader.getId(link);
                if (!context.mounted) return;
                downloader.download(id);
              }
            },
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          const SliverAppBar.large(
            title: Text('YouTube Music Downloader'),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Form(
                    key: _formKey,
                    child: TextFormField(
                      controller: _linkController,
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        label: const Text('Music Link'),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => _linkController.text = '',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
