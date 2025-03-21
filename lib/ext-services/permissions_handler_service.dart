import 'package:permission_handler/permission_handler.dart';

Future<void> requestMicPermission() async {
  var status = await Permission.microphone.request();
  if (!status.isGranted) {
    await Permission.microphone.request();
  }
}

Future<bool> hasMicPermission() async {
  var status = await Permission.microphone.status;
  return status.isGranted;
}
