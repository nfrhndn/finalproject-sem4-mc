import 'dart:io';

/// Platform-specific base URL for mobile/desktop (uses dart:io)
String getApiBaseUrl() {
  if (Platform.isAndroid) {
    return 'http://10.0.2.2:8000/api';
  }

  return 'http://localhost:8000/api';
}
