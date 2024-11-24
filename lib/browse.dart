import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:videoplayer/audioplayer.dart';
import 'package:videoplayer/videoplayer.dart';

class BrowseView extends StatefulWidget {
  const BrowseView({super.key});

  @override
  State<BrowseView> createState() => _BrowseViewState();
}

class _BrowseViewState extends State<BrowseView> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Scaffold(
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 10),
            Padding(
                padding: EdgeInsets.only(left: 8.0),
                child: Text('Internal Storage',
                    style: TextStyle(
                        color: Colors.deepOrangeAccent, fontSize: 22))),
            SizedBox(height: 15),
            Padding(
                padding: EdgeInsets.only(left: 5.0),
                child: DecoratedBox(
                    child: Card(
                      color: Colors.black38,
                      borderOnForeground: false,
                      child: SizedBox(
                        height: 125,
                        width: 130,
                        child: Center(
                          child: Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            direction: Axis.vertical,
                            children: [
                              IconButton(
                                onPressed: () async {
                                  await selectAndStoreMedia(context);
                                },
                                icon: const Icon(
                                  Icons.folder,
                                  color: Colors.white60,
                                  size: 60,
                                ),
                              ),
                              const Text(
                                'Browse Files',
                                style: TextStyle(color: Colors.white),
                              )
                            ],
                          ),
                        ),
                      ),
                    ),
                    decoration: BoxDecoration(
                        border: Border.all(color: Colors.white30))))
          ],
        ),
      ),
    ));
  }

  Future<void> requestStoragePermission() async {
    final status = await Permission.storage.request();
    if (!status.isGranted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          content: const Text(
              "App cannot function properly without storage permission."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK"),
            ),
          ],
        ),
      );
    }
  }

  Future<void> selectAndStoreMedia(BuildContext context) async {
    await requestStoragePermission();

    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.any,
      allowMultiple: false,
    );

    if (result != null && result.files.single.path != null) {
      final path = result.files.single.path!;
      final extension = path.split('.').last.toLowerCase();

      if (extension == 'mp3' || extension == 'm4a') {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AudioPlay(path),
          ),
        );
      } else if (extension == 'mp4' || extension == 'mkv') {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VideoPlay(path),
          ),
        );
      } else {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            content: const Text("App does not support the file extension used"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("OK"),
              ),
            ],
          ),
        );
      }
    }
  }
}
