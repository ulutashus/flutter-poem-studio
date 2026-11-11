import 'dart:io';

import 'package:shelf/shelf_io.dart' as io;

import 'package:poem_studio_mock_server/server.dart';

Future<void> main() async {
  final port = int.parse(Platform.environment['PORT'] ?? '8080');
  final apiKey = Platform.environment['POEMS_API_KEY'] ?? 'dev-key';
  // 0.0.0.0 so emulators and devices on the LAN can reach it.
  final server = await io.serve(
    buildHandler(apiKey: apiKey),
    InternetAddress.anyIPv4,
    port,
  );
  stdout.writeln(
    'Mock server listening on http://${server.address.host}:${server.port}',
  );
}
