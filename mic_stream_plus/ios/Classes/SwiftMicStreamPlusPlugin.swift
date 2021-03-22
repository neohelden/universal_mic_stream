import Flutter
import UIKit
import AVFoundation
import Foundation

@available(iOS 9.0, *)
public class SwiftMicStreamPlusPlugin: NSObject, FlutterPlugin, FlutterStreamHandler {

    let engine = AVAudioEngine()
    var outputFormat = AVAudioFormat(commonFormat: AVAudioCommonFormat.pcmFormatInt16, sampleRate: 16000, channels: 1, interleaved: false)
    var isRecording = false;

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "neohelden.com/mic_stream_plus", binaryMessenger: registrar.messenger())
        let eventChannel = FlutterEventChannel(name: "neohelden/com.audio_stream", binaryMessenger: registrar.messenger())
        let instance = SwiftMicStreamPlusPlugin()
        eventChannel.setStreamHandler(instance)
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        if(call.method == "getPlatformVersion") {
            result(UIDevice.current.systemName + " " + UIDevice.current.systemVersion)
        } else if (call.method == "startRecording") {
            isRecording = true
            result(nil)
        } else if (call.method == "stopRecording") {
            isRecording = false
            result(nil)
        } else {
            result(FlutterMethodNotImplemented)
        }
    }

    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        let audioSession = AVAudioSession.sharedInstance()
        if #available(iOS 10.0, *) {
            try! audioSession.setCategory(AVAudioSession.Category.playAndRecord, mode: .default)
        } else {
            try! audioSession.setCategory(AVAudioSession.Category.playAndRecord)
        }

        try! audioSession.setActive(true, options: .notifyOthersOnDeactivation)

        let input = engine.inputNode
        let bus = 0
        let inputFormat = input.outputFormat(forBus: 0)
        let converter = AVAudioConverter(from: inputFormat, to: outputFormat!)!

        input.installTap(onBus: bus, bufferSize: 1024, format: inputFormat) { (buffer, time) -> Void in
            var newBufferAvailable = true

            let inputCallback: AVAudioConverterInputBlock = { inNumPackets, outStatus in
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

            if(!self.isRecording) {
                events(FlutterEndOfEventStream)
            }
        }

        try! engine.start()

        return nil
    }

    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        engine.inputNode.removeTap(onBus: 0)
        engine.stop()

        return nil
    }
}

