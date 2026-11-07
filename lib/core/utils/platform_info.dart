import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;

import 'platform_stub.dart'
    if (dart.library.io) 'platform_io.dart'
    if (dart.library.js_interop) 'platform_web.dart';

/// Unified cross-platform helper that exposes platform info and file saving
/// without ever importing `dart:io` or `dart:html` in shared code.
abstract final class PlatformInfo {
  static bool get isWeb => kIsWeb;
  static String get platformName => getPlatformNameImpl();
  static bool get isNativeMobile => !kIsWeb && isNativeMobileImpl();
  static bool get isNativeDesktop => !kIsWeb && isNativeDesktopImpl();

  /// Triggers a browser download on Web or writes to system storage on Native
  /// using raw `Uint8List` bytes only.
  static Future<bool> saveBytesAsFile({
    required String fileName,
    required Uint8List bytes,
    String mimeType = 'application/octet-stream',
  }) {
    return saveBytesAsFileImpl(
      fileName: fileName,
      bytes: bytes,
      mimeType: mimeType,
    );
  }
}
