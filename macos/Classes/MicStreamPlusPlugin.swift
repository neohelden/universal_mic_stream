import AVFoundation
import Cocoa
import FlutterMacOS

public class MicStreamPlusPlugin: NSObject, FlutterPlugin, FlutterStreamHandler {
    let engine = AVAudioEngine()
    var outputFormat = AVAudioFormat(commonFormat: AVAudioCommonFormat.pcmFormatInt16, sampleRate: 16000, channels: 1, interleaved: false)
    var isRecording = false

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "mic_stream_plus", binaryMessenger: registrar.messenger)
        let eventChannel = FlutterEventChannel(name: "audio_stream", binaryMessenger: registrar.messenger)
        let instance = MicStreamPlusPlugin()
        eventChannel.setStreamHandler(instance)
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "startRecording":
            isRecording = true
            result(nil)
        case "stopRecording":
            isRecording = false
            result(nil)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    public func onListen(withArguments _: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        let input = engine.inputNode
        let bus = 0
        let inputFormat = input.outputFormat(forBus: 0)
        let converter = AVAudioConverter(from: inputFormat, to: outputFormat!)!

        input.installTap(onBus: bus, bufferSize: 1024, format: inputFormat) { (buffer, _) -> Void in
            var newBufferAvailable = true

            let inputCallback: AVAudioConverterInputBlock = { _, outStatus in
                if newBufferAvailable {
                    outStatus.pointee = .haveData
                    newBufferAvailable = false
                    return buffer
                } else {
                    outStatus.pointee = .noDataNow
                    return nil
                }
            }

            let convertedBuffer = AVAudioPCMBuffer(pcmFormat: self.outputFormat!, frameCapacity: AVAudioFrameCount(self.outputFormat!.sampleRate) * buffer.frameLength / AVAudioFrameCount(buffer.format.sampleRate))!

            var error: NSError?
            let status = converter.convert(to: convertedBuffer, error: &error, withInputFrom: inputCallback)
            assert(status != .error)

            let values = UnsafeBufferPointer(start: convertedBuffer.int16ChannelData![0], count: Int(convertedBuffer.frameLength))
            events(Data(buffer: values))

            if !self.isRecording {
                events(FlutterEndOfEventStream)
            }
        }

        try! engine.start()

        return nil
    }

    public func onCancel(withArguments _: Any?) -> FlutterError? {
        engine.inputNode.removeTap(onBus: 0)
        engine.stop()

        return nil
    }
}
