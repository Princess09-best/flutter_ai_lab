import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:googleapis/speech/v1.dart';
import 'package:googleapis_auth/auth_io.dart';

class GoogleSpeechService {
  // IMPORTANT: Replace this with your actual Google Cloud API key
  // Get one by creating a project at https://console.cloud.google.com/
  // and enabling the Speech-to-Text API
  // Remember to restrict API key usage in production!
  static const String _apiKey =
      "AIzaSyBINOdWqe7uy-y06Ji-yt1S71NHRLcZw1Y"; // Replace with your Google Cloud API key

  // Transcribe audio file using Google Speech API
  Future<String> transcribeAudio(String filePath) async {
    try {
      final File audioFile = File(filePath);
      if (!audioFile.existsSync()) {
        throw Exception("Audio file doesn't exist at path: $filePath");
      }

      final fileSize = audioFile.lengthSync();
      debugPrint("Audio file size: $fileSize bytes");

      if (fileSize < 5000) {
        throw Exception(
          "Audio file is too small, might not contain any speech",
        );
      }

      // Read file bytes
      final List<int> audioBytes = await audioFile.readAsBytes();
      final String base64Audio = base64Encode(audioBytes);

      debugPrint("Sending ${audioBytes.length} bytes to Google Speech API");

      // Prepare request to Speech API
      final Map<String, dynamic> requestBody = {
        'config': {
          'encoding': 'LINEAR16',
          'sampleRateHertz': 44100,
          'languageCode': 'en-US',
          'enableAutomaticPunctuation': true,
          'model': 'default',
          'audioChannelCount': 2,
        },
        'audio': {'content': base64Audio},
      };

      // Make API call
      final response = await http.post(
        Uri.parse(
          'https://speech.googleapis.com/v1/speech:recognize?key=$_apiKey',
        ),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        debugPrint("API response: $jsonResponse");

        // Extract transcription
        if (jsonResponse['results'] != null &&
            jsonResponse['results'].isNotEmpty) {
          final String transcript =
              jsonResponse['results'][0]['alternatives'][0]['transcript'];
          debugPrint("Transcription: $transcript");
          return transcript;
        } else {
          return "No speech recognized";
        }
      } else {
        debugPrint("API error: ${response.statusCode}, ${response.body}");
        throw Exception(
          "Google Speech API error: ${response.statusCode}, ${response.body}",
        );
      }
    } catch (e) {
      debugPrint("Error transcribing audio: $e");
      throw Exception("Failed to transcribe audio: $e");
    }
  }

  // Alternative implementation using googleapis package
  Future<String> transcribeAudioWithClient(String filePath) async {
    try {
      final File audioFile = File(filePath);
      if (!audioFile.existsSync()) {
        throw Exception("Audio file doesn't exist at path: $filePath");
      }

      // Setup auth client
      // For demo purposes - you should use proper authentication
      // with a service account in production
      final client = http.Client();

      // Create Speech API client
      final speechApi = SpeechApi(client);

      // Read file as bytes
      final List<int> audioBytes = await audioFile.readAsBytes();
      final String base64Audio = base64Encode(audioBytes);

      // Create recognition config
      final recognitionConfig = RecognitionConfig(
        encoding: 'LINEAR16',
        sampleRateHertz: 44100,
        languageCode: 'en-US',
        enableAutomaticPunctuation: true,
        model: 'default',
        audioChannelCount: 2,
      );

      // Create recognition request
      final request = RecognizeRequest(
        config: recognitionConfig,
        audio: RecognitionAudio(content: base64Audio),
      );

      // Perform recognition
      final response = await speechApi.speech.recognize(request);

      // Parse results
      if (response.results != null && response.results!.isNotEmpty) {
        final String transcript =
            response.results!.first.alternatives!.first.transcript!;
        debugPrint("Transcription: $transcript");
        return transcript;
      } else {
        return "No speech recognized";
      }
    } catch (e) {
      debugPrint("Error transcribing audio: $e");
      throw Exception("Failed to transcribe audio: $e");
    }
  }
}
