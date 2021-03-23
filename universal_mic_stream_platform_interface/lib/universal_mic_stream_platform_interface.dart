import 'dart:async';

import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'method_channel_universal_mic_stream.dart';
import 'method_channel_universal_mic_stream.dart';

import 'dart:typed_data';


/// The interface that implementations of universal_mic_stream must implement.
///
/// Platform implementations should extend this class rather than implement it as `universal_mic_stream`
/// does not consider newly added methods to be breaking changes. Extending this class
/// (using `extends`) ensures that the subclass will get the default implementation, while
/// platform implementations that `implements` this interface will be broken by newly added
/// [UniversalMicStreamPlatform] methods.
abstract class UniversalMicStreamPlatform extends PlatformInterface {
  /// Constructs a UniversalMicStreamPlatform.
  UniversalMicStreamPlatform() : super(token: _token);

  static final Object _token = Object();

  static UniversalMicStreamPlatform _instance = MethodChannelUniversalMicStream();

  /// The default instance of [UniversalMicStreamPlatform] to use.
  ///
  /// Defaults to [MethodChannelUniversalMicStream].
  static UniversalMicStreamPlatform get instance => _instance;

  /// Platform-specific plugins should set this with their own platform-specific
  /// class that extends [UniversalMicStreamPlatform] when they register themselves.
  static set instance(UniversalMicStreamPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  /// Starts recording the microphone input and returns it as a Uint8List stream.
  Future<Stream<Uint8List?>?> startRecording() async {
    throw UnimplementedError('startRecording() has not been implemented.');
  }

  /// Stops the current recording and flushes the recorded file.
  Future<void> stopRecording() async {
    throw UnimplementedError('stopRecording() has not been implemented.');
  }
}