import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import 'package:poem_studio_mock_server/edit_store.dart';

const apiKeyHeader = 'X-Poems-Key';

Handler buildHandler({required String apiKey, EditStore? store}) {
  final edits = store ?? EditStore();
  final router = Router()
    ..get('/api/v1/poems/edits', (Request request) {
      return _json({'edits': edits.all().map((e) => e.toJson()).toList()});
    })
    ..put('/api/v1/poems/edits/<id>', (Request request, String id) async {
      final Map<String, dynamic> body;
      try {
        body = jsonDecode(await request.readAsString()) as Map<String, dynamic>;
      } on FormatException {
        return Response.badRequest(body: 'Invalid JSON');
      }
      final title = body['title'];
      final content = body['content'];
      final updatedAt = DateTime.tryParse('${body['updatedAt']}');
      if (title is! String || content is! String || updatedAt == null) {
        return Response.badRequest(
          body: 'title, content and updatedAt are required',
        );
      }
      final stored = edits.put(
        PoemEdit(id: id, title: title, content: content, updatedAt: updatedAt),
      );
      return _json(stored.toJson());
    });

  return const Pipeline()
      .addMiddleware(logRequests())
      .addMiddleware(_cors())
      .addMiddleware(_requireApiKey(apiKey))
      .addHandler(router.call);
}

// Browsers send a keyless preflight, so this must run before the key check.
Middleware _cors() {
  const headers = {
    'access-control-allow-origin': '*',
    'access-control-allow-methods': 'GET, PUT, OPTIONS',
    'access-control-allow-headers': 'content-type, $apiKeyHeader',
  };
  return (inner) => (request) async {
    if (request.method == 'OPTIONS') {
      return Response.ok(null, headers: headers);
    }
    return (await inner(request)).change(headers: headers);
  };
}

Middleware _requireApiKey(String apiKey) {
  return (inner) => (request) {
    if (request.headers[apiKeyHeader] != apiKey) {
      return Response.forbidden('Invalid or missing $apiKeyHeader');
    }
    return inner(request);
  };
}

Response _json(Object body) => Response.ok(
  jsonEncode(body),
  headers: {'content-type': 'application/json'},
);
