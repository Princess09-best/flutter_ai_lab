import 'package:flutter/material.dart';
import '../ext-services/permissions_handler_service.dart' as permissions;
import '../ext-services/speechtotext_service.dart';

class VoiceRecordScreen extends StatefulWidget {
  const VoiceRecordScreen({super.key});

  @override
  _VoiceRecordScreenState createState() => _VoiceRecordScreenState();
}

class _VoiceRecordScreenState extends State<VoiceRecordScreen> {
  final SpeechToTextService _speechToTextService = SpeechToTextService();

  String _speakprompt = 'Press the button and start speaking';
  bool _isListening = false;
  bool _hasPermission = false;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    bool granted = await permissions.hasMicPermission();
    setState(() {
      _hasPermission = granted;
    });

    if (!granted) {
      permissions.requestMicPermission();
      granted = await permissions.hasMicPermission();
      setState(() {
        _hasPermission = granted;
      });
    }
  }

  void _toggleRecordButton() async {
    if (!_hasPermission) {
      setState(() {
        _speakprompt = 'Microphone Permission Required';
      });
      return;
    }

    if (_isListening) {
      _speechToTextService.stopListening();
      setState(() {
        _isListening = false;
        _speakprompt = 'Press the mic and start speaking';
      });
    } else {
      await _speechToTextService.startListening((text) {
        setState(() {
          _speakprompt = text;
        });
      });
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
