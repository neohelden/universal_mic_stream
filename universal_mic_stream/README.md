# universal_mic_stream

Static functions for accessing the microphone cross-platform with ease.

Currently, **universal_mic_stream** works on **iOS**, **Android** and **MacOS**, with Web support planned for the near future.

The plugin is currently hard set to the following audio config:

- **SampleRate:** 16 KHz
- **Channels**: Mono
- **ByteRate**: 32 kbit/s

## Usage

So how to use **universal_mic_stream**? Actually it's pretty easy, just start it by calling the static method `UniversalMicStream.startRecording()` and stop it with `UniversalMicStream.stopRecording()`**.** 

```dart
var stream = await UniversalMicStream.startRecording();

// When finished call:
UniversalMicStream.stopRecording();
```

You want to get a file of the recorded stream, then use the `UniversalMicStream.startRecordingToFile()` methode.

```dart
// Define the path of the file e.g.
var path = await getDownloadStoragePath();

var file = await UniversalMicStream.startRecordingToFile(
	path: path,
	name:"test.wav",
);

// When finished call:
UniversalMicStream.stopRecording();

// Writing the file to the file system
file.saveTo(file.path);
```

## Project Setup

Accessing the microphone doesn't work without explicit permission by the user. Therefor you have to configure your project for the individual operating systems.

### Android

- [ ]  Add the `RECORD_AUDIO` permission to your AndroidManifest.xml:

```xml
<uses-permission android:name="android.permission.RECORD_AUDIO" />
```

### iOS

- [ ]  You will need at least iOS 9.0 to makes usage of this plugin. So set your deployment target to 9.0 or higher.
- [ ]  Add the following entry to your Info.plist:

```xml
<key>NSMicrophoneUsageDescription</key>
<string>Audio Input from Microphone</string>
```

### MacOS

- [ ]  Add the following entry to your Info.plist:

```xml
<key>NSMicrophoneUsageDescription</key>
<string>Audio Input from Microphone</string>
```

- [ ]  Enable audio input at the hardware features. Therefor open your project in XCode, select the desired target and on the **Signing & Capabilities**-Tab. In the **App Sandbox** section select **Hardware** -> **Audio Input**.

## Constribution

**universal_mic_stream** is maintained by [Neohelden GmbH]([https://neohelden.com/](https://neohelden.com/) ). Because Flutter has no native access to the microphone we want to make it accessible for everyone and everywhere. We highly appreciate pull requests to make on microphone plugin to rule them all.

Happy Coding :D
