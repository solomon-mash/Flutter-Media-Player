import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:videoplayer/audio.dart';
import 'package:videoplayer/browse.dart';
import 'package:videoplayer/home.dart';
import 'package:videoplayer/video.dart';

import 'package:flutter_native_splash/flutter_native_splash.dart';

List<File> videoFiles = [];
List<File> audioFiles = [];
Map<String, String> thumbnails = {}; // Map to store video paths and thumbnails

var refresh_times = 0;

var audiorefresh_times = 0;

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  runApp(const MyApp());
  FlutterNativeSplash.remove();
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Color(0xFF131313), // Set status bar color
      systemNavigationBarColor: Color(0xFF131313),
      systemNavigationBarIconBrightness:
          Brightness.light, // Set navigation bar icons' brightness
    ));
    return MaterialApp(
      color: Color(0xFF131313),
      title: 'Video Player',
      theme: ThemeData(
          scaffoldBackgroundColor: Color(0xFF131313),
          primarySwatch: Colors.grey),
      home: homepage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class homepage extends StatefulWidget {
  const homepage({super.key});

  @override
  State<homepage> createState() => _homepageState();
}

var test;

class _homepageState extends State<homepage> {
  var page_index = 0;
  final page_list = [
    VideoListPage(),
    AudioList(),
    BrowseView(),
    morepage(),
  ];
  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Scaffold(
      backgroundColor: Color(0xFF131313),
      appBar: AppBar(
        shadowColor: Color(0xFF131313),
        surfaceTintColor: Color(0xFF131313),
        title: Text('Video Player', style: TextStyle(color: Color(0xFFC7C7C7))),
        backgroundColor: Color(0xFF131313),
      ),
      body: page_list[page_index],
      bottomNavigationBar: BottomAppBar(
          color: Color(0xFF131313),
          height: 90,
          surfaceTintColor: Color(0xFF131313),
          child:
              Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
            Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                direction: Axis.vertical,
                children: [
                  IconButton(
                      onPressed: () {
                        setState(() {
                          page_index = 0;
                        });
                      },
                      icon: page_index == 0
                          ? const Icon(
                              Icons.video_collection,
                              color: Colors.orange,
                              size: 18,
                            )
                          : const Icon(
                              Icons.video_collection,
                              color: Color(0xFFC7C7C7),
                              size: 18,
                            )),
                  const Text(
                    'Video',
                    style: TextStyle(color: Color(0xFFC7C7C7)),
                  )
                ]),
            Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                direction: Axis.vertical,
                children: [
                  IconButton(
                      onPressed: () {
                        setState(() {
                          page_index = 1;
                        });
                      },
                      icon: page_index == 1
                          ? const Icon(
                              Icons.audiotrack,
                              color: Colors.orange,
                              size: 18,
                            )
                          : const Icon(
                              Icons.audiotrack,
                              color: Color(0xFFC7C7C7),
                              size: 18,
                            )),
                  const Text(
                    'Audio',
                    style: TextStyle(color: Color(0xFFC7C7C7)),
                  )
                ]),
            Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                direction: Axis.vertical,
                children: [
                  IconButton(
                      onPressed: () {
                        setState(() {
                          page_index = 2;
                        });
                      },
                      icon: page_index == 2
                          ? const Icon(
                              Icons.file_open,
                              color: Colors.orange,
                              size: 18,
                            )
                          : const Icon(
                              Icons.file_open,
                              color: Color(0xFFC7C7C7),
                              size: 18,
                            )),
                  const Text(
                    'Browse',
                    style: TextStyle(color: Colors.white),
                  )
                ]),
            Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                direction: Axis.vertical,
                children: [
                  IconButton(
                      onPressed: () {
                        setState(() {
                          page_index = 3;
                        });
                      },
                      icon: page_index == 3
                          ? const Icon(
                              Icons.more_horiz,
                              color: Colors.orange,
                              size: 18,
                            )
                          : const Icon(Icons.more_horiz,
                              color: Color(0xFFC7C7C7), size: 18)),
                  const Text(
                    'More',
                    style: TextStyle(color: Color(0xFFC7C7C7)),
                  )
                ]),
          ])),
    ));
  }
}
