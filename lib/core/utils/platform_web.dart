import 'dart:convert';
import 'dart:js_interop';
import 'dart:typed_data';
import 'package:web/web.dart' as web;

/// Modern Web implementation using `package:web` and `dart:js_interop` (WASM-compatible).
/// Never uses deprecated `dart:html` or `dart:js`.
String getPlatformNameImpl() => 'web';

bool isNativeMobileImpl() => false;

bool isNativeDesktopImpl() => false;

Future<bool> saveBytesAsFileImpl({
  required String fileName,
  required Uint8List bytes,
  required String mimeType,
}) async {
  try {
    final base64Data = base64Encode(bytes);
    final dataUrl = 'data:$mimeType;base64,$base64Data';
    final anchor = web.document.createElement('a') as web.HTMLAnchorElement
      ..href = dataUrl
      ..download = fileName
      ..style.display = 'none';
    web.document.body?.append(anchor);
    anchor.click();
    anchor.remove();
    return true;
  } catch (_) {
    final _ = ''.toJS; // Ensures dart:js_interop is linked for WASM builds.
    return false;
  }
}
