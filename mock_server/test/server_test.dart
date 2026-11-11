import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

import 'package:poem_studio_mock_server/server.dart';

void main() {
  const key = 'test-key';
  late Handler handler;

  setUp(() => handler = buildHandler(apiKey: key));

  Request request(
    String method,
    String path, {
    Object? body,
    String? apiKey = key,
  }) {
    return Request(
      method,
      Uri.parse('http://localhost$path'),
      headers: {apiKeyHeader: ?apiKey},
      body: body == null ? null : jsonEncode(body),
    );
  }

  Future<Map<String, dynamic>> jsonOf(Response response) async =>
      jsonDecode(await response.readAsString()) as Map<String, dynamic>;

  test('rejects requests without a valid API key', () async {
    final response = await handler(
      request('GET', '/api/v1/poems/edits', apiKey: null),
    );
    expect(response.statusCode, 403);
  });

  test('stores an edit and returns it from the list', () async {
    final put = await handler(
      request(
        'PUT',
        '/api/v1/poems/edits/p1',
        body: {
          'title': 'Title',
          'content': 'Content',
          'updatedAt': '2026-01-01T10:00:00.000Z',
        },
      ),
    );
    expect(put.statusCode, 200);

    final list = await jsonOf(
      await handler(request('GET', '/api/v1/poems/edits')),
    );
    expect(list['edits'], [
      {
        'id': 'p1',
        'title': 'Title',
        'content': 'Content',
        'updatedAt': '2026-01-01T10:00:00.000Z',
      },
    ]);
  });

  test('keeps the newer edit when an older one arrives', () async {
    Future<Response> put(String content, String at) async => handler(
      request(
        'PUT',
        '/api/v1/poems/edits/p1',
        body: {'title': 'T', 'content': content, 'updatedAt': at},
      ),
    );

    await put('newer', '2026-01-02T00:00:00.000Z');
    final response = await jsonOf(
      await put('older', '2026-01-01T00:00:00.000Z'),
    );
    expect(response['content'], 'newer');
  });

  test('rejects an incomplete body', () async {
    final response = await handler(
      request('PUT', '/api/v1/poems/edits/p1', body: {'title': 'T'}),
    );
    expect(response.statusCode, 400);
  });
}
