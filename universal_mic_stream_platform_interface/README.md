# universal_mic_stream_platform_interface
A common platform interface for the universal_mic_stream plugin.

This interface allows platform-specific implementations of the [universal_mic_stream](https://github.com/neohelden/universal_mic_stream) plugin, as well as the plugin itself, to ensure they are supporting the same interface.

## Usage
To implement a new platform-specific implementation of universal_mic_stream, extend UniversalMicStreamPlatform with an implementation that performs the platform-specific behavior, and when you register your plugin, set the default UniversalMicStreamPlatform by calling UniversalMicStreamPlatform.instance = MyUniversalMicStreamPlatform().