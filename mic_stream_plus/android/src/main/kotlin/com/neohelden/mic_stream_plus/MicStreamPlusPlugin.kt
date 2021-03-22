package com.neohelden.mic_stream_plus

import android.media.AudioFormat
import android.media.AudioRecord
import android.media.MediaRecorder
import android.os.Handler
import android.os.Looper
import android.util.Log
import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry.Registrar
import java.io.File
import java.io.FileOutputStream
import kotlin.experimental.and


/** MicStreamPlusPlugin */
class MicStreamPlusPlugin : FlutterPlugin, MethodCallHandler, EventChannel.StreamHandler {
  private lateinit var channel: MethodChannel
  private lateinit var eventChannel: EventChannel

  private var recorder: AudioRecord? = null
  private var isRecording = false
  private var eventSink: EventChannel.EventSink? = null
  private var handler: Handler? = null

  private val chunkId = "RIFF"
  private val format = "WAVE"
  private val subChunk1Id = "fmt "
  private val subChunk2Id = "data"

  private val sampleRate = 16000
  private val channels = AudioFormat.CHANNEL_IN_MONO
  private val audioFormat = AudioFormat.ENCODING_PCM_16BIT
  private val bufferSize = AudioRecord.getMinBufferSize(sampleRate, channels, audioFormat)
  private val audioFormatVal: Short = 1
  private val bps: Short = 16
  private val numChannels: Short = 1
  private val subChunk1Size: Int = 16

  private val byteRate: Int = sampleRate * numChannels * (bps / 8)
  private val blockAlign: Short = (numChannels * (bps / 8)).toShort()

  override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    channel = MethodChannel(flutterPluginBinding.flutterEngine.dartExecutor, "neohelden.com/mic_stream_plus")
    channel.setMethodCallHandler(this)

    eventChannel = EventChannel(flutterPluginBinding.flutterEngine.dartExecutor, "neohelden/com.audio_stream")
    eventChannel.setStreamHandler(this)
  }

  companion object {
    @JvmStatic
    fun registerWith(registrar: Registrar) {
      val plugin = MicStreamPlusPlugin()

      val channel = MethodChannel(registrar.messenger(), "neohelden.com/mic_stream_plus")
      channel.setMethodCallHandler(plugin)

      val eventChannel = EventChannel(registrar.messenger(), "neohelden.com/audio_stream")
      eventChannel.setStreamHandler(plugin)
    }
  }

  override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
    when (call.method) {
      "startRecording" -> {
        startRecording()
        result.success(null)
      }
      "stopRecording" -> {
        stopRecording()
        result.success(null)
      }
      else -> {
        result.notImplemented()
      }
    }
  }

  override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
  }

  private fun startRecording() {
    if (isRecording) return

    startAudioRecorder()

    var recordingThread = Thread(Runnable {
      isRecording = true

      val buffer = ByteArray(bufferSize);

      while (isRecording) {
        recorder?.read(buffer, 0, bufferSize)

        if (handler == null) {
          handler = Handler(Looper.getMainLooper())
        }

        handler?.post {
          eventSink?.success(buffer)
        }
      }

      handler?.post {
        eventSink?.endOfStream()
      }
    })

    recordingThread?.start()
  }

  private fun startAudioRecorder() {
    if (recorder == null) {
      Log.d("MicStreamPlusPlugin", "Start audio recorder")
      recorder = AudioRecord(MediaRecorder.AudioSource.MIC, sampleRate, channels, audioFormat, bufferSize)
      recorder?.startRecording()
    } else {
      Log.w("MicStreamPlusPlugin", "Audio recorder does already exist. Care the recorder could be canceled somewhere else.")
    }
  }

  private fun stopRecording() {
    if (recorder != null) {
      Log.i("MicStreamPlusPlugin", "Stopping audio recorder")
      isRecording = false
      recorder?.stop()
      recorder?.release()
      recorder = null
    } else {
      Log.i("MicStreamPlusPlugin", "No audio recorder to stop")
    }
  }

  override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
    eventSink = events
  }

  override fun onCancel(arguments: Any?) {
    eventSink = null
  }
}
