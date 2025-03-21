import 'package:speech_to_text/speech_to_text.dart';

class SpeechToTextService {
  final SpeechToText _speech = SpeechToText();

  Future<bool> initSpeech() async {
    return await _speech.initialize();
  }

  Future<void> startListening(Function(String text) onResult) async {
    await _speech.listen(
      onResult: (result) {
        onResult(result.recognizedWords);
      },
    );
  }

  Future<void> stopListening() async {
    await _speech.stop();
  }

  bool get isListening => _speech.isListening;
}
