import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _pkg = 'package:poem_studio/';
final _importPattern = RegExp(r'''^(?:import|export)\s+['"]([^'"]+)['"]''');

class _Source {
  _Source(this.path, this.imports);

  final String path;
  final List<String> imports;

  String? get feature => RegExp(r'^lib/features/([^/]+)/').firstMatch(path)?[1];

  String? get layer =>
      RegExp(r'^lib/features/[^/]+/(data|domain|presentation)/')
          .firstMatch(path)?[1];
}

List<_Source> _scan() {
  return [
    for (final file in Directory('lib').listSync(recursive: true))
      if (file is File &&
          file.path.endsWith('.dart') &&
          !file.path.contains('/generated/') &&
          !file.path.endsWith('.config.dart') &&
          !file.path.endsWith('.g.dart') &&
          !file.path.endsWith('.freezed.dart'))
        _Source(file.path, [
          for (final line in file.readAsLinesSync())
            ?_importPattern.firstMatch(line)?[1],
        ]),
  ];
}

List<String> _violations(
  List<_Source> sources,
  bool Function(_Source source, String uri) isViolation,
) => [
  for (final source in sources)
    for (final uri in source.imports)
      if (isViolation(source, uri)) '${source.path} -> $uri',
];

bool _isProject(String uri, String area) => uri.startsWith('$_pkg$area/');

void main() {
  final sources = _scan();

  test('scans the project sources', () {
    expect(sources, isNotEmpty);
  });

  test('core never depends on app or features', () {
    final violations = _violations(
      sources.where((s) => s.path.startsWith('lib/core/')).toList(),
      (_, uri) => _isProject(uri, 'app') || _isProject(uri, 'features'),
    );
    expect(violations, isEmpty);
  });

  test('features never depend on app', () {
    final violations = _violations(
      sources.where((s) => s.feature != null).toList(),
      (_, uri) => _isProject(uri, 'app'),
    );
    expect(violations, isEmpty);
  });

  test('domain is free of Flutter and I/O packages, data and presentation', () {
    final violations = _violations(
      sources.where((s) => s.layer == 'domain').toList(),
      (_, uri) =>
          uri.startsWith('package:flutter/') ||
          uri.startsWith('package:flutter_bloc/') ||
          uri.startsWith('package:dio/') ||
          uri.startsWith('package:drift/') ||
          uri.startsWith('package:retrofit/') ||
          uri.startsWith('package:shared_preferences/') ||
          uri == 'dart:ui' ||
          uri == 'dart:io' ||
          RegExp('^${RegExp.escape(_pkg)}features/[^/]+/(data|presentation)/')
              .hasMatch(uri),
    );
    expect(violations, isEmpty);
  });

  test('blocs and cubits never depend on other blocs or cubits', () {
    final violations = _violations(
      sources.where((s) => s.path.contains('/presentation/bloc/')).toList(),
      (source, uri) =>
          uri.contains('/presentation/bloc/') &&
          RegExp(r'_(bloc|cubit)\.dart$').hasMatch(uri) &&
          !source.path.endsWith(uri.split('/').last),
    );
    expect(violations, isEmpty);
  });

  test('data never depends on presentation', () {
    final violations = _violations(
      sources.where((s) => s.layer == 'data').toList(),
      (_, uri) => uri.contains('/presentation/'),
    );
    expect(violations, isEmpty);
  });

  test('presentation never depends on data', () {
    final violations = _violations(
      sources.where((s) => s.layer == 'presentation').toList(),
      (_, uri) =>
          RegExp('^${RegExp.escape(_pkg)}features/[^/]+/data/').hasMatch(uri),
    );
    expect(violations, isEmpty);
  });

  test('a feature reaches another feature only through its barrel', () {
    final violations = _violations(
      sources.where((s) => s.feature != null).toList(),
      (source, uri) {
        final match = RegExp('^${RegExp.escape(_pkg)}features/([^/]+)/(.*)')
            .firstMatch(uri);
        if (match == null || match[1] == source.feature) return false;
        return match[2] != '${match[1]}.dart';
      },
    );
    expect(violations, isEmpty);
  });

  test('settings never depends on poem', () {
    final violations = _violations(
      sources.where((s) => s.feature == 'settings').toList(),
      (_, uri) => uri.startsWith('${_pkg}features/poem/'),
    );
    expect(violations, isEmpty);
  });
}
