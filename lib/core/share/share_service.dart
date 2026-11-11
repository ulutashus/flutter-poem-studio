import 'dart:typed_data';

abstract interface class ShareService {
  Future<void> shareText(String text, {String? subject});

  Future<void> shareImage(Uint8List pngBytes, {String? subject});
}
