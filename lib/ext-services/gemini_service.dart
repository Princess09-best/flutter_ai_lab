import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiService {
  late final GenerativeModel _model;

  GeminiService() {
    // Initialize the model with your API key
    _model = GenerativeModel(
      model: 'gemini-2.0-flash',
      apiKey: 'AIzaSyD0LNV1nebsFgVFlZPyJeGXwbnPW0fVmHM',
    );
  }

  Future<String> processUserInput(String userInput) async {
    try {
      final content = [Content.text(userInput)];
      final response = await _model.generateContent(content);
      return response.text ?? 'No response from AI';
    } catch (e, stack) {
      print('Error processing with Gemini: $e');
      print(stack);
      return 'Sorry, I encountered an error processing your request: $e';
    }
  }
}
