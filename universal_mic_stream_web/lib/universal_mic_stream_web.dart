import 'dart:async';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'dart:typed_data';
import 'package:meta/meta.dart';
import 'dart:html';
import 'dart:js';
import 'package:http/http.dart' as http;
import 'dart:web_audio';
import 'package:universal_mic_stream_platform_interface/universal_mic_stream_platform_interface.dart';

class UniversalMicStreamPlugin extends UniversalMicStreamPlatform {

  StreamController<Uint8List?>? _streamController;
  ScriptProcessorNode? recorder;
  MediaStreamAudioSourceNode? audioInput;
  MediaStream? mediaStream;
  bool _isRecording = false;

  /// Registers this class as the default instance of [UniversalMicStreamPlatform].
  static void registerWith(Registrar registrar) {
    UniversalMicStreamPlatform.instance = UniversalMicStreamPlugin();
  }

  @override
  Future<Stream<Uint8List?>?> startRecording() async {
    if (_isRecording) {
      return Future.error(("Recording is already running"));
    }

    final perm = await window.navigator.permissions!.query({"name": "microphone"});
    if (perm.state == "denied") {
      return Future.error("error");
    } else {
      _isRecording = true;

      _streamController = StreamController<Uint8List?>();

      mediaStream = await window.navigator.getUserMedia(audio: true, video: false);

      const inputChannels = 1;
      const outputChannels = 1;
      const bufferSize = 4096;
      var audioContext = AudioContext();
      recorder = audioContext.createScriptProcessor(bufferSize, inputChannels, outputChannels);
      recorder!.connectNode(audioContext.destination!);
      // setStream
      audioInput = audioContext.createMediaStreamSource(mediaStream!);
      audioInput!.connectNode(recorder!);
      recorder!.onAudioProcess.listen((AudioProcessingEvent e) {
        print(e.inputBuffer?.getChannelData(0));
        var floa = e.inputBuffer?.getChannelData(0);
        var bytes = floa!.buffer.asUint8List();
        _streamController?.add(bytes);
      });

      return _streamController!.stream;
    }
  }

  @override
  Future<void> stopRecording() async {
    print("Stop recording");
    recorder?.disconnect();
    recorder = null;
    _streamController?.close();
    audioInput?.disconnect();
    if (mediaStream != null) {
      List<MediaStreamTrack> mediaTracks = mediaStream!.getTracks();
      if (mediaTracks != null) {
        for (MediaStreamTrack track in mediaTracks) {
          track.stop();
        }
      }
      mediaStream = null;
    }
    _isRecording = false;
    print("Recording stopped");
  }
}