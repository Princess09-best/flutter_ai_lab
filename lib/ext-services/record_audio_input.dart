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
  bool _isInitialized = false;
  bool _isRecording = false;
  static const int _minRecordingDurationMs = 1000; // Minimum 1 second recording
  DateTime? _recordingStartTime;

  //the constructor initializes the recorder object
  AudioRecordService() {
    _recorder = FlutterSoundRecorder();
  }

  // This method initializes the recorder
  Future<void> initRecorder() async {
    try {
      if (!_isInitialized) {
        debugPrint("Initializing recorder...");
        await _recorder!.openRecorder();
        await _recorder!.setSubscriptionDuration(Duration(milliseconds: 500));
        _isInitialized = true;
        debugPrint("Recorder initialized successfully");

        // Add a small delay after initialization
        await Future.delayed(Duration(milliseconds: 100));
      }
    } catch (e) {
      debugPrint("Error initializing recorder: $e");
      throw Exception("Failed to initialize recorder: $e");
    }
  }

  // This method checks if the app has permission to record audio
  Future<bool> checkAndAskForMicPermission() async {
    var status = await Permission.microphone.status;
    if (!status.isGranted) {
      debugPrint("Requesting microphone permission...");
      status = await Permission.microphone.request();
      debugPrint(
        "Microphone permission status: ${status.isGranted ? 'granted' : 'denied'}",
      );
    }
    return status.isGranted;
  }

  // This method starts recording audio
  Future<void> startRecording() async {
    try {
      if (!_isInitialized) {
        debugPrint("Recorder not initialized, initializing now...");
        await initRecorder();
      }

      if (!await checkAndAskForMicPermission()) {
        throw Exception("Microphone permission denied");
      }

      if (_isRecording) {
        debugPrint("Already recording, ignoring start request");
        return;
      }

      debugPrint("Starting recording...");

      // Use Documents directory instead of Temp directory
      Directory documentsDir = await getApplicationDocumentsDirectory();
      _recordedAudioFile = File('${documentsDir.path}/recorded_audio.wav');

      // Ensure the file doesn't exist from a previous recording
      if (_recordedAudioFile.existsSync()) {
        await _recordedAudioFile.delete();
      }

      debugPrint("Starting recorder with file: ${_recordedAudioFile.path}");
      await _recorder!.startRecorder(
        toFile: _recordedAudioFile.path,
        codec: Codec.pcm16WAV,
        sampleRate: 44100, // Changed from 16000 to 44100 (CD quality)
        bitRate: 256000,
        numChannels: 2, // Changed from mono to stereo
      );
      debugPrint("startRecorder call completed");

      _recordingStartTime = DateTime.now();
      _isRecording = true;
      debugPrint("Recording started successfully at: $_recordingStartTime");

      // Add a small delay after starting to ensure recording begins
      await Future.delayed(Duration(milliseconds: 100));
    } catch (e) {
      debugPrint("Error starting recording: $e");
      throw Exception("Error starting recording: $e");
    }
  }

  // This method stops recording audio
  Future<void> stopRecording() async {
    try {
      if (_recorder == null) {
        debugPrint("Recorder is null, cannot stop");
        return;
      }

      if (!_isRecording) {
        debugPrint("Not currently recording, cannot stop");
        return;
      }

      debugPrint("Stopping recording...");
      debugPrint(
        "Recording duration so far: ${DateTime.now().difference(_recordingStartTime!).inMilliseconds}ms",
      );

      // Ensure minimum recording duration
      if (_recordingStartTime != null) {
        final recordingDuration = DateTime.now().difference(
          _recordingStartTime!,
        );
        if (recordingDuration.inMilliseconds < _minRecordingDurationMs) {
          debugPrint(
            "Recording too short (${recordingDuration.inMilliseconds}ms), waiting for minimum duration...",
          );
          await Future.delayed(
            Duration(
              milliseconds:
                  _minRecordingDurationMs - recordingDuration.inMilliseconds,
            ),
          );
        }
      }

      _isRecording = false;
      debugPrint("Stopping recorder...");
      await _recorder!.stopRecorder();
      debugPrint("Recorder stopped");

      // Wait for file to be written
      debugPrint("Waiting for file to be written...");
      await Future.delayed(Duration(milliseconds: 500));

      if (_recordedAudioFile.existsSync()) {
        final fileSize = _recordedAudioFile.lengthSync();
        debugPrint("Audio file size: $fileSize bytes");

        if (fileSize < 5000) {
          throw Exception(
            "Audio file is too small ($fileSize bytes). Recording may have failed.",
          );
        }
        debugPrint("Recording completed successfully");
      } else {
        throw Exception("Audio file was not saved");
      }
    } catch (e) {
      debugPrint("Error stopping recording: $e");
      throw Exception("Error stopping recording: $e");
    } finally {
      _recordingStartTime = null;
      _isRecording = false;
    }
  }

  // This method disposes the recorder object
  Future<void> dispose() async {
    if (_recorder != null) {
      if (_isRecording) {
        debugPrint("Disposing while recording, stopping first...");
        await stopRecording();
      }
      debugPrint("Closing recorder...");
      await _recorder!.closeRecorder();
      _recorder = null;
      _isInitialized = false;
      _recordingStartTime = null;
      _isRecording = false;
      debugPrint("Recorder disposed successfully");
    }
  }
}
