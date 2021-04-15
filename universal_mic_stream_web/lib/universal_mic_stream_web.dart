import 'dart:async';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'dart:typed_data';
import 'package:meta/meta.dart';
import 'dart:html';
import 'dart:js';
import 'package:http/http.dart' as http;
import 'dart:web_audio';
import 'dart:math' as Math;
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

    final perm = await window.navigator.permissions!.query(
        {"name": "microphone"});
    if (perm.state == "denied") {
      return Future.error("error");
    } else {
      _isRecording = true;

      _streamController = StreamController<Uint8List?>();

      mediaStream =
      await window.navigator.getUserMedia(audio: true, video: false);

      const inputChannels = 1;
      const outputChannels = 1;
      const bufferSize = 4096;
      var audioContext = AudioContext();
      var sampleRate = audioContext.sampleRate as int;
      print("SampleRate: ${audioContext.sampleRate}");
      recorder = audioContext.createScriptProcessor(
          bufferSize, inputChannels, outputChannels);
      recorder!.connectNode(audioContext.destination!);
      // setStream
      audioInput = audioContext.createMediaStreamSource(mediaStream!);
      audioInput!.connectNode(recorder!);
      recorder!.onAudioProcess.listen((AudioProcessingEvent e) {
        var source = e.inputBuffer!.getChannelData(0);
        var downSampled = resample(
            buffer: source, srcSampleRate: sampleRate, destSampleRate: 16000);

        var bytes = downSampled.buffer.asUint8List();

        _streamController?.add(bytes);
      });

      return _streamController!.stream;
    }
  }

  Float32List resample({required Float32List buffer,
    required int srcSampleRate,
    required int destSampleRate,
      }) {
    print("Resample from $srcSampleRate to $destSampleRate");

    var sampleRateRatio = srcSampleRate / destSampleRate;
    var length = (buffer.length / sampleRateRatio).round();
    var result = Float32List(length);
    var offsetResult = 0;
    var offsetBuffer = 0;

    while (offsetResult < result.length) {
      var nextOffsetBuffer = ((offsetResult + 1) * sampleRateRatio).round();
      var accum = 0.0;
      var count = 0;
      for (var i = offsetBuffer; i < nextOffsetBuffer &&
          i < buffer.length; i++) {
        accum += buffer[i];
        ++count;
      }

      result[offsetResult] = (Math.min(1, accum / count) * 0x7FFF);
      ++offsetResult;
      offsetBuffer = nextOffsetBuffer;
    }

    print("Buffer: $buffer \nResult: $result");

    return result;
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