import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/services.dart';

import 'universal_mic_stream_platform_interface.dart';

const MethodChannel _channel = MethodChannel('neohelden.com/universal_mic_stream');

/// An implementation of [UniversalMicStreamPlatform] that uses method channels.
class MethodChannelUniversalMicStream extends UniversalMicStreamPlatform {

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

