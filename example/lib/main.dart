import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mic_stream_plus/mic_stream_plus.dart';
import "package:os_detect/os_detect.dart" as platform;
import 'package:path_provider/path_provider.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _platformVersion = 'Unknown';
  String _buttonText = "Record to File";
  String _button2Text = "Record as Stream";
  String _filename = "test.wav";
  var completeDataStream = <int>[];

  late TextEditingController filenameTextController;

  @override
  void initState() {
    super.initState();
    initPlatformState();
    filenameTextController = TextEditingController(text: _filename);
    filenameTextController.addListener(() {
      _filename = filenameTextController.text;
    });
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;
  }

  @override
  void dispose() {
    filenameTextController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var startByte = completeDataStream.length - 100;
    if (startByte < 0) {
      startByte = 0;
    }

    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Record Sample'),
        ),
        body: Center(
          child: Column(
            children: [
              Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: Text("Change the file name:"),
                  ),
                  Expanded(
                    child: TextField(controller: filenameTextController),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      if (_buttonText == "Record to File") {
                        _buttonText = "Stop Record";
                        getDownloadStoragePath().then((path) async {
                          if (_filename.isEmpty) _filename = "test.wav";
                          if (!_filename.endsWith(".wav")) _filename += ".wav";

                          filenameTextController.text = _filename;

                          debugPrint("Recording to file: $path/$_filename");

                          var file = await MicStreamPlus.startRecordingToFile(
                            path: path,
                            name: _filename,
                          );

                          // Save the file on the file system
                          file.saveTo(file.path);
                        });
                      } else {
                        _buttonText = "Record to File";
                        MicStreamPlus.stopRecording();
                      }
                    });
                  },
                  child: Text(
                    _buttonText,
                    style: TextStyle(fontSize: 20.0),
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (_button2Text == "Record as Stream") {
                    setState(() {
                      _button2Text = "Stop Record";
                    });
                    (await MicStreamPlus.getMicStream()).listen((value) {
                      if (value != null) {
                        setState(() {
                          completeDataStream.addAll(value);
                        });
                      }
                    }, onDone: () {
                      debugPrint("Stream ended!");
                    }, onError: (err) {
                      debugPrint(err);
                    });
                  } else {
                    setState(() {
                      _button2Text = "Record as Stream";
                    });
                    MicStreamPlus.stopRecording();
                  }
                },
                child: Text(
                  _button2Text,
                  style: TextStyle(fontSize: 20.0),
                ),
              ),
              Text("Last 100 Bytes: ${completeDataStream.getRange(
                startByte,
                completeDataStream.length,
              )}"),
            ],
          ),
        ),
      ),
    );
  }

  Future<String> getDownloadStoragePath() async {
    String dataPath = "";
    if (platform.isIOS) {
      dataPath = (await getApplicationDocumentsDirectory()).path;
    } else if (platform.isAndroid) {
      dataPath = "/sdcard/Download";
    } else if (platform.isMacOS) {
      dataPath = (await getDownloadsDirectory())!.path;
    } else {
      throw UnsupportedError(
          "Platform ${platform.operatingSystem} not supported!");
    }
    return dataPath;
  }
}
