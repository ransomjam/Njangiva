import 'dart:io' show Directory, File, Platform;
import 'dart:typed_data';

/// Native (iOS, Android, Windows, macOS, Linux) platform implementation.
/// Isolated via conditional import so `dart:io` is never imported on Web.
String getPlatformNameImpl() {
  if (Platform.isAndroid) return 'android';
  if (Platform.isIOS) return 'ios';
  if (Platform.isWindows) return 'windows';
  if (Platform.isMacOS) return 'macos';
  if (Platform.isLinux) return 'linux';
  return 'native';
}

bool isNativeMobileImpl() => Platform.isAndroid || Platform.isIOS;

bool isNativeDesktopImpl() =>
    Platform.isWindows || Platform.isMacOS || Platform.isLinux;

Future<bool> saveBytesAsFileImpl({
  required String fileName,
  required Uint8List bytes,
  required String mimeType,
}) async {
  try {
    final sanitizedName = fileName.replaceAll(RegExp(r'[^\w\.\-]'), '_');
    final tempDir = Directory.systemTemp;
    final file = File('${tempDir.path}${Platform.pathSeparator}$sanitizedName');
    await file.writeAsBytes(bytes, flush: true);
    return true;
  } catch (_) {
    return false;
  }
}
