import 'dart:async';
import 'dart:typed_data';

import 'package:cross_file/cross_file.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:mic_stream_plus_platform_interface/mic_stream_plus_platform_interface.dart';
import 'package:path/path.dart' as p;
import 'package:permission_handler/permission_handler.dart';

const EventChannel _eventChannel = EventChannel('neohelden/com.audio_stream');

/// Starts recording the microphone input.
Future<Stream<Uint8List?>?> startRecording() async {
  if ((await Permission.microphone.request()) == PermissionStatus.granted) {
    MicStreamPlusPlatform.instance.startRecording();

    var stream = _eventChannel
        .receiveBroadcastStream()
        .map<Uint8List?>((event) => event);

    return stream;
  } else {
    return Future.error("Mic permission is missing");
  }
}

/// Stops the current recording and flushes the recorded file.
Future<void> stopRecording() async {
  return await MicStreamPlusPlatform.instance.stopRecording();
}

/// Starts recording the microphone input to a file with the given [path]
/// and [name].
///
/// The [path] must not include the file [name]!
Future<XFile> startRecordingToFile({
  required String path,
  required String name,
}) async {
  if ((await Permission.storage.request()) == PermissionStatus.granted) {
    var completer = Completer<XFile>();

    var stream = await startRecording();

    var completeDataStream = <int>[];
    stream!.listen((value) {
      completeDataStream.addAll(value!);
    }, onDone: () async {
      debugPrint("Start writing file...");
      XFile? file;
      if (kIsWeb) {
        file = XFile.fromData(Uint8List.fromList(completeDataStream));
      } else {
        file = await _writeWavFile(
          data: completeDataStream,
          path: path,
          name: name,
        );
        var length = await file.length();
        debugPrint("Created WAV File with path: ${file.path}, size: $length");
      }
      completer.complete(file);
    }, onError: (error) {
      debugPrint("Error in input Stream. Cant write file: $path");
      return completer.completeError(error);
    });

    return completer.future;
  } else {
    return Future.error("Storage permission is missing");
  }
}

Future<XFile> _writeWavFile({
  required List<int> data,
  required String path,
  required String name,
}) async {
  var subChunk2Size = data.length;
  var subChunk1Size = 16;
  var numChannels = 1;
  var sampleRate = 16000;
  var byteRate = sampleRate * numChannels * 2;
  var fileSize = 4 + (8 + subChunk1Size) + (8 + subChunk2Size);

  var dataWithHeader = Uint8List.fromList([
    // "RIFF"
    82, 73, 70, 70,
    fileSize & 0xff,
    (fileSize >> 8) & 0xff,
    (fileSize >> 16) & 0xff,
    (fileSize >> 24) & 0xff,
    // WAVE
    87, 65, 86, 69,
    // fmt
    102, 109, 116, 32,
    // fmt chunk size 16
    16, 0, 0, 0,
    // Type of format
    1, 0,
    // One channel
    numChannels, 0,
    // Sample rate
    sampleRate & 0xff,
    (sampleRate >> 8) & 0xff,
    (sampleRate >> 16) & 0xff,
    (sampleRate >> 24) & 0xff,
    // Byte rate
    byteRate & 0xff,
    (byteRate >> 8) & 0xff,
    (byteRate >> 16) & 0xff,
    (byteRate >> 24) & 0xff,
    // Uhm
    2, 0, // (chunkSize * numChannels) >> 3, 0,
    // bitsize
    subChunk1Size, 0,
    // "data"
    100, 97, 116, 97,
    subChunk2Size & 0xff,
    (subChunk2Size >> 8) & 0xff,
    (subChunk2Size >> 16) & 0xff,
    (subChunk2Size >> 24) & 0xff,
    ...data
  ]);

  var file = XFile.fromData(
    dataWithHeader,
    path: p.join(path, name),
    name: name,
    mimeType: "wav",
  );

  return file;
}
