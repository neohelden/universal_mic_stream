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

  MediaRecorder? _mediaRecorder;
  StreamController<Uint8List?>? _streamController;
  ScriptProcessorNode? recorder;
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
      var stream = await window.navigator.getUserMedia(audio: true, video: false);

      /* var audioContext = AudioContext();
      var analyser = audioContext.createAnalyser();
      audioContext.createMediaStreamSource(stream);
      var bufferLength = analyser.frequencyBinCount;
      var dataArray = Uint8List(bufferLength!);
      analyser.getByteTimeDomainData(dataArray);

      _mediaRecorder = MediaRecorder(stream, {
        'audioBitsPerSecond' : 16000,
      });
      _mediaRecorder!.addEventListener("dataavailable", (event) async {*/



       /* // Retreive audio data chunks from js object then
        // Convert it to a single audio data blob
        Blob blob = JsObject.fromBrowserObject(event)['data'];

        // Create a URL for that single audio data blob
        final audioUrl = Url.createObjectUrl(blob);

        FileReader reader = FileReader();
        // Convert the blob to a flutter readable object Uint8List
        reader.readAsArrayBuffer(blob);

        reader.onLoadEnd.listen((event) async {
          if (!(_streamController?.isClosed ?? true)) {
            print("add data");
            print(reader.result as Uint8List);
            _streamController?.add(reader.result as Uint8List);
          }
        });*/

     /*   final blobEvent = event as BlobEvent;
        var blob = blobEvent.data;
        print(blob!.type);
        var url = Url.createObjectUrl(blob);
        var path = url.substring(5);
        var uri = Uri(path: path);
        final result = await http.get(uri);
        var bytes = result.bodyBytes;
        if (!(_streamController?.isClosed ?? true)) {
          print("add data");
          print(bytes);
          _streamController?.add(bytes);
        }*/
    /*  });*/

      const inputChannels = 1;
      const outputChannels = 1;
      const bufferSize = 4096;
      var audioContext = AudioContext();
      recorder = audioContext.createScriptProcessor(bufferSize, inputChannels, outputChannels);
      recorder!.connectNode(audioContext.destination!);
      // setStream
      var audioInput = audioContext.createMediaStreamSource(stream);
      audioInput.connectNode(recorder!);
      recorder!.onAudioProcess.listen((AudioProcessingEvent e) {
        print(e.inputBuffer?.getChannelData(0));
        var floa = e.inputBuffer?.getChannelData(0);
        var bytes = floa!.buffer.asUint8List();
        _streamController?.add(bytes);
      });

     /* _mediaRecorder!.addEventListener('stop', (event) async {
          _streamController?.close();
          _isRecording = false;
      });

      _mediaRecorder!.start(100);*/

      return _streamController!.stream;
    }
  }

  @override
  Future<void> stopRecording() async {
    print("Stop recording");
    //_mediaRecorder?.stop();
    recorder?.disconnect();
    _streamController?.close();
    print("Recording stopped");
  }
}