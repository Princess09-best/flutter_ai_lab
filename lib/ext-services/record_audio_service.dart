import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class RecordAudioService {
  final AudioRecorder _recorder = AudioRecorder();
  late String _filePath;
  bool _isRecording = false;
  bool _isInitialized = false;
  DateTime? _recordingStartTime;

  // Initialize the recorder
  Future<void> init() async {
    if (!_isInitialized) {
      final hasPermission = await checkAndRequestPermissions();
      if (hasPermission) {
        _isInitialized = true;
        debugPrint("Recorder initialized");
      } else {
        throw Exception("Microphone permission denied");
      }
    }
  }

  // Check and request permissions
  Future<bool> checkAndRequestPermissions() async {
    // Check if permission is already granted
    final status = await Permission.microphone.status;

    if (status.isGranted) {
      return true;
    }

    // Request permission
    debugPrint("Requesting microphone permission...");
    final result = await Permission.microphone.request();
    return result.isGranted;
  }

  // Alias for init() to match the original AudioRecordService interface
  Future<void> initRecorder() async {
    return init();
  }

  // Alias for checkAndRequestPermissions() to match the original AudioRecordService interface
  Future<bool> checkAndAskForMicPermission() async {
    return checkAndRequestPermissions();
  }

  // Start recording
  Future<void> startRecording() async {
    try {
      // Ensure we're initialized
      if (!_isInitialized) {
        await init();
      }

      if (_isRecording) {
        debugPrint("Already recording, ignoring request");
        return;
      }

      // Setup file path
      final Directory appDir = await getApplicationDocumentsDirectory();
      _filePath = '${appDir.path}/recorded_audio.wav';

      // Delete existing file if present
      final file = File(_filePath);
      if (file.existsSync()) {
        await file.delete();
      }

      debugPrint("Starting recording to: $_filePath");

      // Configure and start recording
      await _recorder.start(
        RecordConfig(
          encoder: AudioEncoder.wav, // WAV format for Google Speech API
          bitRate: 256000,
          sampleRate: 44100, // CD quality
          numChannels: 2, // stereo
        ),
        path: _filePath,
      );

      _recordingStartTime = DateTime.now();
      _isRecording = true;
      debugPrint("Recording started at: $_recordingStartTime");
    } catch (e) {
      debugPrint("Error starting recording: $e");
      throw Exception("Failed to start recording: $e");
    }
  }

  // Stop recording
  Future<void> stopRecording() async {
    try {
      if (!_isRecording) {
        debugPrint("Not recording, nothing to stop");
        return;
      }

      // Check recording duration
      if (_recordingStartTime != null) {
        final duration = DateTime.now().difference(_recordingStartTime!);
        debugPrint("Recording duration: ${duration.inMilliseconds}ms");

        // Ensure at least 1 second of recording
        if (duration.inMilliseconds < 1000) {
          debugPrint("Recording too short, waiting...");
          await Future.delayed(
            Duration(milliseconds: 1000 - duration.inMilliseconds),
          );
        }
      }

      debugPrint("Stopping recording...");
      final result = await _recorder.stop();

      debugPrint("Recording stopped, saved to: $result");
      _isRecording = false;

      // Verify the file
      final file = File(result ?? _filePath);
      if (file.existsSync()) {
        final size = file.lengthSync();
        debugPrint("Recording saved with size: $size bytes");

        if (size < 5000) {
          throw Exception(
            "Recording is too small ($size bytes), may have failed",
          );
        }
      } else {
        throw Exception("Recording file was not saved");
      }
    } catch (e) {
      debugPrint("Error stopping recording: $e");
      throw Exception("Failed to stop recording: $e");
    } finally {
      _isRecording = false;
      _recordingStartTime = null;
    }
  }

  // Get the path to the recorded file
  String? getRecordedFilePath() {
    final file = File(_filePath);
    if (file.existsSync()) {
      return _filePath;
    }
    return null;
  }

  // Dispose resources
  Future<void> dispose() async {
    if (_isRecording) {
      await stopRecording();
    }
    await _recorder.dispose();
    _isInitialized = false;
    debugPrint("Recorder disposed");
  }
}
