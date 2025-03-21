import 'package:flutter/material.dart';
import 'UI/voicerecord_screen.dart'; // Make sure this path is correct

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: VoiceRecordScreen(),
    );
  }
}
