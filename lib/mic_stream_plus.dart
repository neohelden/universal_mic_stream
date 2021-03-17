import 'dart:async';
import 'dart:typed_data';

import 'package:cross_file/cross_file.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import "package:os_detect/os_detect.dart" as platform;
import 'package:path/path.dart' as p;
import 'package:permission_handler/permission_handler.dart';

const MethodChannel _channel = MethodChannel('mic_stream_plus');
const EventChannel _eventChannel = EventChannel('audio_stream');

/// Provides access to the device microphone stream.
class MicStreamPlus {
  /// Starts recording the microphone input.
  static Future<Stream<Uint8List?>> getMicStream() async {
    var micPermissionGranted = await _checkAndRequestPermission(
      Permission.microphone,
    );

    if (micPermissionGranted) {
      _channel.invokeMethod('startRecording');

      var stream = _eventChannel
          .receiveBroadcastStream()
          .map<Uint8List?>((event) => event);

      return stream;
    } else {
      return Future.error("Mic permission is missing");
    }
  }

  /// Starts recording the microphone input to a file with the given [path]
  /// and [name].
  ///
  /// The [path] must not include the file [name]!
  static Future<XFile> startRecordingToFile({
    required String path,
    required String name,
  }) async {
    var completer = Completer<XFile>();

    var micPermissionGranted = await _checkAndRequestPermission(
      Permission.microphone,
    );

    var storagePermission = await _checkAndRequestPermission(
      Permission.storage,
    );

    if (micPermissionGranted && storagePermission) {
      _channel.invokeMethod('startRecording');

      var stream = _eventChannel
          .receiveBroadcastStream()
          .map<Uint8List?>((event) => event);

      var completeDataStream = <int>[];
      stream.listen((value) {
        completeDataStream.addAll(value!);
      }, onDone: () async {
        debugPrint("Start writing file...");
        var file = await _writeWavFile(
          data: completeDataStream,
          path: path,
          name: name,
        );
        var length = await file.length();
        debugPrint("Created WAV File with path: ${file.path}, size: $length");
        completer.complete(file);
      }, onError: (error) {
        debugPrint("Error in input Stream. Cant write file: $path");
        return completer.completeError(error);
      });
      return completer.future;
    }
    return Future.error("Permissions are missing. Permission status Mic:"
        " $micPermissionGranted, Storage: $storagePermission.");
  }

  /// Stops the current recording and flushes the recorded file.
  static Future<void> stopRecording() async {
    return await _channel.invokeMethod('stopRecording');
  }

  static Future<bool> _checkAndRequestPermission(Permission permission) async {
    if (!platform.isBrowser && (platform.isAndroid || platform.isIOS)) {
      var permissionStatus = await permission.status;
      if (permissionStatus != PermissionStatus.granted) {
        permissionStatus = await permission.request();
      }

      return permissionStatus == PermissionStatus.granted;
    }

    return true;
  }

  static Future<XFile> _writeWavFile({
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
}
