import 'dart:io';

String getHost() {
  try {
    if (Platform.isAndroid) {
      return '10.0.2.2';
    }
  } catch (e) {
    // If the Platform access fails, assume it's not android.
  }
  return 'localhost:5000';
}
