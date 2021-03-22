import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/services.dart';

import 'mic_stream_plus_platform_interface.dart';

const MethodChannel _channel = MethodChannel('neohelden.com/mic_stream_plus');

/// An implementation of [MicStreamPlusPlatform] that uses method channels.
class MethodChannelMicStreamPlus extends MicStreamPlusPlatform {

  @override
  Future<Stream<Uint8List?>?> startRecording() async {
    return _channel.invokeMethod<Stream<Uint8List?>>(
      'startRecording',
    );
  }

  @override
  Future<void> stopRecording() async {
    return await _channel.invokeMethod<void>('stopRecording');
  }
}

