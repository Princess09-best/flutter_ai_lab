import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

// This class is responsible for recording audio
// It uses the FlutterSoundRecorder class from the flutter_sound package
class AudioRecordService {
  // The recorder object and the file where the audio will be saved
  FlutterSoundRecorder? _recorder;
  late File _recordedAudioFile;

  //the constructor initializes the recorder object
  AudioRecordService() {
    _recorder = FlutterSoundRecorder();
  }

  // This method initializes the recorder
  Future<void> initRecorder() async {
    await _recorder!.openRecorder();
    await _recorder!.setSubscriptionDuration(Duration(milliseconds: 500));
  }

  // This method checks if the app has permission to record audio
  Future<bool> checkAndAskForMicPermission() async {
    var status = await Permission.microphone.status;
    if (!status.isGranted) {
      status = await Permission.microphone.request();
    }
    return status.isGranted;
  }

  // This method starts recording audio
  Future<void> startRecording() async {
    // Check if the app has permission to record audio
    if (!await checkAndAskForMicPermission()) {
      throw Exception("Permission denied");
    }

    // Create a new file to save the audio
    try {
      debugPrint("Starting recording...");

      Directory tempDir = await getTemporaryDirectory();
      _recordedAudioFile = File('${tempDir.path}/recorded_audio.wav');

      await _recorder!.startRecorder(
        toFile: _recordedAudioFile.path,
        codec: Codec.pcm16WAV,
        sampleRate: 16000,
        bitRate: 256000,
        numChannels: 1,
      );

      debugPrint("Recording started: ${_recordedAudioFile.path}");
    } catch (e) {
      debugPrint("Error starting recording: $e");
      throw Exception("Error starting recording");
    }
  }

  // This method stops recording audio
  Future<void> stopRecording() async {
    // Check if the recorder is recording before stopping
    try {
      if (_recorder == null || !_recorder!.isRecording) {
        debugPrint("no recording to stop");
        return;
      }
      // Stop the recorder
      // Force at least 2 seconds of recording before allowing stop
      // await Future.delayed(Duration(seconds: 3));
      //debugPrint("✅ 3 seconds delay complete. Ready to stop now.");
      await _recorder!.stopRecorder();
      debugPrint("Recording stopped: ${_recordedAudioFile.path}");
      if (_recordedAudioFile.existsSync()) {
        // Check if the file was saved
        debugPrint("Audio successfully saved at ${_recordedAudioFile.path}");
        debugPrint("Audio file size: ${_recordedAudioFile.lengthSync()} bytes");

        if (_recordedAudioFile.lengthSync() < 5000) {
          // Less than 5KB is too small
          debugPrint(
            " ERROR: Audio file is too small! Recording may have failed.",
          );
        }
      } else {
        debugPrint("Audio file was not saved");
      }
    } catch (e) {
      debugPrint("Error stopping recording: $e");
      throw Exception("Error stopping recording");
    }
  }

  // This method disposes the recorder object
  Future<void> dispose() async {
    if (_recorder != null) {
      await _recorder!.closeRecorder();
      _recorder = null;
    }
  }
}
