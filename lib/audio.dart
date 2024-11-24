import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:path/path.dart' as p;
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:videoplayer/audioplayer.dart';
import 'package:videoplayer/main.dart';

class AudioList extends StatefulWidget {
  const AudioList({Key? key}) : super(key: key);

  @override
  State<AudioList> createState() => _AudioListState();
}

class _AudioListState extends State<AudioList> {
  bool isScanning = true;
  @override
  void initState() {
    audiorefresh_times += 1;
    super.initState();
    if (audiorefresh_times <= 1) {
      _loadPersistedAudio();
    } else {
      isScanning = false;

      print('Audio Files already loaded no need for reload');
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Scaffold(
      body: isScanning
          ? Center(
              child: SpinKitCircle(
                color: Colors.orange,
                size: 50.0,
              ),
            )
          : audioFiles.isNotEmpty && isScanning == false
              ? ListView.builder(
                  itemCount: audioFiles.length,
                  cacheExtent: 1000,
                  itemBuilder: (context, index) {
                    final audio = audioFiles[index];
                    return ListTile(
                      visualDensity: VisualDensity(vertical: 2),
                      contentPadding: const EdgeInsets.all(2),
                      leading: const Icon(
                        Icons.queue_music_outlined,
                        color: Color(0xFFC7C7C7),
                        size: 30,
                      ),
                      title: Text(
                        p.basenameWithoutExtension(audio.path),
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFFC7C7C7),
                        ),
                      ),
                      trailing: PopupMenuButton<String>(
                        color: Colors.black,
                        onSelected: (value) {
                          if (value == 'Play') {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AudioPlay(audio.path),
                              ),
                            );
                          } else if (value == 'Delete') {
                            deleteaudio(audio.path, index);
                            setState(() {});
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'Play',
                            child: Text(
                              'Play',
                              style: TextStyle(
                                  fontSize: 14, color: Color(0xFFC7C7C7)),
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'Delete',
                            child: Text('Delete',
                                style: TextStyle(
                                    fontSize: 14, color: Color(0xFFC7C7C7))),
                          ),
                        ],
                        icon: const Icon(Icons.more_vert, color: Colors.white),
                      ),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AudioPlay(audio.path),
                        ),
                      ),
                    );
                  },
                )
              : const Center(child: Text('No Audio File found')),
      floatingActionButton: FloatingActionButton(
        onPressed: _refreshAudios,
        backgroundColor: const Color.fromARGB(204, 255, 153, 0),
        child: const Icon(Icons.refresh),
      ),
    ));
  }

  void deleteaudio(String path, int index) async {
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
      setState(() {
        audioFiles.removeAt(index);
      });
    }
  }

  Future<void> _requestStoragePermission() async {
    final status = await Permission.manageExternalStorage.request();
    if (status.isGranted) {
      _scanInternalStorageForAudios();
    } else {
      print('Storage permission denied');
      showDialog(
          context: context,
          builder: (context) => AlertDialog(
              content: Text(
                  "App cannot function properly without this permission")));
    }
  }

  Future<void> _refreshAudios() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('audioPaths');
    setState(() {
      audioFiles.clear();
    });
    _scanInternalStorageForAudios();
  }

  Future<void> _scanInternalStorageForAudios() async {
    if (audioFiles.isNotEmpty) {
      return;
    }

    try {
      Directory rootDirectory = Directory('/storage/emulated/0');
      List<File> tempAudioFiles =
          await _getAllAudioFilesInDirectory(rootDirectory);

      tempAudioFiles
          .sort((a, b) => p.basename(a.path).compareTo(p.basename(b.path)));

      await _saveAudioPathsToStorage(tempAudioFiles);

      if (mounted) {
        setState(() {
          audioFiles = tempAudioFiles;
          isScanning = false;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error scanning internal storage.')),
      );
      print('Error scanning internal storage: $e');
    }
  }

  Future<List<File>> _getAllAudioFilesInDirectory(Directory directory) async {
    List<File> foundAudioFiles = [];
    List<FileSystemEntity> entities;

    try {
      entities = directory.listSync(recursive: false, followLinks: false);
    } catch (e) {
      print('Error reading directory: $e');
      return [];
    }

    for (var entity in entities) {
      if (entity is Directory) {
        foundAudioFiles.addAll(await _getAllAudioFilesInDirectory(entity));
      } else if (entity is File &&
          (entity.path.toLowerCase().endsWith('.mp3') ||
              entity.path.toLowerCase().endsWith('.m4a'))) {
        foundAudioFiles.add(entity);
      } else if (entity.path.contains('/Android/')) {
        continue;
      }
    }
    return foundAudioFiles;
  }

  Future<void> _saveAudioPathsToStorage(List<File> audioFiles) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> paths = audioFiles.map((file) => file.path).toList();
    await prefs.setStringList('audioPaths', paths);
  }

  Future<void> _loadPersistedAudio() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? audioPaths = prefs.getStringList('audioPaths');

    if (audioPaths != null && audioPaths.isNotEmpty) {
      setState(() {
        audioFiles = audioPaths.map((path) => File(path)).toList();
        isScanning = false;
      });
    } else {
      _requestStoragePermission();

      setState(() {});
    }
  }
}
