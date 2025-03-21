import 'package:flutter/material.dart';
import '../ext-services/record_audio_input.dart';

class VoiceRecordScreen extends StatefulWidget {
  const VoiceRecordScreen({super.key});

  @override
  _VoiceRecordScreenState createState() => _VoiceRecordScreenState();
}

class _VoiceRecordScreenState extends State<VoiceRecordScreen> {
  final AudioRecordService _recordAudioService = AudioRecordService();

  String _speakprompt = 'Press the button and start speaking';
  bool _isListening = false;
  bool _hasPermission = false;

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
    super.dispose();
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

    if (!_hasPermission) {
      debugPrint("No microphone permission!");
      setState(() {
        _speakprompt = 'Microphone Permission Required';
      });
      return;
    }
    if (_isListening) {
      debugPrint("Stopping Listening...");
      await _recordAudioService.stopRecording();
      setState(() {
        _isListening = false;
        _speakprompt = 'Press the button and start speaking again';
      });
    } else {
      debugPrint("Listening...");
      await _recordAudioService.startRecording();
      setState(() {
        _isListening = true;
        _speakprompt = 'Listening...';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("AI Voice Assistant")),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            _speakprompt,
            style: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 30.0),
          GestureDetector(
            onTap: _toggleRecordButton,
            child: CircleAvatar(
              radius: 40.0,
              backgroundColor:
                  _isListening
                      ? Colors.red
                      : (_hasPermission ? Colors.blue : Colors.grey),
              child: Icon(
                _isListening ? Icons.mic_off : Icons.mic,
                size: 40.0,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
