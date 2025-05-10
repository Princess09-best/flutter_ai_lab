import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../ext-services/record_audio_service.dart';
import '../ext-services/google_speech_service.dart';
import '../ext-services/gemini_service.dart';

class VoiceRecordScreen extends StatefulWidget {
  const VoiceRecordScreen({super.key});

  @override
  _VoiceRecordScreenState createState() => _VoiceRecordScreenState();
}

class _VoiceRecordScreenState extends State<VoiceRecordScreen> {
  final RecordAudioService _recordAudioService = RecordAudioService();
  final GoogleSpeechService _speechService = GoogleSpeechService();
  final GeminiService _geminiService = GeminiService();
  final FlutterTts _flutterTts = FlutterTts();

  String _speakprompt = 'Press the button and start speaking';
  String _transcription = '';
  String _aiResponse = '';
  bool _isListening = false;
  bool _hasPermission = false;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _initServices();
  }

  Future<void> _initServices() async {
    // Initialize the recorder and check permissions
    await _recordAudioService.initRecorder();
    _hasPermission = await _recordAudioService.checkAndAskForMicPermission();
    setState(() {}); // Update the UI
  }

  @override
  void dispose() {
    // Clean up resources
    _recordAudioService.dispose();
    _flutterTts.stop();
    super.dispose();
  }

  Future<void> _speak(String text) async {
    print('TTS: Speaking: $text');
    try {
      await _flutterTts.stop();
      await _flutterTts.setLanguage('en-US');
      await _flutterTts.setPitch(1.0);
      var result = await _flutterTts.speak(text);
      print('TTS: Speak result: $result');
    } catch (e) {
      print('TTS Error: $e');
    }
  }

  void _toggleRecordButton() async {
    debugPrint("Button pressed!");

    if (!_hasPermission) {
      debugPrint("No microphone permission!");
      setState(() {
        _speakprompt = 'Microphone Permission Required';
      });
      return;
    }

    if (_isProcessing) {
      debugPrint("Still processing previous recording");
      return;
    }

    if (_isListening) {
      try {
        debugPrint("Stopping Listening...");
        setState(() {
          _isListening = false;
          _speakprompt = 'Processing...';
          _isProcessing = true;
        });

        // Stop recording
        await _recordAudioService.stopRecording();

        // Get file path
        final filePath = _recordAudioService.getRecordedFilePath();
        if (filePath != null) {
          // Transcribe audio
          debugPrint("Transcribing audio from: $filePath");
          final transcript = await _speechService.transcribeAudio(filePath);

          setState(() {
            _transcription = transcript;
            _speakprompt = 'Processing with AI...';
          });

          // Process with Gemini
          final aiResponse = await _geminiService.processUserInput(transcript);

          setState(() {
            _aiResponse = aiResponse;
            _speakprompt = 'AI Response Ready';
            _isProcessing = false;
          });
          _speak(aiResponse);
        } else {
          setState(() {
            _speakprompt = 'Failed to get recording file';
            _isProcessing = false;
          });
        }
      } catch (e) {
        debugPrint("Error processing recording: $e");
        setState(() {
          _speakprompt = 'Error: $e';
          _isProcessing = false;
        });
      }
    } else {
      try {
        debugPrint("Starting Listening...");
        // Clear previous transcription and AI response
        setState(() {
          _transcription = '';
          _aiResponse = '';
          _speakprompt = 'Listening...';
        });

        await _recordAudioService.startRecording();
        setState(() {
          _isListening = true;
        });
      } catch (e) {
        debugPrint("Error starting recording: $e");
        setState(() {
          _speakprompt = 'Error: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("AI Voice Assistant")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _speakprompt,
              style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 30.0),
            GestureDetector(
              onTap: _toggleRecordButton,
              child: CircleAvatar(
                radius: 40.0,
                backgroundColor:
                    _isProcessing
                        ? Colors.orange
                        : (_isListening
                            ? Colors.red
                            : (_hasPermission ? Colors.blue : Colors.grey)),
                child: Icon(
                  _isProcessing
                      ? Icons.hourglass_bottom
                      : (_isListening ? Icons.mic_off : Icons.mic),
                  size: 40.0,
                  color: Colors.white,
                ),
              ),
            ),
            SizedBox(height: 40.0),
            if (_transcription.isNotEmpty) ...[
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'You said:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.blue[800],
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(_transcription, style: TextStyle(fontSize: 18)),
                  ],
                ),
              ),
            ],
            if (_aiResponse.isNotEmpty) ...[
              SizedBox(height: 20),
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI Response:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.blue[800],
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(_aiResponse, style: TextStyle(fontSize: 18)),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
