import 'dart:typed_data';

/// Stub implementation for cross-platform capabilities.
String getPlatformNameImpl() => 'unknown';

bool isNativeMobileImpl() => false;

bool isNativeDesktopImpl() => false;

Future<bool> saveBytesAsFileImpl({
  required String fileName,
  required Uint8List bytes,
  required String mimeType,
}) async {
  return false;
}
