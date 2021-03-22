# mic_stream_plus_platform_interface
A common platform interface for the mic_stream_plus plugin.

This interface allows platform-specific implementations of the [mic_stream_plus](https://github.com/neohelden/mic_stream_plus) plugin, as well as the plugin itself, to ensure they are supporting the same interface.

## Usage
To implement a new platform-specific implementation of mic_stream_plus, extend MicStreamPlusPlatform with an implementation that performs the platform-specific behavior, and when you register your plugin, set the default MicStreamPlusPlatform by calling MicStreamPlusPlatform.instance = MyMicStreamPlusPlatform().