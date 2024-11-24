import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path/path.dart' as p;
import 'package:permission_handler/permission_handler.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:videoplayer/main.dart';
import 'package:videoplayer/videoplayer.dart';

class VideoListPage extends StatefulWidget {
  @override
  _VideoListPageState createState() => _VideoListPageState();
}

class _VideoListPageState extends State<VideoListPage> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();

    refresh_times += 1;
    if (refresh_times <= 1) {
      print(refresh_times);
      _requestStoragePermission();
    } else {
      _isLoading = false;
      print("Videos already loaded no need for reload");
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: _isLoading
            ? const Center(
                child: SpinKitCircle(
                  color: Colors.orange,
                  size: 50.0,
                ),
              )
            : videoFiles.isNotEmpty
                ? ListView.builder(
                    itemCount: videoFiles.length,
                    cacheExtent: 1000,
                    itemBuilder: (context, index) {
                      final video = videoFiles[index];
                      return ListTile(
                        visualDensity: VisualDensity(vertical: 4),
                        contentPadding: EdgeInsets.all(3),
                        leading: Container(
                          height: 45,
                          width: 75,
                          child: thumbnails[video.path] != null
                              ? Image.file(File(thumbnails[video.path]!),
                                  fit: BoxFit.fitWidth)
                              : const Icon(Icons.videocam),
                        ),
                        title: Text(
                          p.basenameWithoutExtension(video.path),
                          style: const TextStyle(
                              fontSize: 14, color: Color(0xFFC7C7C7)),
                        ),
                        trailing: PopupMenuButton<String>(
                          color: Color(0xFF131313),
                          onSelected: (value) {
                            if (value == 'Play') {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => VideoPlay(video.path),
                                ),
                              );
                            } else if (value == 'Delete') {
                              deleteVideo(video.path, index);
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'Play',
                              child: Text('Play',
                                  style: TextStyle(color: Color(0xFFC7C7C7))),
                            ),
                            const PopupMenuItem(
                              value: 'Delete',
                              child: Text('Delete',
                                  style: TextStyle(color: Color(0xFFC7C7C7))),
                            ),
                          ],
                          icon: const Icon(Icons.more_vert,
                              color: Color(0xFFC7C7C7)),
                        ),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: ((context) => VideoPlay(video.path))),
                        ),
                      );
                    },
                  )
                : const Center(
                    child: Text('No videos found',
                        style: TextStyle(color: Color(0xFFC7C7C7))),
                  ),
        floatingActionButton: FloatingActionButton(
          onPressed: _refreshVideos,
          backgroundColor: const Color.fromARGB(204, 255, 153, 0),
          child: Icon(Icons.refresh),
        ),
      ),
    );
  }

  void deleteVideo(String path, int index) async {
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
      setState(() {
        videoFiles.removeAt(index);
        thumbnails.remove(path);
      });
      SharedPreferences prefs = await SharedPreferences.getInstance();
      prefs.remove(path); // Remove thumbnail path from SharedPreferences
      prefs.setStringList('videoPaths',
          videoFiles.map((file) => file.path).toList()); // Update video list
    }
  }

  Future<void> _requestStoragePermission() async {
    final status = await Permission.manageExternalStorage.request();
    if (status.isGranted) {
      _scanInternalStorageForVideos();
    } else if (status.isDenied) {
      _showPermissionRationale();
    } else if (status.isPermanentlyDenied) {
      _showOpenSettingsDialog();
    }
    ;
  }

  void _showPermissionRationale() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Storage Permission Needed"),
        content: Text(
            "This app requires access to manage your storage to save and load files effectively."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _requestStoragePermission();
            },
            child: Text("Grant Permission"),
          ),
        ],
      ),
    );
  }

  void _showOpenSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Permission Permanently Denied"),
        content: Text(
            "You have permanently denied the storage permission. Please enable it in the app settings to proceed."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: Text("Open Settings"),
          ),
        ],
      ),
    );
  }

  Future<void> _refreshVideos() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    setState(() {
      videoFiles.clear();
      thumbnails.clear();
    });

    _scanInternalStorageForVideos();
  }

  Future<List<File>> _getAllVideoFilesInDirectory(Directory directory) async {
    List<File> videoFiles = [];
    try {
      var entities = directory.listSync(recursive: false, followLinks: false);
      for (var entity in entities) {
        if (entity is Directory) {
          videoFiles.addAll(await _getAllVideoFilesInDirectory(entity));
        } else if (entity is File &&
            (entity.path.toLowerCase().endsWith('.mp4') ||
                entity.path.toLowerCase().endsWith('.mkv'))) {
          videoFiles.add(entity);
        }
      }
    } catch (e) {
      print('Error reading directory: $e');
    }
    return videoFiles;
  }

  Future<void> _saveVideoPathsToStorage(List<File> videoFiles) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> paths = videoFiles.map((file) => file.path).toList();
    await prefs.setStringList('videoPaths', paths);
  }

  Future<void> _saveThumbnailToStorage(
      String videoPath, String thumbnailPath) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(videoPath, thumbnailPath);
  }

  Future<void> _loadPersistedVideos() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? videoPaths = prefs.getStringList('videoPaths');

    setState(() {
      if (videoPaths != null && videoPaths.isNotEmpty) {
        videoFiles = videoPaths.map((path) => File(path)).toList();
        for (String path in videoPaths) {
          String? thumbnailPath = prefs.getString(path);
          if (thumbnailPath != null) {
            thumbnails[path] = thumbnailPath;
          }
        }

        _isLoading = false;
      } else {
        setState(() {});
      }
    });
  }

  Future<String?> getVideoThumbnail(String videoPath) async {
    final tempDir = await getTemporaryDirectory();
    final thumbnailPath = await VideoThumbnail.thumbnailFile(
      video: videoPath,
      thumbnailPath: tempDir.path,
      imageFormat: ImageFormat.JPEG,
      quality: 25,
      timeMs: 8000,
    );
    return thumbnailPath;
  }

  Future<void> _scanInternalStorageForVideos() async {
    try {
      Directory rootDirectory = Directory('/storage/emulated/0');
      List<File> tempVideoFiles =
          await _getAllVideoFilesInDirectory(rootDirectory);

      tempVideoFiles
          .sort((a, b) => p.basename(a.path).compareTo(p.basename(b.path)));

      await _saveVideoPathsToStorage(tempVideoFiles);

      for (File video in tempVideoFiles) {
        final thumbnailPath = await getVideoThumbnail(video.path);
        if (thumbnailPath != null) {
          thumbnails[video.path] = thumbnailPath;
          await _saveThumbnailToStorage(video.path, thumbnailPath);
          if (mounted) setState(() {}); // Update UI with new thumbnails
        }
      }

      if (mounted) {
        setState(() {
          _loadPersistedVideos();
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error reading directory: $e');
    }
  }
}
