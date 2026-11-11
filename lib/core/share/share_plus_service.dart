import 'package:flutter/services.dart';
import 'package:injectable/injectable.dart';
import 'package:poem_studio/core/logging/app_logger.dart';
import 'package:poem_studio/core/share/share_service.dart';
import 'package:share_plus/share_plus.dart';

@LazySingleton(as: ShareService)
class SharePlusService implements ShareService {
  const SharePlusService(this._logger);

  final AppLogger _logger;

  @override
  Future<void> shareText(String text, {String? subject}) {
    return _guard(
      () => SharePlus.instance.share(ShareParams(text: text, subject: subject)),
    );
  }

  @override
  Future<void> shareImage(Uint8List pngBytes, {String? subject}) {
    final file = XFile.fromData(
      pngBytes,
      mimeType: 'image/png',
      name: 'poem.png',
    );
    return _guard(
      () => SharePlus.instance.share(
        ShareParams(files: [file], subject: subject),
      ),
    );
  }

  // The share sheet is fire-and-forget UI; a platform failure must not surface as an app error.
  Future<void> _guard(Future<ShareResult> Function() share) async {
    try {
      await share();
    } on PlatformException catch (e, s) {
      _logger.warning('Sharing failed', e, s);
    }
  }
}
